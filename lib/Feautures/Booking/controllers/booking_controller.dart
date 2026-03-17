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

  bool _isFetching = false;
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
    if (userController.currentUser.value != null) {
      _initForUser(userController.currentUser.value!);
      return;
    }
    ever<User?>(userController.currentUser, (user) {
      if (user != null) _initForUser(user);
    });
  }

  Future<void> _initForUser(User user) async {
    if (_currentUser?.id == user.id && bookings.isNotEmpty) return;
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

  // ---------------- Sync helpers ----------------
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

  String? get userId => _currentUser?.id;

  // =========================================================================
  // JSON HELPERS
  // =========================================================================

  /// Parse items from a GraphQL list response using dart:convert.
  /// Handles both wrapped ({ "data": { ... } }) and unwrapped responses.
  ///
  /// ✅ KEY FIX: filters out soft-deleted items (_deleted == true) here.
  /// AppSync with conflict detection CANNOT filter _deleted server-side —
  /// the field is not exposed in GraphQL filter inputs. Every deleted item
  /// stays in DynamoDB with _deleted=true until the TTL expires (days/weeks).
  /// Without this client-side filter, fetchBookings loads deleted bookings,
  /// shows them in the UI, and addSessionToBooking reuses a "deleted" booking
  /// as if it were active — creating BookingItems under a ghost parent.
  List<Map<String, dynamic>> _parseItemsFromResponse(
    String responseData,
    String listKey,
  ) {
    try {
      final decoded = jsonDecode(responseData) as Map<String, dynamic>;
      final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      final listObj = root[listKey] as Map<String, dynamic>?;
      final items = listObj?['items'] as List<dynamic>?;
      if (items == null) return [];
      return items
          .whereType<Map<String, dynamic>>()
          .where((item) => item['id'] != null)
          // ✅ Filter out soft-deleted items — AppSync sets _deleted=true
          // instead of physically removing rows. Without this filter every
          // deleted booking/item reappears on the next fetchBookings call.
          .where((item) => item['_deleted'] != true)
          .toList();
    } catch (e) {
      print('BookingController: _parseItemsFromResponse($listKey) error: $e');
      return [];
    }
  }

  Map<String, dynamic>? _parseSingleFromResponse(
    String responseData,
    String operationKey,
  ) {
    try {
      final decoded = jsonDecode(responseData) as Map<String, dynamic>;
      final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      return root[operationKey] as Map<String, dynamic>?;
    } catch (e) {
      print(
        'BookingController: _parseSingleFromResponse($operationKey) error: $e',
      );
      return null;
    }
  }

  int _versionFromMap(Map<String, dynamic> map) {
    final v = map['_version'];
    if (v == null) return 1;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 1;
  }

  List<BookingItem> _parseBookingItemsFromMaps(
    List<Map<String, dynamic>> maps,
    Booking booking,
  ) {
    final items = <BookingItem>[];
    for (final map in maps) {
      try {
        final id = map['id'] as String?;
        if (id == null) continue;

        _itemVersionCache[id] = _versionFromMap(map);

        items.add(
          BookingItem(
            id: id,
            booking: booking,
            sessionId: map['sessionId'] as String?,
            tutorId: map['tutorId'] as String?,
            serviceTitle: map['serviceTitle'] as String?,
            serviceImage: map['serviceImage'] as String?,
            providerName: map['providerName'] as String?,
            providerImage: map['providerImage'] as String?,
            selectedAttributes: map['selectedAttributes'] as String?,
            timeSlot: map['timeSlot'] as String?,
            price: (map['price'] as num?)?.toDouble(),
            quantity: (map['quantity'] as num?)?.toInt(),
            hasPaid: map['hasPaid'] as bool?,
            bookingDate:
                map['bookingDate'] != null
                    ? TemporalDateTime.fromString(map['bookingDate'] as String)
                    : null,
            createdAt:
                map['createdAt'] != null
                    ? TemporalDateTime.fromString(map['createdAt'] as String)
                    : null,
            updatedAt:
                map['updatedAt'] != null
                    ? TemporalDateTime.fromString(map['updatedAt'] as String)
                    : null,
          ),
        );
      } catch (e) {
        print('BookingController: error parsing BookingItem map: $e');
      }
    }
    return items;
  }

  final _itemVersionCache = <String, int>{};
  final _bookingVersionCache = <String, int>{};

  // =========================================================================
  // FETCH LIVE VERSIONS
  // =========================================================================

  Future<int?> _fetchLiveItemVersion(String itemId) async {
    try {
      const query = r"""
        query GetBookingItem($id: ID!) {
          getBookingItem(id: $id) { id _version _deleted }
        }
      """;
      final response =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: query,
                  variables: {'id': itemId},
                ),
              )
              .response;
      if (response.errors.isNotEmpty || response.data == null) return null;
      final obj = _parseSingleFromResponse(response.data!, 'getBookingItem');
      // Return null if item is already soft-deleted — treat as gone.
      if (obj == null || obj['_deleted'] == true) return null;
      final v = _versionFromMap(obj);
      _itemVersionCache[itemId] = v;
      return v;
    } catch (e) {
      print('BookingController: _fetchLiveItemVersion error: $e');
      return null;
    }
  }

  Future<int?> _fetchLiveBookingVersion(String bookingId) async {
    try {
      const query = r"""
        query GetBooking($id: ID!) {
          getBooking(id: $id) { id _version _deleted }
        }
      """;
      final response =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: query,
                  variables: {'id': bookingId},
                ),
              )
              .response;
      if (response.errors.isNotEmpty || response.data == null) return null;
      final obj = _parseSingleFromResponse(response.data!, 'getBooking');
      if (obj == null || obj['_deleted'] == true) return null;
      final v = _versionFromMap(obj);
      _bookingVersionCache[bookingId] = v;
      return v;
    } catch (e) {
      print('BookingController: _fetchLiveBookingVersion error: $e');
      return null;
    }
  }

  // =========================================================================
  // FETCH
  // =========================================================================
  Future<void> fetchBookings() async {
    if (_isFetching) {
      print('BookingController: fetchBookings already in progress — skip');
      return;
    }
    if (!await _canSync()) return;

    _isFetching = true;
    try {
      final uid = _currentUser!.id;

      // ✅ Request _deleted in the query so _parseItemsFromResponse can
      // filter it out client-side (AppSync doesn't expose it as a filter).
      const bookingQuery = r"""
        query ListBookingsByUser($userId: ID!, $limit: Int) {
          listBookings(filter: { userId: { eq: $userId } }, limit: $limit) {
            items {
              id
              sessionId
              status
              totalPrice
              userId
              createdAt
              updatedAt
              _version
              _deleted
            }
          }
        }
      """;

      const itemQuery = r"""
        query ListBookingItemsByBooking($bookingId: ID!, $limit: Int) {
          listBookingItems(
            filter: { bookingId: { eq: $bookingId } }
            limit: $limit
          ) {
            items {
              id
              bookingId
              userId
              sessionId
              tutorId
              serviceTitle
              serviceImage
              providerName
              providerImage
              timeSlot
              price
              quantity
              selectedAttributes
              hasPaid
              bookingDate
              createdAt
              updatedAt
              _version
              _deleted
            }
          }
        }
      """;

      final bookingResponse =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: bookingQuery,
                  variables: {'userId': uid, 'limit': 100},
                ),
              )
              .response;

      if (bookingResponse.errors.isNotEmpty || bookingResponse.data == null) {
        print(
          'BookingController: fetchBookings error: ${bookingResponse.errors}',
        );
        return;
      }

      // _parseItemsFromResponse already filters out _deleted=true items.
      final bookingMaps = _parseItemsFromResponse(
        bookingResponse.data!,
        'listBookings',
      );

      print(
        'BookingController: found ${bookingMaps.length} active bookings for user $uid',
      );

      if (bookingMaps.isEmpty) {
        bookings.clear();
        bookingItemsMap.clear();
        _syncFlatBookingItems();
        _recalculateTotals();
        return;
      }

      final fetchedBookings = <Booking>[];
      final newMap = <String, List<BookingItem>>{};

      for (final bMap in bookingMaps) {
        final bookingId = bMap['id'] as String?;
        final sessionId = bMap['sessionId'] as String?;

        if (bookingId == null || sessionId == null || sessionId.isEmpty) {
          print(
            'BookingController: skipping booking with missing id or sessionId',
          );
          continue;
        }

        _bookingVersionCache[bookingId] = _versionFromMap(bMap);

        final booking = Booking(
          id: bookingId,
          sessionId: sessionId,
          status: bMap['status'] as String?,
          totalPrice: (bMap['totalPrice'] as num?)?.toDouble(),
          createdAt:
              bMap['createdAt'] != null
                  ? TemporalDateTime.fromString(bMap['createdAt'] as String)
                  : null,
          updatedAt:
              bMap['updatedAt'] != null
                  ? TemporalDateTime.fromString(bMap['updatedAt'] as String)
                  : null,
        );
        fetchedBookings.add(booking);

        final itemResponse =
            await Amplify.API
                .query(
                  request: GraphQLRequest<String>(
                    document: itemQuery,
                    variables: {'bookingId': bookingId, 'limit': 50},
                  ),
                )
                .response;

        if (itemResponse.errors.isEmpty && itemResponse.data != null) {
          // _parseItemsFromResponse filters out _deleted=true items here too.
          final itemMaps = _parseItemsFromResponse(
            itemResponse.data!,
            'listBookingItems',
          );
          final parsedItems = _parseBookingItemsFromMaps(itemMaps, booking);
          if (parsedItems.isNotEmpty) {
            newMap[bookingId] = parsedItems;
          }
        }
      }

      bookings.assignAll(fetchedBookings);
      bookingItemsMap.assignAll(newMap);
      _syncFlatBookingItems();
      _recalculateTotals();

      print(
        'BookingController: loaded ${bookings.length} active bookings '
        'with ${bookingItems.length} items for user $uid',
      );
    } catch (e) {
      print('BookingController: fetchBookings error: $e');
    } finally {
      _isFetching = false;
    }
  }

  // =========================================================================
  // CREATE BOOKING
  // =========================================================================
  Future<Booking?> createBooking({
    required TutoringSession session,
    double? totalPrice,
    String status = 'pending',
  }) async {
    if (!await _canSync()) return null;

    try {
      final bookingId = amplify_core.UUID.getUUID();
      final now = DateTime.now().toUtc().toIso8601String();

      const mutationDoc = r"""
        mutation CreateBooking($input: CreateBookingInput!) {
          createBooking(input: $input) {
            id
            sessionId
            status
            totalPrice
            userId
            createdAt
            updatedAt
            _version
          }
        }
      """;

      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: {
                    'input': {
                      'id': bookingId,
                      'sessionId': session.id,
                      'userId': _currentUser!.id,
                      'status': status,
                      'totalPrice': totalPrice,
                      'createdAt': now,
                      'updatedAt': now,
                    },
                  },
                ),
              )
              .response;

      if (response.errors.isNotEmpty) {
        print('BookingController: createBooking error: ${response.errors}');
        return null;
      }

      final obj = _parseSingleFromResponse(
        response.data ?? '',
        'createBooking',
      );
      if (obj != null) _bookingVersionCache[bookingId] = _versionFromMap(obj);

      final booking = Booking(
        id: bookingId,
        sessionId: session.id,
        status: status,
        totalPrice: totalPrice,
        createdAt: TemporalDateTime.fromString(now),
        updatedAt: TemporalDateTime.fromString(now),
      );

      bookings.add(booking);
      _recalculateTotals();

      print('BookingController: createBooking success: $bookingId');
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
      final itemId = amplify_core.UUID.getUUID();
      final now = DateTime.now().toUtc().toIso8601String();
      final bookingDateStr = bookingDate?.format() ?? now;

      const mutationDoc = r"""
        mutation CreateBookingItem($input: CreateBookingItemInput!) {
          createBookingItem(input: $input) {
            id
            bookingId
            userId
            sessionId
            tutorId
            serviceTitle
            serviceImage
            providerName
            providerImage
            timeSlot
            price
            quantity
            selectedAttributes
            hasPaid
            bookingDate
            createdAt
            updatedAt
            _version
          }
        }
      """;

      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: {
                    'input': {
                      'id': itemId,
                      'bookingId': booking.id,
                      'userId': _currentUser!.id,
                      'sessionId': sessionId,
                      'tutorId': tutorId,
                      'price': price,
                      'quantity': quantity,
                      'serviceTitle': serviceTitle,
                      'serviceImage': serviceImage,
                      'providerName': providerName,
                      'providerImage': providerImage,
                      'timeSlot': timeSlot,
                      'bookingDate': bookingDateStr,
                      'createdAt': now,
                      'updatedAt': now,
                      'hasPaid': false,
                      'selectedAttributes':
                          selectedAttributes != null
                              ? jsonEncode(selectedAttributes)
                              : null,
                    },
                  },
                ),
              )
              .response;

      if (response.errors.isNotEmpty) {
        print('BookingController: createBookingItem error: ${response.errors}');
        return null;
      }

      final obj = _parseSingleFromResponse(
        response.data ?? '',
        'createBookingItem',
      );
      if (obj != null) _itemVersionCache[itemId] = _versionFromMap(obj);

      final item = BookingItem(
        id: itemId,
        booking: booking,
        sessionId: sessionId,
        tutorId: tutorId,
        price: price,
        quantity: quantity,
        serviceTitle: serviceTitle,
        serviceImage: serviceImage,
        providerName: providerName,
        providerImage: providerImage,
        timeSlot: timeSlot,
        bookingDate: TemporalDateTime.fromString(bookingDateStr),
        createdAt: TemporalDateTime.fromString(now),
        updatedAt: TemporalDateTime.fromString(now),
        hasPaid: false,
        selectedAttributes:
            selectedAttributes != null ? jsonEncode(selectedAttributes) : null,
      );

      final existing = bookingItemsMap[booking.id] ?? [];
      bookingItemsMap[booking.id] = [...existing, item];
      _syncFlatBookingItems();
      _recalculateTotals();

      print('BookingController: createBookingItem success: $itemId');
      return item;
    } catch (e) {
      print('BookingController: createBookingItem error: $e');
      return null;
    }
  }

  // =========================================================================
  // DELETE BOOKING ITEM
  // =========================================================================
  Future<void> deleteBookingItem(BookingItem item) async {
    if (!await _canSync()) return;

    _removeItemFromLocalState(item);

    try {
      await _deleteBookingItemWithRetry(item.id, maxRetries: 2);
    } catch (e) {
      print('BookingController: deleteBookingItem failed, rolling back: $e');
      final bookingId = item.booking?.id ?? '';
      final existing = List<BookingItem>.from(bookingItemsMap[bookingId] ?? []);
      if (!existing.any((i) => i.id == item.id)) {
        bookingItemsMap[bookingId] = [...existing, item];
        _syncFlatBookingItems();
        _recalculateTotals();
      }
    }
  }

  void _removeItemFromLocalState(BookingItem item) {
    final bookingId = item.booking?.id ?? '';
    final items = List<BookingItem>.from(bookingItemsMap[bookingId] ?? []);
    items.removeWhere((i) => i.id == item.id);
    bookingItemsMap[bookingId] = items;
    _syncFlatBookingItems();
    _recalculateTotals();
    _itemVersionCache.remove(item.id);
  }

  Future<void> _deleteBookingItemWithRetry(
    String itemId, {
    int maxRetries = 2,
  }) async {
    const mutationDoc = r"""
      mutation DeleteBookingItem($input: DeleteBookingItemInput!) {
        deleteBookingItem(input: $input) { id _version }
      }
    """;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final version = await _fetchLiveItemVersion(itemId);
      if (version == null) {
        // Already soft-deleted or doesn't exist — nothing to do.
        print('BookingController: item $itemId already deleted or not found');
        return;
      }

      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: {
                    'input': {'id': itemId, '_version': version},
                  },
                ),
              )
              .response;

      if (response.errors.isEmpty) {
        print(
          'BookingController: deleteBookingItem success: $itemId (attempt ${attempt + 1})',
        );
        return;
      }

      final isConflict = response.errors.any(
        (e) =>
            e.extensions?['errorType']?.toString().contains('Conflict') == true,
      );

      if (isConflict && attempt < maxRetries - 1) {
        print('BookingController: conflict on $itemId — retrying');
        continue;
      }

      throw Exception('deleteBookingItem failed: ${response.errors}');
    }
  }

  // =========================================================================
  // DELETE BOOKING
  // =========================================================================
  Future<void> deleteBooking(Booking booking) async {
    if (!await _canSync()) return;

    try {
      await _deleteBookingWithRetry(booking.id, maxRetries: 2);
      bookings.removeWhere((b) => b.id == booking.id);
      bookingItemsMap.remove(booking.id);
      _recalculateTotals();
      _bookingVersionCache.remove(booking.id);
      print('BookingController: deleteBooking success: ${booking.id}');
    } catch (e) {
      print('BookingController: deleteBooking error: $e');
    }
  }

  Future<void> _deleteBookingWithRetry(
    String bookingId, {
    int maxRetries = 2,
  }) async {
    const mutationDoc = r"""
      mutation DeleteBooking($input: DeleteBookingInput!) {
        deleteBooking(input: $input) { id _version }
      }
    """;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final version = await _fetchLiveBookingVersion(bookingId);
      if (version == null) {
        print(
          'BookingController: booking $bookingId already deleted or not found',
        );
        return;
      }

      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: {
                    'input': {'id': bookingId, '_version': version},
                  },
                ),
              )
              .response;

      if (response.errors.isEmpty) {
        print(
          'BookingController: deleteBooking success: $bookingId (attempt ${attempt + 1})',
        );
        return;
      }

      final isConflict = response.errors.any(
        (e) =>
            e.extensions?['errorType']?.toString().contains('Conflict') == true,
      );

      if (isConflict && attempt < maxRetries - 1) {
        print('BookingController: conflict on booking $bookingId — retrying');
        continue;
      }

      throw Exception('deleteBooking failed: ${response.errors}');
    }
  }

  // =========================================================================
  // REMOVE BOOKING ITEM (public)
  // =========================================================================
  Future<void> removeBookingItem(BookingItem item) async {
    await deleteBookingItem(item);

    final bookingId = item.booking?.id ?? '';
    if (bookingId.isNotEmpty) {
      final remaining = List<BookingItem>.from(
        bookingItemsMap[bookingId] ?? [],
      );
      if (remaining.isEmpty) {
        final parentBooking = bookings.firstWhereOrNull(
          (b) => b.id == bookingId,
        );
        if (parentBooking != null) {
          await deleteBooking(parentBooking);
        }
      }
    }
  }

  void removeBooking(BookingItem item) => removeBookingItem(item);

  // =========================================================================
  // CLEAR BOOKING — called after successful payment
  // =========================================================================
  Future<void> clearBooking() async {
    if (!await _canSync()) return;

    try {
      for (final booking in List<Booking>.from(bookings)) {
        final items = List<BookingItem>.from(bookingItemsMap[booking.id] ?? []);
        for (final item in items) {
          await deleteBookingItem(item);
        }
        await deleteBooking(booking);
      }
    } catch (e) {
      print('BookingController: clearBooking error: $e');
    } finally {
      bookings.clear();
      bookingItemsMap.clear();
      bookingItems.clear();
      totalBookedSessions.value = 0;
      totalBookingPrice.value = 0.0;
    }
  }

  // =========================================================================
  // CONVENIENCE — addBookingItem
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
  // UPDATE BOOKING
  // =========================================================================
  Future<void> updateBooking(
    Booking booking, {
    double? totalPrice,
    String? status,
  }) async {
    if (!await _canSync()) return;

    try {
      final version =
          await _fetchLiveBookingVersion(booking.id) ??
          _bookingVersionCache[booking.id] ??
          1;

      const mutationDoc = r"""
        mutation UpdateBooking($input: UpdateBookingInput!) {
          updateBooking(input: $input) {
            id sessionId status totalPrice updatedAt _version
          }
        }
      """;

      final now = DateTime.now().toUtc().toIso8601String();
      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: {
                    'input': {
                      'id': booking.id,
                      '_version': version,
                      'status': status ?? booking.status,
                      'totalPrice': totalPrice ?? booking.totalPrice,
                      'updatedAt': now,
                    },
                  },
                ),
              )
              .response;

      if (response.errors.isNotEmpty) {
        print('BookingController: updateBooking error: ${response.errors}');
        return;
      }

      final updated = booking.copyWith(
        totalPrice: totalPrice ?? booking.totalPrice,
        status: status ?? booking.status,
        updatedAt: TemporalDateTime.fromString(now),
      );
      final index = bookings.indexWhere((b) => b.id == booking.id);
      if (index >= 0) bookings[index] = updated;
    } catch (e) {
      print('BookingController: updateBooking error: $e');
    }
  }

  // =========================================================================
  // UPDATE BOOKING ITEM
  // =========================================================================
  Future<void> updateBookingItem(
    BookingItem item, {
    int? quantity,
    double? price,
  }) async {
    if (!await _canSync()) return;

    try {
      final version =
          await _fetchLiveItemVersion(item.id) ??
          _itemVersionCache[item.id] ??
          1;

      const mutationDoc = r"""
        mutation UpdateBookingItem($input: UpdateBookingItemInput!) {
          updateBookingItem(input: $input) {
            id price quantity updatedAt _version
          }
        }
      """;

      final now = DateTime.now().toUtc().toIso8601String();
      final response =
          await Amplify.API
              .mutate(
                request: GraphQLRequest<String>(
                  document: mutationDoc,
                  variables: {
                    'input': {
                      'id': item.id,
                      '_version': version,
                      'quantity': quantity ?? item.quantity ?? 0,
                      'price': price ?? item.price ?? 0.0,
                      'updatedAt': now,
                    },
                  },
                ),
              )
              .response;

      if (response.errors.isNotEmpty) {
        print('BookingController: updateBookingItem error: ${response.errors}');
        return;
      }

      final updated = item.copyWith(
        quantity: quantity ?? item.quantity ?? 0,
        price: price ?? item.price ?? 0.0,
        updatedAt: TemporalDateTime.fromString(now),
      );
      final bookingId = item.booking?.id ?? '';
      final items = List<BookingItem>.from(bookingItemsMap[bookingId] ?? []);
      final index = items.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        items[index] = updated;
        bookingItemsMap[bookingId] = items;
      }
      _recalculateTotals();
    } catch (e) {
      print('BookingController: updateBookingItem error: $e');
    }
  }

  // =========================================================================
  // CLEAR on logout / RELOAD on login
  // =========================================================================
  void clearOnLogout() {
    _currentUser = null;
    _isFetching = false;
    _itemVersionCache.clear();
    _bookingVersionCache.clear();
    bookings.clear();
    bookingItemsMap.clear();
    bookingItems.clear();
    totalBookedSessions.value = 0;
    totalBookingPrice.value = 0.0;
  }

  Future<void> reloadForUser() async {
    _currentUser = null;
    _isFetching = false;
    await fetchBookings();
  }
}
