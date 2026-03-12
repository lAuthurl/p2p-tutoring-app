// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:path/path.dart' as p;
import '../../../personalization/controllers/user_controller.dart';
import '../../Booking/controllers/booking_controller.dart';
import '../../../../models/ModelProvider.dart';
import 'session_creation_controller.dart';

class TutoringController extends GetxController {
  // ---------------- Singleton ----------------
  static TutoringController get instance {
    if (Get.isRegistered<TutoringController>()) return Get.find();
    return Get.put(TutoringController());
  }

  // ---------------- Auth User ----------------
  Future<String?> get authUserId async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user.userId;
    } catch (_) {
      return null;
    }
  }

  // ---------------- Current User Tutor ID ----------------
  Future<String?> get currentUserTutorId async {
    try {
      final user = UserController.instance.currentUser.value;
      final userEmail = user?.email;
      if (userEmail == null || userEmail.isEmpty) return null;

      final tutors = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.EMAIL.eq(userEmail),
      );

      if (tutors.isEmpty) return null;
      return tutors.first.id;
    } catch (e) {
      print('❌ Error fetching current user tutor ID: $e');
      return null;
    }
  }

  // ---------------- Reactive State ----------------
  final sessions = <TutoringSession>[].obs;
  final featuredSessions = <TutoringSession>[].obs;
  final popularSessions = <TutoringSession>[].obs;

  /// Sessions belonging to the currently logged-in tutor.
  /// Used by InboxScreen to list conversations.
  final activeSessions = <TutoringSession>[].obs;

  final selectedAttributes = <String, String>{}.obs;
  final selectedSessionImage = ''.obs;

  final favorites = <String, RxBool>{}.obs;
  final isSynced = false.obs;

  final sessionMessages = <String, List<ChatMessage>>{}.obs;

  // ---------------- Unread Counts ----------------
  // Tracks how many unread messages each session has.
  // Incremented when a new message arrives for a session that isn't
  // currently open, reset when the user opens/marks that session read.
  final _unreadCounts = <String, int>{};

  // Holds the sessionId the user currently has open in ChatScreen.
  // Set this when ChatScreen is entered; clear it on dispose.
  String? currentOpenSessionId;

  int unreadCount(String sessionId) => _unreadCounts[sessionId] ?? 0;

  // ---------------- Lifecycle ----------------
  @override
  void onInit() {
    super.onInit();
    _observeSessions();
    fetchTutorSessions(); // ← add this line
  }

  // ---------------- Helper: Check if user can sync ----------------
  Future<bool> _canSync() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user != null;
    } catch (_) {
      print('⚠️ User not signed in, skipping DataStore operations');
      return false;
    }
  }

  // ---------------- AWS DataStore Observers ----------------
  void _observeSessions() async {
    if (!await _canSync()) return;
    try {
      Amplify.DataStore.observeQuery(TutoringSession.classType).listen((
        snapshot,
      ) {
        final awsSessions =
            snapshot.items.whereType<TutoringSession>().toList();
        if (awsSessions.isNotEmpty) _mergeSessions(awsSessions);
        isSynced.value = snapshot.isSynced;
      }, onError: (e) => print('❌ Error observing sessions: $e'));
    } catch (e) {
      print('❌ Failed to start observeQuery: $e');
    }
  }

  void _mergeSessions(List<TutoringSession> newSessions) {
    sessions.assignAll(newSessions);
    featuredSessions.assignAll(
      sessions.where((s) => s.isFeatured == true).toList(),
    );
    popularSessions.assignAll(
      sessions.length > 4 ? sessions.sublist(0, 4) : sessions.toList(),
    );
  }

  Future<void> fetchSessions() async {
    if (!await _canSync()) return;
    try {
      final sessionsResponse = await Amplify.DataStore.query(
        TutoringSession.classType,
      );
      if (sessionsResponse.isEmpty) return;
      _mergeSessions(sessionsResponse);
    } catch (e) {
      print('❌ Error fetching sessions: $e');
    }
  }

  /// Queries ALL ChatMessages whose sessionId starts with any of this
  /// tutor's session IDs (format: baseSessionId_studentUserId).
  /// This discovers every unique student thread and subscribes to each.
  /// Call after [fetchTutorSessions] so [activeSessions] is populated.
  Future<void> fetchAllStudentThreads() async {
    if (!await _canSync()) return;
    try {
      for (final session in activeSessions) {
        // Query all messages whose sessionId contains the base session id.
        // DataStore doesn't support "startsWith" so we query all messages
        // for the base id first, then extract unique scoped chatIds.
        final allMessages = await Amplify.DataStore.query(
          ChatMessage.classType,
        );

        final relatedChatIds =
            allMessages
                .where((m) => (m.sessionId).startsWith(session.id))
                .map((m) => m.sessionId)
                .toSet();

        for (final chatId in relatedChatIds) {
          if (!sessionMessages.containsKey(chatId)) {
            observeChat(chatId);
          }
        }
      }
    } catch (e) {
      print('❌ fetchAllStudentThreads error: $e');
    }
  }

  /// Fetches all sessions where the logged-in user is the tutor,
  /// populates [activeSessions], and pre-warms [sessionMessages]
  /// by subscribing to each session's chat stream.
  ///
  /// Call this from your tutor home / inbox screen's initState,
  /// or add it to onInit() if the user is always a tutor.
  Future<void> fetchTutorSessions() async {
    if (!await _canSync()) return;

    try {
      final tutorId = await currentUserTutorId;
      if (tutorId == null) {
        print('⚠️ fetchTutorSessions: no tutor ID found');
        return;
      }

      final results = await Amplify.DataStore.query(
        TutoringSession.classType,
        where: TutoringSession.TUTOR.eq(tutorId),
      );

      activeSessions.assignAll(results.whereType<TutoringSession>().toList());

      // Pre-warm message subscriptions so the inbox shows latest messages
      // as soon as it opens, without waiting for the user to tap each row.
      for (final session in activeSessions) {
        observeChat(session.id);
      }

      print('✅ fetchTutorSessions: loaded ${activeSessions.length} sessions');
    } catch (e) {
      print('❌ fetchTutorSessions error: $e');
    }
  }

  // ---------------- Session Utilities ----------------
  double _computeAdjustedPrice(
    TutoringSession session,
    Map<String, String>? attributes,
  ) {
    double price = session.pricePerSession ?? 0.0;

    final duration = attributes?['Duration']?.toLowerCase() ?? '';
    if (duration.contains('2hr') ||
        duration.contains('2 h') ||
        duration.contains('2h')) {
      price *= 2;
    }

    final mode = attributes?['Mode']?.toLowerCase() ?? '';
    if (mode.contains('in-person') ||
        mode.contains('offline') ||
        mode.contains('physical')) {
      price *= 1.2;
    }

    return price;
  }

  String getSessionPrice(TutoringSession session) {
    final price = _computeAdjustedPrice(session, selectedAttributes);
    return price % 1 == 0 ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
  }

  void initializeSelectedAttributes(TutoringSession session) {
    selectedAttributes.clear();
    if (session.sessionAttributes?.isNotEmpty ?? false) {
      for (var attr in session.sessionAttributes!) {
        if (attr.values?.isNotEmpty ?? false) {
          selectedAttributes[attr.name] = attr.values!.first;
        }
      }
    }
    selectedAttributes.putIfAbsent('Duration', () => '1hr');
    selectedAttributes.putIfAbsent('Mode', () => 'Online');

    selectedSessionImage.value =
        session.images?.isNotEmpty == true
            ? session.images!.first
            : session.thumbnail ?? '';
  }

  // ---------------- Reactive Booking Helper ----------------
  Future<void> addSessionToBooking(
    TutoringSession session, {
    Map<String, String>? selectedAttributes,
    int quantity = 1,
    String? controllerTag,
  }) async {
    if (!await _canSync()) return;

    final bookingController = BookingController.instance;

    Booking booking;
    if (bookingController.bookings.isNotEmpty) {
      booking = bookingController.bookings.first;
    } else {
      final created = await bookingController.createBooking(session: session);
      if (created == null) return;
      booking = created;
    }

    final tagToUse = controllerTag ?? session.id;
    final sessionController = Get.find<SessionCreationController>(
      tag: tagToUse,
    );

    final double finalPrice = sessionController.calculateDynamicPrice(session);

    await bookingController.createBookingItem(
      booking: booking,
      sessionId: session.id,
      tutorId: session.tutor?.id,
      price: finalPrice,
      quantity: quantity,
      serviceTitle: session.title,
      serviceImage: session.images?.first ?? session.thumbnail ?? '',
      providerName: session.tutor?.name ?? '',
      providerImage: session.tutor?.image ?? '',
      selectedAttributes: selectedAttributes,
      bookingDate: TemporalDateTime.now(),
    );

    Get.back();

    Get.snackbar(
      "Added to Booking",
      "Session added with your selected options",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ---------------- Favorites ----------------
  bool isFavourite(String sessionId) => favorites[sessionId]?.value ?? false;

  void toggleFavoriteSession(String sessionId) {
    if (!favorites.containsKey(sessionId)) {
      favorites[sessionId] = true.obs;
    } else {
      favorites[sessionId]!.value = !favorites[sessionId]!.value;
    }
  }

  List<TutoringSession> favoriteSessions() =>
      sessions.where((s) => isFavourite(s.id)).toList();

  List<String> getAllSessionImages(TutoringSession session) {
    final List<String> images = [];
    if ((session.thumbnail?.isNotEmpty ?? false)) {
      images.add(session.thumbnail!);
    }
    if ((session.images?.isNotEmpty ?? false)) images.addAll(session.images!);
    return images;
  }

  List<Map<String, String>> generateCombinationsForUI(TutoringSession session) {
    List<Map<String, String>> combos = [{}];
    session.sessionAttributes?.forEach((attr) {
      final values = attr.values ?? [];
      List<Map<String, String>> newList = [];
      for (var combo in combos) {
        for (var val in values) {
          newList.add({...combo, attr.name: val});
        }
      }
      combos = newList;
    });
    return combos;
  }

  // ---------------- Sale Calculation ----------------
  int calculateSalePercentage(double originalPrice, double? discountedPrice) {
    if (discountedPrice == null || discountedPrice >= originalPrice) return 0;
    return ((1 - (discountedPrice / originalPrice)) * 100).round();
  }

  // ---------------- Compute Price Based on Selected Attributes ----------------
  double computeSelectedAttributesPrice() {
    if (sessions.isEmpty) return 0.0;

    final session = sessions.firstWhere(
      (s) => s.id == selectedSessionImage.value,
      orElse: () => sessions.first,
    );

    return _computeAdjustedPrice(session, selectedAttributes);
  }

  // ---------------- Reviews ----------------
  Future<Review> addReview({
    required TutoringSession session,
    required double rating,
    required String comment,
  }) async {
    if (!await _canSync()) throw Exception("User not signed in");
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      final userList = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(authUser.userId),
      );
      final currentUser = userList.first;

      final tutorList = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.ID.eq(session.tutor!.id),
      );
      final currentTutor = tutorList.first;

      final review = Review(
        user: currentUser,
        sessionId: session.id,
        tutor: currentTutor,
        rating: rating,
        comment: comment,
        createdAt: TemporalDateTime.now(),
      );

      await Amplify.DataStore.save(review);
      return review;
    } catch (e) {
      print('❌ Error adding review for session ${session.id}: $e');
      rethrow;
    }
  }

  Future<List<Review>> fetchReviews(String sessionId) async {
    if (!await _canSync()) return [];
    try {
      final reviews = await Amplify.DataStore.query(
        Review.classType,
        where: Review.SESSIONID.eq(sessionId),
      );
      return reviews.where((r) => r.createdAt != null).toList();
    } catch (e) {
      print('❌ Error fetching reviews for session $sessionId: $e');
      return [];
    }
  }

  Future<List<Review>> addReviewAndFetch({
    required TutoringSession session,
    required double rating,
    required String comment,
  }) async {
    final newReview = await addReview(
      session: session,
      rating: rating,
      comment: comment,
    );
    print(
      '✅ Review created at (UTC): ${newReview.createdAt!.getDateTimeInUtc()}',
    );
    return await fetchReviews(session.id);
  }

  Future<List<Review>> fetchReviewsByTutor(String tutorId) async {
    try {
      final reviews = await Amplify.DataStore.query(
        Review.classType,
        where: Review.TUTOR.eq(tutorId),
      );
      return reviews;
    } catch (e) {
      print("❌ Error fetching reviews for tutor $tutorId: $e");
      return [];
    }
  }

  // ---------------- Chat Sessions ----------------
  List<String> get chatSessions => sessionMessages.keys.toList();

  // ---------------- Chat ----------------

  /// Resolves the display name for the current user.
  /// Checks the User table first (username), then Tutor table (name),
  /// then falls back to the Cognito username attribute.
  Future<String> _resolveSenderName(String userId) async {
    try {
      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(userId),
      );
      if (users.isNotEmpty && (users.first.username.isNotEmpty)) {
        return users.first.username;
      }
    } catch (_) {}

    try {
      final tutors = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.ID.eq(userId),
      );
      if (tutors.isNotEmpty && (tutors.first.name.isNotEmpty)) {
        return tutors.first.name;
      }
    } catch (_) {}

    // Last resort: Cognito username
    try {
      final attrs = await Amplify.Auth.fetchUserAttributes();
      final nameAttr = attrs.firstWhere(
        (a) =>
            a.userAttributeKey.key == 'name' ||
            a.userAttributeKey.key == 'preferred_username',
        orElse: () => attrs.first,
      );
      return nameAttr.value;
    } catch (_) {}

    return 'User';
  }

  Future<void> sendMessage(String sessionId, String text) async {
    if (!await _canSync()) return;

    final authUser = await Amplify.Auth.getCurrentUser();
    final userId = authUser.userId;
    if (userId == null) return;

    final senderName = await _resolveSenderName(userId);

    final message = ChatMessage(
      sessionId: sessionId,
      senderId: userId,
      senderName: senderName,
      text: text,
      isVoice: false,
      createdAt: TemporalDateTime.now(),
    );

    await Amplify.DataStore.save(message);
  }

  Future<void> sendVoiceMessage(String sessionId, File audioFile) async {
    if (!await _canSync()) return;

    final authUser = await Amplify.Auth.getCurrentUser();
    final userId = authUser.userId;
    if (userId == null) return;

    final senderName = await _resolveSenderName(userId);

    final key =
        'chat/$sessionId/${DateTime.now().millisecondsSinceEpoch}${p.extension(audioFile.path)}';

    try {
      final uploadResult =
          await Amplify.Storage.uploadFile(
            localFile: AWSFile.fromPath(audioFile.path),
            path: StoragePath.fromString(key),
          ).result;

      final urlResult =
          await Amplify.Storage.getUrl(
            path: StoragePath.fromString(uploadResult.uploadedItem.path),
          ).result;
      final presignedUrl = urlResult.url.toString();

      final message = ChatMessage(
        sessionId: sessionId,
        senderId: userId,
        senderName: senderName,
        text: null,
        audioUrl: presignedUrl,
        isVoice: true,
        createdAt: TemporalDateTime.now(),
      );

      await Amplify.DataStore.save(message);

      // _onNewMessage handles updating sessionMessages + unread counts,
      // but voice messages are saved directly here so we call it manually.
      _onNewMessage(message);
    } on StorageException catch (e) {
      print('❌ S3 Upload or URL failed: ${e.message}');
    }
  }

  /// Subscribes to real-time updates for a single session's messages.
  /// Safe to call multiple times — GetX / DataStore deduplicates internally.
  ///
  /// All incoming messages are routed through [_onNewMessage] so unread
  /// counts are always kept in sync.
  void observeChat(String sessionId) {
    Amplify.DataStore.observeQuery(
      ChatMessage.classType,
      where: ChatMessage.SESSIONID.eq(sessionId),
    ).listen((snapshot) {
      final msgs = snapshot.items.whereType<ChatMessage>().toList();
      msgs.sort(
        (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now()).compareTo(
          b.createdAt?.getDateTimeInUtc() ?? DateTime.now(),
        ),
      );

      // Detect truly new messages (not just a re-sync of existing ones)
      // by comparing against what we already have stored locally.
      final existing = sessionMessages[sessionId] ?? [];
      final existingIds = existing.map((m) => m.id).toSet();

      for (final msg in msgs) {
        if (!existingIds.contains(msg.id)) {
          _onNewMessage(msg);
        }
      }

      // Always replace the full list so ordering and edits stay correct.
      sessionMessages[sessionId] = msgs;
    });
  }

  /// Central handler for every new inbound message.
  ///
  /// • Updates [sessionMessages] with the new message.
  /// • Increments [_unreadCounts] only when the session is NOT currently
  ///   open (i.e. the user isn't already looking at it).
  void _onNewMessage(ChatMessage msg) {
    final id = msg.sessionId;
    if (id == null) return;

    // Update local message list
    sessionMessages.update(id, (list) => list..add(msg), ifAbsent: () => [msg]);

    // Only count as unread if this session isn't the one currently open
    if (currentOpenSessionId != id) {
      _unreadCounts[id] = (_unreadCounts[id] ?? 0) + 1;
      // Nudge GetX so InboxScreen badge re-renders
      sessionMessages.refresh();
    }
  }

  // ---------------- Mark Chat Session Read ----------------
  /// Resets the unread badge for [sessionId] to zero.
  ///
  /// Call this when the user opens a ChatScreen.
  /// Also set [currentOpenSessionId] so subsequent messages don't
  /// re-increment the count while the screen is open.
  void markSessionRead(String sessionId) {
    _unreadCounts[sessionId] = 0;
    currentOpenSessionId = sessionId;
    sessionMessages.refresh();
  }

  /// Call this when the user leaves ChatScreen (in dispose / onClose).
  void clearCurrentOpenSession() {
    currentOpenSessionId = null;
  }

  // ---------------- Delete Session ----------------
  Future<bool> deleteSession(String sessionId) async {
    if (!await _canSync()) return false;

    try {
      TutoringSession session;
      try {
        session = sessions.firstWhere((s) => s.id == sessionId);
      } catch (_) {
        print('⚠️ Session $sessionId not found locally');
        return false;
      }

      final attributes = await Amplify.DataStore.query(
        SessionAttribute.classType,
        where: SessionAttribute.SESSION.eq(sessionId),
      );
      for (final attr in attributes) {
        await Amplify.DataStore.delete(attr);
      }

      final reviews = await Amplify.DataStore.query(
        Review.classType,
        where: Review.SESSIONID.eq(sessionId),
      );
      for (final review in reviews) {
        await Amplify.DataStore.delete(review);
      }

      final messages = await Amplify.DataStore.query(
        ChatMessage.classType,
        where: ChatMessage.SESSIONID.eq(sessionId),
      );
      for (final msg in messages) {
        await Amplify.DataStore.delete(msg);
      }

      final bookings = await Amplify.DataStore.query(
        Booking.classType,
        where: Booking.SESSIONID.eq(sessionId),
      );
      for (final booking in bookings) {
        final items = await Amplify.DataStore.query(
          BookingItem.classType,
          where: BookingItem.BOOKING.eq(booking.id),
        );
        for (final item in items) {
          await Amplify.DataStore.delete(item);
        }
        await Amplify.DataStore.delete(booking);
      }

      await Amplify.DataStore.delete(session);

      sessions.removeWhere((s) => s.id == sessionId);
      featuredSessions.removeWhere((s) => s.id == sessionId);
      popularSessions.removeWhere((s) => s.id == sessionId);
      activeSessions.removeWhere((s) => s.id == sessionId); // ← keep in sync
      favorites.remove(sessionId);
      sessionMessages.remove(sessionId);
      _unreadCounts.remove(sessionId); // ← clean up badge count

      update();

      print('✅ Session $sessionId deleted everywhere');

      await _waitForSync();

      return true;
    } catch (e, st) {
      print('❌ Delete session failed: $e\n$st');
      return false;
    }
  }

  // ---------------- Undo Delete ----------------
  Future<void> undoDelete(TutoringSession deletedSession) async {
    if (!await _canSync()) return;

    try {
      await Amplify.DataStore.save(deletedSession);

      sessions.add(deletedSession);

      if (deletedSession.isFeatured == true) {
        featuredSessions.add(deletedSession);
      }

      if (popularSessions.length < 4) {
        popularSessions.add(deletedSession);
      }

      if (favorites.containsKey(deletedSession.id)) {
        favorites[deletedSession.id]!.value = true;
      }

      update();

      print('↩️ Session ${deletedSession.id} restored successfully');

      await _waitForSync();
    } catch (e, st) {
      print('❌ Error restoring session ${deletedSession.id}: $e\n$st');
    }
  }

  // ---------------- Wait for DataStore Sync ----------------
  Future<void> _waitForSync() async {
    final completer = Completer<void>();

    late StreamSubscription subscription;

    subscription = Amplify.Hub.listen(HubChannel.DataStore, (event) {
      if (event.eventName == 'syncQueriesReady') {
        completer.complete();
        subscription.cancel();
      }
    });

    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        subscription.cancel();
      },
    );
  }
}
