// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'dart:convert';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import '../../../models/ModelProvider.dart';
import '../../../personalization/controllers/user_controller.dart';

class BookingController extends GetxController {
  // ---------------- Singleton ----------------
  static BookingController get instance => Get.find();

  // ---------------- Reactive State ----------------
  final RxList<Booking> bookings = <Booking>[].obs;
  final RxMap<String, List<BookingItem>> bookingItemsMap =
      <String, List<BookingItem>>{}.obs;
  final RxList<BookingItem> bookingItems = <BookingItem>[].obs;

  final RxInt totalBookedSessions = 0.obs;
  final RxDouble totalBookingPrice = 0.0.obs;

  User? _currentUser;

  // ---------------- Lifecycle ----------------
  @override
  void onInit() {
    super.onInit();

    ever(bookingItemsMap, (_) {
      _syncFlatBookingItems();
      _recalculateTotals();
    });
    ever(bookings, (_) => _recalculateTotals());

    _listenToUserChanges();
  }

  void _listenToUserChanges() {
    final userController = UserController.instance;

    // If user is already loaded, initialise immediately.
    if (userController.currentUser.value != null) {
      _initForUser(userController.currentUser.value!);
      return;
    }

    // ✅ FIX: the ever() callback was set up but never called _initForUser —
    //    the body was empty. This meant bookings never loaded after login
    //    unless something else triggered a reload, so the counter stayed 0
    //    until the user navigated to BookingScreen (which calls fetchBookings
    //    in initState). Now it fires _initForUser as soon as the user is set.
    ever<User?>(userController.currentUser, (user) {
      if (user != null) _initForUser(user);
    });
  }

  Future<void> _initForUser(User user) async {
    try {
      _currentUser = user;
      await fetchBookings();
    } catch (e) {
      print('BookingController: failed to init for user: $e');
    }
  }

  // ---------------- Auth guard ----------------
  Future<bool> _canSync() async {
    try {
      await Amplify.Auth.getCurrentUser();
      if (_currentUser == null) {
        final userController = UserController.instance;
        if (userController.currentUser.value != null) {
          _currentUser = userController.currentUser.value;
        }
      }
      return _currentUser != null;
    } catch (_) {
      return false;
    }
  }

  // ---------------- Sync flat booking items ----------------
  void _syncFlatBookingItems() {
    bookingItems.assignAll(
      bookingItemsMap.values.expand((items) => items).toList(),
    );
  }

  // ---------------- Totals ----------------
  List<BookingItem> get bookingItemsForUI => bookingItems.toList();

  num itemTotal(BookingItem item) => (item.price ?? 0.0) * (item.quantity ?? 0);

  void _recalculateTotals() {
    int sessions = 0;
    double price = 0.0;
    for (final booking in bookings) {
      final items = bookingItemsMap[booking.id] ?? [];
      for (final item in items) {
        sessions += item.quantity ?? 0;
        price += (item.price ?? 0) * (item.quantity ?? 0);
      }
    }
    totalBookedSessions.value = sessions;
    totalBookingPrice.value = price;
  }

  int totalBookedSessionsForBooking(String bookingId) {
    final items = bookingItemsMap[bookingId] ?? [];
    return items.fold(0, (sum, item) => sum + (item.quantity ?? 0));
  }

  // =========================================================================
  // FETCH
  // =========================================================================
  Future<void> fetchBookings() async {
    if (!await _canSync()) return;

    try {
      final userId = _currentUser!.id;

      const userIdField = amplify_core.QueryField(fieldName: 'userId');
      final result = await Amplify.DataStore.query(
        Booking.classType,
        where: userIdField.eq(userId),
      );

      bookings.assignAll(result);
      bookingItemsMap.clear();

      for (final booking in result) {
        final items = await Amplify.DataStore.query(
          BookingItem.classType,
          where: BookingItem.BOOKING.eq(booking.id),
        );
        if (items.isNotEmpty) {
          bookingItemsMap[booking.id] = items;
        }
      }
      _syncFlatBookingItems();
      _recalculateTotals();

      print(
        'BookingController: loaded ${bookings.length} bookings '
        'with ${bookingItems.length} items for user $userId',
      );
    } catch (e) {
      print('BookingController: fetchBookings error: $e');
    }
  }

  // =========================================================================
  // CREATE BOOKING
  // =========================================================================
  Future<Booking?> createBooking({
    required TutoringSession session,
    List<BookingItem>? items,
    double? totalPrice,
    String status = 'pending',
  }) async {
    if (!await _canSync()) return null;

    try {
      final booking = Booking(
        user: _currentUser,
        bookingItems: items,
        totalPrice: totalPrice,
        status: status,
        createdAt: TemporalDateTime.now(),
        sessionId: session.id,
      );

      await Amplify.DataStore.save(booking);
      bookings.add(booking);

      if (items != null) {
        bookingItemsMap[booking.id] = items;
      }

      _recalculateTotals();
      return booking;
    } catch (e) {
      print('BookingController: createBooking error: $e');
      return null;
    }
  }

