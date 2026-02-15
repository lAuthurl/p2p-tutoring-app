// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../models/ModelProvider.dart';

class BookingController extends GetxController {
  // ---------------- Singleton ----------------
  static BookingController get instance => Get.find();

  // ---------------- Current User ----------------
  final User? currentUser;
  BookingController({this.currentUser}); // ✅ added named parameter

  // ---------------- Reactive State ----------------
  final RxList<Booking> bookings = <Booking>[].obs;
  final RxMap<String, List<BookingItem>> bookingItemsMap =
      <String, List<BookingItem>>{}.obs;
  final RxList<BookingItem> bookingItems = <BookingItem>[].obs;

  RxInt totalBookedSessions = 0.obs;
  RxDouble totalBookingPrice = 0.0.obs;

  // ---------------- Lifecycle ----------------
  @override
  void onInit() {
    super.onInit();

    // Rebuild flat list & totals when map changes
    ever(bookingItemsMap, (_) {
      _syncFlatBookingItems();
      _recalculateTotals();
    });

    // Recalculate totals when bookings change
    ever(bookings, (_) => _recalculateTotals());
  }

  // ---------------- Helper: Check if user can sync ----------------
  Future<bool> _canSync() async {
    if (currentUser == null) {
      print('⚠️ BookingController: No user set yet');
      return false;
    }

    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      return authUser != null;
    } catch (_) {
      print('⚠️ User not signed in, skipping DataStore operations');
      return false;
    }
  }

  // ---------------- Sync flat booking items ----------------
  void _syncFlatBookingItems() {
    bookingItems.clear();
    for (var entry in bookingItemsMap.values) {
      bookingItems.addAll(entry);
    }
  }

  // ---------------- UI Helpers ----------------
  List<BookingItem> get bookingItemsForUI => bookingItems.toList();

  num itemTotal(BookingItem item) {
    final price = item.price ?? 0.0;
    final quantity = item.quantity ?? 0;
    return price * quantity;
  }

  void _recalculateTotals() {
    int sessions = 0;
    double price = 0.0;

    for (var booking in bookings) {
      final items = bookingItemsMap[booking.id] ?? [];
      for (var item in items) {
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

  // ---------------- Fetch Bookings ----------------
  Future<void> fetchBookings() async {
    if (!await _canSync()) return;

    try {
      final userId = currentUser!.id;
      final result = await Amplify.DataStore.query(
        Booking.classType,
        where: Booking.USER.eq(userId),
      );

      bookings.assignAll(result);

      for (var booking in result) {
        final items = await Amplify.DataStore.query(
          BookingItem.classType,
          where: BookingItem.BOOKING.eq(booking.id),
        );

        bookingItemsMap[booking.id] = items;
      }

      print('📦 Bookings loaded: ${bookings.length}');
    } catch (e) {
      print('❌ Failed to fetch bookings: $e');
    }
  }

  // ---------------- Create Booking ----------------
  Future<Booking?> createBooking({
    List<BookingItem>? items,
    double? totalPrice,
    String status = 'pending',
  }) async {
    if (!await _canSync()) return null;

    try {
      final booking = Booking(
        user: currentUser,
        bookingItems: items,
        totalPrice: totalPrice,
        status: status,
        createdAt: TemporalDateTime.now(),
      );

      await Amplify.DataStore.save(booking);
      bookings.add(booking);

      if (items != null) {
        bookingItemsMap[booking.id] = items;
      }

      _recalculateTotals();
      return booking;
    } catch (e) {
      print('❌ Failed to create booking: $e');
      return null;
    }
  }

  // ---------------- Create Booking Item ----------------
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
  }) async {
    if (!await _canSync()) return null;

    try {
      final item = BookingItem(
        booking: booking,
        user: currentUser,
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
      );

      await Amplify.DataStore.save(item);

      final existing = bookingItemsMap[booking.id] ?? [];
      bookingItemsMap[booking.id] = [...existing, item];

      _recalculateTotals();
      return item;
    } catch (e) {
      print('❌ Failed to create booking item: $e');
      return null;
    }
  }

  // ---------------- Add Booking Item Helper ----------------
  Future<void> addBookingItem({
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
  }) async {
    if (!await _canSync()) return;

    // Use existing booking or create a new one
    Booking booking;
    if (bookings.isNotEmpty) {
      booking = bookings.first;
    } else {
      final created = await createBooking();
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
    );
  }

  // ---------------- Update Booking ----------------
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
      print('❌ Failed to update booking: $e');
    }
  }

  // ---------------- Update Booking Item ----------------
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
      print('❌ Failed to update booking item: $e');
    }
  }

  // ---------------- Delete Booking ----------------
  Future<void> deleteBooking(Booking booking) async {
    if (!await _canSync()) return;

    try {
      await Amplify.DataStore.delete(booking);
      bookings.removeWhere((b) => b.id == booking.id);
      bookingItemsMap.remove(booking.id);

      _recalculateTotals();
    } catch (e) {
      print('❌ Failed to delete booking: $e');
    }
  }

  // ---------------- Delete Booking Item ----------------
  Future<void> deleteBookingItem(BookingItem item) async {
    if (!await _canSync()) return;

    try {
      await Amplify.DataStore.delete(item);
      final items = bookingItemsMap[item.booking?.id ?? ''] ?? [];
      items.removeWhere((i) => i.id == item.id);
      bookingItemsMap[item.booking?.id ?? ''] = items;

      _recalculateTotals();
    } catch (e) {
      print('❌ Failed to delete booking item: $e');
    }
  }

  // ---------------- Remove Booking Item Helper ----------------
  void removeBooking(BookingItem item) async {
    await deleteBookingItem(item);
  }
}