  // =========================================================================
  // CREATE BOOKING ITEM
  // =========================================================================
  Future<BookingItem?> createBookingItem({
    required Booking booking,
    String? sessionId,
    String? tutorId,
    double price = 0.0,
    int quantity = 1,
    String serviceTitle = '',
    String serviceImage = '',
    String providerName = '',
    String providerImage = '',
    String timeSlot = '',
    TemporalDateTime? bookingDate,
    Map<String, String>? selectedAttributes,
  }) async {
    if (!await _canSync()) return null;

    try {
      final item = BookingItem(
        booking: booking,
        user: _currentUser,
        sessionId: sessionId,
        tutorId: tutorId,
        price: price,
        quantity: quantity,
        serviceTitle: serviceTitle,
        serviceImage: serviceImage,
        providerName: providerName,
        providerImage: providerImage,
        bookingDate: bookingDate ?? TemporalDateTime.now(),
        timeSlot: timeSlot,
        selectedAttributes:
            selectedAttributes != null ? jsonEncode(selectedAttributes) : null,
      );

      await Amplify.DataStore.save(item);

      final existing = bookingItemsMap[booking.id] ?? [];
      bookingItemsMap[booking.id] = [...existing, item];
      _syncFlatBookingItems();

      _recalculateTotals();
      return item;
    } catch (e) {
      print('BookingController: createBookingItem error: $e');
      return null;
    }
  }

  // =========================================================================
  // CONVENIENCE
  // =========================================================================
  Future<void> addBookingItem({
    required TutoringSession session,
    String? sessionId,
    String? tutorId,
    DateTime? bookingDate,
    String? timeSlot,
    double? price,
    String? serviceTitle,
    String? serviceImage,
    String? tutorName,
    String? tutorImage,
    int quantity = 1,
    Map<String, String>? selectedAttributes,
  }) async {
    if (!await _canSync()) return;

    Booking booking;
    if (bookings.isNotEmpty) {
      booking = bookings.first;
    } else {
      final created = await createBooking(session: session);
      if (created == null) return;
      booking = created;
    }

    await createBookingItem(
      booking: booking,
      sessionId: sessionId,
      tutorId: tutorId,
      bookingDate:
          bookingDate != null
              ? TemporalDateTime(bookingDate)
              : TemporalDateTime.now(),
      timeSlot: timeSlot ?? '',
      price: price ?? 0,
      quantity: quantity,
      serviceTitle: serviceTitle ?? '',
      serviceImage: serviceImage ?? '',
      providerName: tutorName ?? '',
      providerImage: tutorImage ?? '',
      selectedAttributes: selectedAttributes,
    );
  }

  // =========================================================================
  // UPDATE
  // =========================================================================
  Future<void> updateBooking(
    Booking booking, {
    double? totalPrice,
    String? status,
  }) async {
    if (!await _canSync()) return;
    try {
      final updated = booking.copyWith(
        totalPrice: totalPrice ?? booking.totalPrice,
        status: status ?? booking.status,
        updatedAt: TemporalDateTime.now(),
      );
      await Amplify.DataStore.save(updated);
      final index = bookings.indexWhere((b) => b.id == booking.id);
      if (index >= 0) bookings[index] = updated;
    } catch (e) {
      print('BookingController: updateBooking error: $e');
    }
  }

  Future<void> updateBookingItem(
    BookingItem item, {
    int? quantity,
    double? price,
  }) async {
    if (!await _canSync()) return;
    try {
      final updated = item.copyWith(
        quantity: quantity ?? item.quantity ?? 0,
        price: price ?? item.price ?? 0.0,
        updatedAt: TemporalDateTime.now(),
      );
      await Amplify.DataStore.save(updated);
      final items = bookingItemsMap[item.booking?.id ?? ''] ?? [];
      final index = items.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        items[index] = updated;
        bookingItemsMap[item.booking?.id ?? ''] = items;
      }
      _recalculateTotals();
    } catch (e) {
      print('BookingController: updateBookingItem error: $e');
    }
  }

  // =========================================================================
  // DELETE
  // =========================================================================
  Future<void> deleteBooking(Booking booking) async {
    if (!await _canSync()) return;
    try {
      await Amplify.DataStore.delete(booking);
      bookings.removeWhere((b) => b.id == booking.id);
      bookingItemsMap.remove(booking.id);
      _recalculateTotals();
    } catch (e) {
      print('BookingController: deleteBooking error: $e');
    }
  }

  Future<void> deleteBookingItem(BookingItem item) async {
    if (!await _canSync()) return;
    try {
      await Amplify.DataStore.delete(item);
      final items = bookingItemsMap[item.booking?.id ?? ''] ?? [];
      items.removeWhere((i) => i.id == item.id);
      bookingItemsMap[item.booking?.id ?? ''] = items;
      _syncFlatBookingItems();
      _recalculateTotals();
    } catch (e) {
      print('BookingController: deleteBookingItem error: $e');
    }
  }

  // =========================================================================
  // CLEAR on logout / RELOAD on login
  // =========================================================================

  void clearOnLogout() {
    _currentUser = null;
    bookings.clear();
    bookingItemsMap.clear();
    bookingItems.clear();
    totalBookedSessions.value = 0;
    totalBookingPrice.value = 0.0;
  }

  Future<void> reloadForUser() async {
    _currentUser = null;
    await fetchBookings();
  }

  void removeBookingItem(BookingItem item) => deleteBookingItem(item);
  void removeBooking(BookingItem item) => deleteBookingItem(item);
}
