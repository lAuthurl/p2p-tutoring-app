// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'package:iconsax/iconsax.dart';
import 'package:path/path.dart' as p;
import '../../../personalization/controllers/user_controller.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../../../models/ModelProvider.dart';
import '../../checkout/screens/checkout.dart';
import '../../favourites/controllers/favorites_controller.dart';
import '../../dashboard/Home/controllers/home_controller.dart';
import '../../../../utils/constants/colors.dart';
import 'session_creation_controller.dart';

class TutoringController extends GetxController {
  static TutoringController get instance {
    if (Get.isRegistered<TutoringController>()) return Get.find();
    return Get.put(TutoringController());
  }

  Future<String?> get authUserId async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user.userId;
    } catch (_) {
      return null;
    }
  }

  // Exposed publicly so InboxScreen can identify "the other person" in a thread
  String? get currentAuthUserId => _currentAuthUserId;

  Future<String?> get currentUserTutorId async {
    const maxAttempts = 5;
    const delays = [0, 500, 1000, 2000, 3000];
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final delay = delays[attempt];
      if (delay > 0) await Future.delayed(Duration(milliseconds: delay));
      try {
        final authUser = await Amplify.Auth.getCurrentUser();
        final attrs = await Amplify.Auth.fetchUserAttributes();
        final emailAttr = attrs.firstWhere(
          (a) => a.userAttributeKey.key == 'email',
          orElse: () => attrs.first,
        );
        final email = emailAttr.value;
        if (email.isNotEmpty) {
          final byEmail = await Amplify.DataStore.query(
            Tutor.classType,
            where: Tutor.EMAIL.eq(email),
          );
          if (byEmail.isNotEmpty) return byEmail.first.id;
        }
        final byId = await Amplify.DataStore.query(
          Tutor.classType,
          where: Tutor.ID.eq(authUser.userId),
        );
        if (byId.isNotEmpty) return byId.first.id;
      } catch (e) {
        print('❌ currentUserTutorId attempt ${attempt + 1} error: $e');
      }
    }
    return null;
  }

  // ── Reactive state ────────────────────────────────────────────────────────
  final sessions = <TutoringSession>[].obs;
  final featuredSessions = <TutoringSession>[].obs;
  final popularSessions = <TutoringSession>[].obs;
  final activeSessions = <TutoringSession>[].obs;
  final selectedAttributes = <String, String>{}.obs;
  final selectedSessionImage = ''.obs;
  final isSynced = false.obs;
  final sessionMessages = <String, List<ChatMessage>>{}.obs;

  // ── Unread counts ─────────────────────────────────────────────────────────
  final unreadCounts = <String, int>{}.obs;
  String? currentOpenChatId;
  final _chatBaselineTime = <String, DateTime>{};
  final _storage = GetStorage();
  static const _kLastReadPrefix = 'chat_last_read_';
  final _observedChatIds = <String>{};

  int unreadCount(String chatId) => unreadCounts[chatId] ?? 0;
  int get totalUnread => unreadCounts.values.fold(0, (sum, n) => sum + n);

  // ── Caches ────────────────────────────────────────────────────────────────
  final _tutorCache = <String, Tutor>{};
  final _userCache = <String, User>{};
  String? _currentAuthUserId;

  // ── Background observer for new tutee threads ─────────────────────────────
  StreamSubscription? _globalMessageObserver;

  Future<String?> _getOrCacheCurrentUserId() async {
    if (_currentAuthUserId != null) return _currentAuthUserId;
    try {
      final user = await Amplify.Auth.getCurrentUser();
      _currentAuthUserId = user.userId;
      return _currentAuthUserId;
    } catch (_) {
      return null;
    }
  }

  final reportedTutors = <String, String>{}.obs;
  void reportTutor(String tutorId, String reason) =>
      reportedTutors[tutorId] = reason;
  String? getReportReason(String tutorId) => reportedTutors[tutorId];

  Worker? _userWorker;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _observeSessions();
    _listenToUserChanges();
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    _globalMessageObserver?.cancel();
    super.onClose();
  }

  void _listenToUserChanges() {
    final userController = UserController.instance;
    if (userController.currentUser.value != null) {
      _fetchSessionsAndThreads();
    }
    _userWorker?.dispose();
    _userWorker = ever<User?>(userController.currentUser, (user) {
      if (user != null) _fetchSessionsAndThreads();
    });
  }

  Future<void> _fetchSessionsAndThreads() async {
    await fetchTutorSessions();
    await Future.delayed(const Duration(milliseconds: 800));
    await fetchAllStudentThreads();
    // Load threads where the current user is the tutee
    await fetchCurrentUserThreads();
    // Start watching ALL messages so new tutee threads are caught in real time
    _startGlobalMessageObserver();
  }

  Future<bool> _canSync() async {
    try {
      await Amplify.Auth.getCurrentUser();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // GLOBAL MESSAGE OBSERVER
  //
  // Watches ALL ChatMessage records in DataStore. When a record arrives
  // whose sessionId is a composite chatId (sessionId_tuteeUserId) that
  // belongs to one of this tutor's sessions but hasn't been subscribed to
  // yet, we call observeChat() on it immediately.
  //
  // This is the key fix for the tutor inbox: fetchAllStudentThreads() only
  // catches threads that have already synced at startup. If the tutee sends
  // a message AFTER the tutor opened the app, or DataStore hasn't finished
  // syncing at load time, those threads would be silently missed.
  // The global observer catches them as they arrive from AppSync.
  // ============================================================
  void _startGlobalMessageObserver() {
    _globalMessageObserver?.cancel();

    _globalMessageObserver = Amplify.DataStore.observeQuery(
      ChatMessage.classType,
    ).listen((snapshot) {
      if (activeSessions.isEmpty) return;
      final tutorSessionIds = activeSessions.map((s) => s.id).toSet();

      for (final msg in snapshot.items) {
        final chatId = msg.sessionId;

        // Only composite chatIds are tutee threads (sessionId_userId).
        // Plain sessionIds are tutor-broadcast threads, already observed.
        if (!chatId.contains('_')) continue;

        // Only care about threads belonging to this tutor's sessions.
        if (!tutorSessionIds.any((sid) => chatId.startsWith(sid))) {
          continue;
        }

        // Already subscribed — skip.
        if (_observedChatIds.contains(chatId)) continue;

        print('🔔 _globalMessageObserver: new tutee thread detected — $chatId');
        observeChat(chatId);
      }
    }, onError: (e) => print('❌ _globalMessageObserver error: $e'));
  }

  // ============================================================
  // RELATION HYDRATION
  // ============================================================

  Future<Tutor?> _resolveTutor(TutoringSession session) async {
    final tutorId = session.tutor?.id;
    if (tutorId == null || tutorId.isEmpty) return null;
    return _resolveTutorById(tutorId);
  }

  Future<Tutor?> _resolveTutorById(String tutorId) async {
    if (_tutorCache.containsKey(tutorId)) return _tutorCache[tutorId];
    try {
      final results = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.ID.eq(tutorId),
      );
      if (results.isEmpty) return null;
      _tutorCache[tutorId] = results.first;
      return results.first;
    } catch (e) {
      print('❌ _resolveTutorById failed for $tutorId: $e');
      return null;
    }
  }

  Future<User?> _resolveUserById(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId];
    try {
      final results = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(userId),
      );
      if (results.isEmpty) return null;
      _userCache[userId] = results.first;
      return results.first;
    } catch (e) {
      print('❌ _resolveUserById failed for $userId: $e');
      return null;
    }
  }

  Future<List<TutoringSession>> _hydrateSessions(
    List<TutoringSession> raw,
  ) async {
    return Future.wait(
      raw.map((session) async {
        final tutor = await _resolveTutor(session);
        if (tutor == null) return session;
        return session.copyWith(tutor: tutor);
      }),
    );
  }

  Future<List<Review>> _hydrateReviews(
    List<Review> raw, {
    String? sourceJson,
  }) async {
    return Future.wait(
      raw.map((review) async {
        Review hydrated = review;

        String? userId = review.user?.id;
        if (userId == null || userId.isEmpty) {
          userId = _reviewUserIdMap[review.id];
        }
        if ((userId == null || userId.isEmpty) && sourceJson != null) {
          userId = _extractFieldForId(sourceJson, review.id, 'userId');
        }
        if (userId != null && userId.isNotEmpty) {
          final user = await _resolveUserById(userId);
          if (user != null) hydrated = hydrated.copyWith(user: user);
        }

        String? tutorId = review.tutor?.id;
        if (tutorId == null || tutorId.isEmpty) {
          tutorId = _reviewTutorIdMap[review.id];
        }
        if ((tutorId == null || tutorId.isEmpty) && sourceJson != null) {
          tutorId = _extractFieldForId(sourceJson, review.id, 'tutorId');
        }
        if (tutorId != null && tutorId.isNotEmpty) {
          final tutor = await _resolveTutorById(tutorId);
          if (tutor != null) hydrated = hydrated.copyWith(tutor: tutor);
        }

        return hydrated;
      }),
    );
  }

  // ============================================================
  // JSON PARSING HELPERS
  // ============================================================

  String? _extractFieldForId(
    String jsonStr,
    String targetId,
    String fieldName,
  ) {
    try {
      final idMarker = RegExp('"id"\\s*:\\s*"${RegExp.escape(targetId)}"');
      final idMatch = idMarker.firstMatch(jsonStr);
      if (idMatch == null) return null;
      final start = jsonStr.lastIndexOf('{', idMatch.start);
      final end = jsonStr.indexOf('}', idMatch.end);
      if (start == -1 || end == -1) return null;
      final block = jsonStr.substring(start, end + 1);
      return RegExp(
        '"' + RegExp.escape(fieldName) + r'"\s*:\s*"([^"]+)"',
      ).firstMatch(block)?.group(1);
    } catch (e) {
      print('❌ _extractFieldForId($targetId, $fieldName) error: $e');
      return null;
    }
  }

  List<String> _parseIds(String jsonStr) {
    final ids = <String>[];
    for (final match in RegExp(r'"id"\s*:\s*"([^"]+)"').allMatches(jsonStr)) {
      ids.add(match.group(1)!);
    }
    return ids;
  }

  void _parseReviewFkIds(String jsonStr) {
    final allIds = RegExp(r'"id"\s*:\s*"([^"]+)"').allMatches(jsonStr).toList();
    final allUserIds =
        RegExp(r'"userId"\s*:\s*"([^"]+)"').allMatches(jsonStr).toList();
    final allTutorIds =
        RegExp(r'"tutorId"\s*:\s*"([^"]+)"').allMatches(jsonStr).toList();

    for (int i = 0; i < allIds.length; i++) {
      final idMatch = allIds[i];
      final reviewId = idMatch.group(1)!;
      final nextIdPos =
          i + 1 < allIds.length ? allIds[i + 1].start : jsonStr.length;

      final u = allUserIds.where(
        (m) => m.start > idMatch.start && m.start < nextIdPos,
      );
      if (u.isNotEmpty) _reviewUserIdMap[reviewId] = u.first.group(1)!;

      final t = allTutorIds.where(
        (m) => m.start > idMatch.start && m.start < nextIdPos,
      );
      if (t.isNotEmpty) _reviewTutorIdMap[reviewId] = t.first.group(1)!;
    }
  }

  Review? _buildMinimalReviewById(String id, String jsonStr, String sessionId) {
    try {
      final idMarker = RegExp('"id"\\s*:\\s*"${RegExp.escape(id)}"');
      final idMatch = idMarker.firstMatch(jsonStr);
      if (idMatch == null) return null;
      final start = jsonStr.lastIndexOf('{', idMatch.start);
      final end = jsonStr.indexOf('}', idMatch.end);
      if (start == -1 || end == -1) return null;
      final block = jsonStr.substring(start, end + 1);
      final rating =
          double.tryParse(
            RegExp(r'"rating"\s*:\s*([\d.]+)').firstMatch(block)?.group(1) ??
                '0',
          ) ??
          0;
      final comment = RegExp(
        r'"comment"\s*:\s*"([^"]*)"',
      ).firstMatch(block)?.group(1);
      final createdAt = RegExp(
        r'"createdAt"\s*:\s*"([^"]+)"',
      ).firstMatch(block)?.group(1);
      return Review(
        id: id,
        sessionId: sessionId,
        rating: rating,
        comment: comment,
        createdAt:
            createdAt != null
                ? TemporalDateTime.fromString(createdAt)
                : TemporalDateTime.now(),
      );
    } catch (e) {
      print('❌ _buildMinimalReviewById error for $id: $e');
      return null;
    }
  }

  String? _parseSessionIdForReview(String reviewId, String jsonStr) {
    return _extractFieldForId(jsonStr, reviewId, 'sessionId');
  }

  List<TutoringSession> _buildMinimalSessions(String jsonStr, Tutor tutor) {
    final sessions = <TutoringSession>[];
    try {
      final ids =
          RegExp(
            r'"id"\s*:\s*"([^"]+)"',
          ).allMatches(jsonStr).map((m) => m.group(1)!).toList();
      final titles =
          RegExp(
            r'"title"\s*:\s*"([^"]+)"',
          ).allMatches(jsonStr).map((m) => m.group(1)!).toList();
      final prices =
          RegExp(r'"pricePerSession"\s*:\s*([\d.]+)')
              .allMatches(jsonStr)
              .map((m) => double.tryParse(m.group(1)!) ?? 0.0)
              .toList();
      final thumbs =
          RegExp(
            r'"thumbnail"\s*:\s*"([^"]+)"',
          ).allMatches(jsonStr).map((m) => m.group(1)!).toList();
      final descs =
          RegExp(
            r'"description"\s*:\s*"([^"]+)"',
          ).allMatches(jsonStr).map((m) => m.group(1)!).toList();
      for (int i = 0; i < ids.length; i++) {
        sessions.add(
          TutoringSession(
            id: ids[i],
            title: i < titles.length ? titles[i] : 'Session',
            description: i < descs.length ? descs[i] : null,
            pricePerSession: i < prices.length ? prices[i] : 0,
            thumbnail: i < thumbs.length ? thumbs[i] : null,
            tutor: tutor,
          ),
        );
      }
    } catch (e) {
      print('❌ _buildMinimalSessions error: $e');
    }
    return sessions;
  }

  // ============================================================
  // SESSIONS
  // ============================================================

  void _observeSessions() async {
    if (!await _canSync()) return;
    try {
      Amplify.DataStore.observeQuery(TutoringSession.classType).listen((
        snapshot,
      ) async {
        final raw = snapshot.items.whereType<TutoringSession>().toList();
        if (raw.isNotEmpty) {
          final hydrated = await _hydrateSessions(raw);
          _mergeSessions(hydrated);
        }
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
      final raw = await Amplify.DataStore.query(TutoringSession.classType);
      if (raw.isEmpty) return;
      final hydrated = await _hydrateSessions(raw);
      _mergeSessions(hydrated);
    } catch (e) {
      print('❌ Error fetching sessions: $e');
    }
  }

  // ── FIXED: fetchAllStudentThreads ────────────────────────────────────────
  //
  // Root cause of the empty tutor inbox:
  //   1. Tutee messages are saved with sessionId = "{sessionId}_{tuteeUserId}".
  //   2. The old code called observeChat(session.id) which subscribes to the
  //      plain sessionId — it never matched the composite chatId.
  //   3. Even after fixing that, the old code never seeded sessionMessages,
  //      so the Obx in InboxScreen saw an empty map even when messages existed.
  //
  // Fix: query ALL ChatMessage records from DataStore, group by chatId,
  // seed sessionMessages immediately so the inbox renders without waiting
  // for the observeQuery subscription tick, then start observeChat on each.
  Future<void> fetchAllStudentThreads() async {
    if (!await _canSync()) return;
    if (activeSessions.isEmpty) return;

    try {
      final allMessages = await Amplify.DataStore.query(ChatMessage.classType);
      final tutorSessionIds = activeSessions.map((s) => s.id).toSet();

      // Group all matching messages by chatId
      final grouped = <String, List<ChatMessage>>{};
      for (final msg in allMessages) {
        final chatId = msg.sessionId;
        if (!tutorSessionIds.any((sid) => chatId.startsWith(sid))) continue;
        grouped.putIfAbsent(chatId, () => []).add(msg);
      }

      print(
        '💬 fetchAllStudentThreads: ${grouped.length} threads across '
        '${tutorSessionIds.length} tutor sessions',
      );

      for (final entry in grouped.entries) {
        final chatId = entry.key;
        final msgs =
            entry.value..sort(
              (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now())
                  .compareTo(b.createdAt?.getDateTimeInUtc() ?? DateTime.now()),
            );

        // Seed the reactive map so the inbox renders immediately without
        // waiting for the observeQuery subscription to fire its first event.
        if (!sessionMessages.containsKey(chatId) ||
            (sessionMessages[chatId]?.isEmpty ?? true)) {
          sessionMessages[chatId] = msgs;
        }

        observeChat(chatId);
      }

      sessionMessages.refresh();
    } catch (e) {
      print('❌ fetchAllStudentThreads error: $e');
    }
  }

  // ── NEW: fetchCurrentUserThreads ─────────────────────────────────────────
  // Loads threads where the current user is the TUTEE. Seeds sessionMessages
  // and starts observeChat so the tutee's inbox also works correctly.
  // A tutee's thread has chatId = "{sessionId}_{tuteeUserId}" so we match
  // on senderId == myId OR chatId ending with "_myId".
  Future<void> fetchCurrentUserThreads() async {
    if (!await _canSync()) return;

    try {
      final myId = await _getOrCacheCurrentUserId();
      if (myId == null) return;

      final allMessages = await Amplify.DataStore.query(ChatMessage.classType);

      final grouped = <String, List<ChatMessage>>{};
      for (final msg in allMessages) {
        if (msg.senderId != myId && !msg.sessionId.endsWith('_$myId')) {
          continue;
        }
        grouped.putIfAbsent(msg.sessionId, () => []).add(msg);
      }

      print(
        '💬 fetchCurrentUserThreads: ${grouped.length} threads for user $myId',
      );

      for (final entry in grouped.entries) {
        final chatId = entry.key;
        final msgs =
            entry.value..sort(
              (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now())
                  .compareTo(b.createdAt?.getDateTimeInUtc() ?? DateTime.now()),
            );

        if (!sessionMessages.containsKey(chatId) ||
            (sessionMessages[chatId]?.isEmpty ?? true)) {
          sessionMessages[chatId] = msgs;
        }

        observeChat(chatId);
      }

      sessionMessages.refresh();
    } catch (e) {
      print('❌ fetchCurrentUserThreads error: $e');
    }
  }

  Future<void> fetchTutorSessions() async {
    if (!await _canSync()) return;
    try {
      final tutorId = await currentUserTutorId;
      if (tutorId == null) {
        print('ℹ️ fetchTutorSessions: no tutor record — skip');
        return;
      }

      const queryDoc = """
        query ListSessionsByTutor(\$tutorId: ID!, \$limit: Int) {
          listTutoringSessions(filter: {tutorId: {eq: \$tutorId}}, limit: \$limit) {
            items {
              id title description pricePerSession thumbnail
              tutorId subjectId isFeatured hasPaid createdAt updatedAt
            }
          }
        }
      """;

      final response =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: queryDoc,
                  variables: {'tutorId': tutorId, 'limit': 100},
                ),
              )
              .response;

      if (response.errors.isNotEmpty || response.data == null) {
        await _fetchTutorSessionsFallback(tutorId);
        return;
      }

      final resolvedTutor = await _resolveTutorById(tutorId);
      final sessionIds = _parseIds(response.data!);
      if (sessionIds.isEmpty) {
        activeSessions.clear();
        return;
      }

      final hydrated = <TutoringSession>[];
      for (final id in sessionIds) {
        final results = await Amplify.DataStore.query(
          TutoringSession.classType,
          where: TutoringSession.ID.eq(id),
        );
        if (results.isNotEmpty) {
          hydrated.add(
            resolvedTutor != null
                ? results.first.copyWith(tutor: resolvedTutor)
                : results.first,
          );
        }
      }

      if (hydrated.isEmpty && resolvedTutor != null) {
        hydrated.addAll(_buildMinimalSessions(response.data!, resolvedTutor));
      }

      activeSessions.assignAll(hydrated);

      // Immediately scan for existing student threads now that we have
      // the tutor session IDs loaded.
      await fetchAllStudentThreads();
      _startGlobalMessageObserver();

      print('✅ fetchTutorSessions: loaded ${activeSessions.length} sessions');
    } catch (e) {
      print('❌ fetchTutorSessions error: $e');
    }
  }

  Future<void> _fetchTutorSessionsFallback(String tutorId) async {
    try {
      final tutorSessions = await Amplify.DataStore.query(
        TutoringSession.classType,
        where: TutoringSession.TUTOR.eq(tutorId),
      );
      final resolvedTutor = await _resolveTutorById(tutorId);
      activeSessions.assignAll(
        tutorSessions.map(
          (s) => resolvedTutor != null ? s.copyWith(tutor: resolvedTutor) : s,
        ),
      );
      await fetchAllStudentThreads();
      _startGlobalMessageObserver();
    } catch (e) {
      print('❌ _fetchTutorSessionsFallback error: $e');
      activeSessions.clear();
    }
  }

  // ── Session utilities ─────────────────────────────────────────────────────

  double _computeAdjustedPrice(
    TutoringSession session,
    Map<String, String>? attrs,
  ) {
    double price = session.pricePerSession ?? 0.0;
    final duration = attrs?['Duration']?.toLowerCase() ?? '';
    if (duration.contains('2hr') || duration.contains('2h')) price *= 2;
    final mode = attrs?['Mode']?.toLowerCase() ?? '';
    if (mode.contains('offline') ||
        mode.contains('in-person') ||
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

    final context = Get.context;
    if (context != null) {
      await showModalBottomSheet(
        // ignore: use_build_context_synchronously
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder:
            (_) =>
                _BookingConfirmationSheet(session: session, price: finalPrice),
      );
    } else {
      Get.snackbar(
        '✅ Added to Booking',
        '${session.title} has been added to your cart',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  bool isFavourite(String sessionId) =>
      FavoritesController.instance.isFavourite(sessionId);

  Future<void> toggleFavoriteSession(String sessionId) =>
      FavoritesController.instance.toggleFavorite(sessionId);

  List<TutoringSession> favoriteSessions() {
    final ids = FavoritesController.instance.favoriteIds;
    final all = <String, TutoringSession>{};
    for (final s in [...sessions, ...activeSessions]) {
      all[s.id] = s;
    }
    try {
      if (Get.isRegistered<HomeController>()) {
        for (final s in HomeController.instance.allSessions) {
          all.putIfAbsent(s.id, () => s);
        }
      }
    } catch (_) {}
    return all.values.where((s) => ids.contains(s.id)).toList();
  }

  List<String> getAllSessionImages(TutoringSession session) {
    final images = <String>[];
    if (session.thumbnail?.isNotEmpty ?? false) images.add(session.thumbnail!);
    if (session.images?.isNotEmpty ?? false) images.addAll(session.images!);
    return images;
  }

  List<Map<String, String>> generateCombinationsForUI(TutoringSession session) {
    List<Map<String, String>> combos = [{}];
    session.sessionAttributes?.forEach((attr) {
      final values = attr.values ?? [];
      final newList = <Map<String, String>>[];
      for (final combo in combos) {
        for (final val in values) {
          newList.add({...combo, attr.name: val});
        }
      }
      combos = newList;
    });
    return combos;
  }

  int calculateSalePercentage(double originalPrice, double? discountedPrice) {
    if (discountedPrice == null || discountedPrice >= originalPrice) return 0;
    return ((1 - (discountedPrice / originalPrice)) * 100).round();
  }

  double computeSelectedAttributesPrice() {
    if (sessions.isEmpty) return 0.0;
    final session = sessions.firstWhere(
      (s) => s.id == selectedSessionImage.value,
      orElse: () => sessions.first,
    );
    return _computeAdjustedPrice(session, selectedAttributes);
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  final _reviewUserIdMap = <String, String>{};
  final _reviewTutorIdMap = <String, String>{};

  Future<Review> addReview({
    required TutoringSession session,
    required double rating,
    required String comment,
  }) async {
    if (!await _canSync()) throw Exception('User not signed in');
    final authUser = await Amplify.Auth.getCurrentUser();
    final userId = authUser.userId;
    final tutorId = session.tutor?.id ?? '';
    if (tutorId.isEmpty) throw Exception('Session has no tutor assigned');

    final userList = await Amplify.DataStore.query(
      User.classType,
      where: User.ID.eq(userId),
    );
    if (userList.isEmpty) throw Exception('Current user not found');
    final currentUser = userList.first;
    _userCache[currentUser.id] = currentUser;

    final tutorList = await Amplify.DataStore.query(
      Tutor.classType,
      where: Tutor.ID.eq(tutorId),
    );
    if (tutorList.isEmpty) throw Exception('Tutor not found');
    final currentTutor = tutorList.first;
    _tutorCache[currentTutor.id] = currentTutor;

    final reviewId = amplify_core.UUID.getUUID();
    final now = TemporalDateTime.now();

    const mutationDoc = """
      mutation CreateReview(
        \$id: ID!, \$sessionId: ID!, \$tutorId: ID!, \$userId: ID!,
        \$rating: Float!, \$comment: String, \$createdAt: AWSDateTime!
      ) {
        createReview(input: {
          id: \$id, sessionId: \$sessionId, tutorId: \$tutorId,
          userId: \$userId, rating: \$rating, comment: \$comment,
          createdAt: \$createdAt
        }) {
          id sessionId tutorId userId rating comment createdAt
        }
      }
    """;

    final response =
        await Amplify.API
            .mutate(
              request: GraphQLRequest<String>(
                document: mutationDoc,
                variables: {
                  'id': reviewId,
                  'sessionId': session.id,
                  'tutorId': tutorId,
                  'userId': userId,
                  'rating': rating,
                  'comment': comment,
                  'createdAt': now.format(),
                },
              ),
            )
            .response;

    if (response.errors.isNotEmpty) {
      throw Exception(
        'GraphQL mutation failed: ${response.errors.first.message}',
      );
    }

    print('✅ Review saved to AppSync: $reviewId');
    _reviewUserIdMap[reviewId] = userId;
    _reviewTutorIdMap[reviewId] = tutorId;

    return Review(
      id: reviewId,
      user: currentUser,
      sessionId: session.id,
      tutor: currentTutor,
      rating: rating,
      comment: comment,
      createdAt: now,
    );
  }

  Future<List<Review>> fetchReviews(String sessionId) async {
    if (!await _canSync()) return [];
    try {
      const gsiQuery = """
        query ListReviewsBySession(\$sessionId: ID!, \$limit: Int) {
          listReviewsBySession(sessionId: \$sessionId, limit: \$limit) {
            items { id sessionId tutorId userId rating comment createdAt }
          }
        }
      """;
      const filterQuery = """
        query ListReviewsBySessionFilter(\$sessionId: ID!, \$limit: Int) {
          listReviews(filter: {sessionId: {eq: \$sessionId}}, limit: \$limit) {
            items { id sessionId tutorId userId rating comment createdAt }
          }
        }
      """;

      String? sourceJson;
      List<String> ids = [];

      final gsiResponse =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: gsiQuery,
                  variables: {'sessionId': sessionId, 'limit': 200},
                ),
              )
              .response;

      if (gsiResponse.errors.isEmpty && gsiResponse.data != null) {
        sourceJson = gsiResponse.data!;
        ids = _parseIds(sourceJson);
      } else {
        final filterResponse =
            await Amplify.API
                .query(
                  request: GraphQLRequest<String>(
                    document: filterQuery,
                    variables: {'sessionId': sessionId, 'limit': 200},
                  ),
                )
                .response;
        if (filterResponse.errors.isEmpty && filterResponse.data != null) {
          sourceJson = filterResponse.data!;
          ids = _parseIds(sourceJson);
        }
      }

      List<Review> raw = [];
      if (sourceJson != null && ids.isNotEmpty) {
        _parseReviewFkIds(sourceJson);
        for (final id in ids) {
          final results = await Amplify.DataStore.query(
            Review.classType,
            where: Review.ID.eq(id),
          );
          if (results.isNotEmpty) {
            raw.add(results.first);
          } else {
            final minimal = _buildMinimalReviewById(id, sourceJson, sessionId);
            if (minimal != null) raw.add(minimal);
          }
        }
      } else {
        final local = await Amplify.DataStore.query(
          Review.classType,
          where: Review.SESSIONID.eq(sessionId),
        );
        raw = local.where((r) => r.createdAt != null).toList();
      }

      return await _hydrateReviews(raw, sourceJson: sourceJson);
    } catch (e) {
      print('❌ fetchReviews error: $e');
      return [];
    }
  }

  Future<List<Review>> fetchReviewsByTutor(String tutorId) async {
    if (!await _canSync()) return [];
    try {
      const gsiQuery = """
        query ListReviewsByTutor(\$tutorId: ID!, \$limit: Int) {
          listReviewsByTutor(tutorId: \$tutorId, limit: \$limit) {
            items { id sessionId tutorId userId rating comment createdAt }
          }
        }
      """;
      const filterQuery = """
        query ListReviewsByTutorFilter(\$tutorId: ID!, \$limit: Int) {
          listReviews(filter: {tutorId: {eq: \$tutorId}}, limit: \$limit) {
            items { id sessionId tutorId userId rating comment createdAt }
          }
        }
      """;

      String? sourceJson;
      List<String> ids = [];

      final gsiResponse =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: gsiQuery,
                  variables: {'tutorId': tutorId, 'limit': 200},
                ),
              )
              .response;

      if (gsiResponse.errors.isEmpty && gsiResponse.data != null) {
        sourceJson = gsiResponse.data!;
        ids = _parseIds(sourceJson);
      } else {
        final filterResponse =
            await Amplify.API
                .query(
                  request: GraphQLRequest<String>(
                    document: filterQuery,
                    variables: {'tutorId': tutorId, 'limit': 200},
                  ),
                )
                .response;
        if (filterResponse.errors.isEmpty && filterResponse.data != null) {
          sourceJson = filterResponse.data!;
          ids = _parseIds(sourceJson);
        }
      }

      List<Review> raw = [];
      if (sourceJson != null && ids.isNotEmpty) {
        _parseReviewFkIds(sourceJson);
        for (final id in ids) {
          final results = await Amplify.DataStore.query(
            Review.classType,
            where: Review.ID.eq(id),
          );
          if (results.isNotEmpty) {
            raw.add(results.first);
          } else {
            final sid = _parseSessionIdForReview(id, sourceJson);
            final minimal = _buildMinimalReviewById(id, sourceJson, sid ?? '');
            if (minimal != null) raw.add(minimal);
          }
        }
      } else {
        final all = await Amplify.DataStore.query(Review.classType);
        raw = all.where((r) => r.tutor?.id == tutorId).toList();
      }

      return await _hydrateReviews(raw, sourceJson: sourceJson);
    } catch (e) {
      print('❌ fetchReviewsByTutor error: $e');
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

  // ============================================================
  // CHAT — SEND
  // ============================================================

  List<String> get chatSessions => sessionMessages.keys.toList();

  Future<String> _resolveSenderName(String userId) async {
    if (_userCache.containsKey(userId)) {
      final cached = _userCache[userId]!;
      if (cached.username.isNotEmpty) return cached.username;
    }
    try {
      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(userId),
      );
      if (users.isNotEmpty && users.first.username.isNotEmpty) {
        _userCache[userId] = users.first;
        return users.first.username;
      }
    } catch (_) {}

    if (_tutorCache.containsKey(userId)) {
      final cached = _tutorCache[userId]!;
      if (cached.name.isNotEmpty) return cached.name;
    }
    try {
      final tutors = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.ID.eq(userId),
      );
      if (tutors.isNotEmpty && tutors.first.name.isNotEmpty) {
        _tutorCache[userId] = tutors.first;
        return tutors.first.name;
      }
    } catch (_) {}

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

  // DataStore.save() is used for all message writes because the ChatMessage
  // @auth rule requires OWNER for CREATE. DataStore automatically attaches
  // the Cognito owner claim before syncing to AppSync, so the write is
  // always accepted. The DataStore observeQuery subscription on the
  // recipient's device fires when the record syncs — delivering the message
  // in real time without any polling.
  Future<void> sendMessage(String sessionId, String text) async {
    if (!await _canSync()) return;

    final authUser = await Amplify.Auth.getCurrentUser();
    final userId = authUser.userId;
    final senderName = await _resolveSenderName(userId);

    final message = ChatMessage(
      sessionId: sessionId,
      senderId: userId,
      senderName: senderName,
      text: text,
      isVoice: false,
      createdAt: TemporalDateTime.now(),
    );

    // Optimistic local insert so the sender sees the message immediately
    _onNewMessage(message);

    try {
      await Amplify.DataStore.save(message);
      print('✅ sendMessage: saved — id=${message.id}');
      // Ensure this chatId is observed so new replies are delivered
      observeChat(sessionId);
    } catch (e) {
      print('❌ sendMessage error: $e');
      _removeOptimisticMessage(sessionId, message.id);
      Get.snackbar(
        'Send Failed',
        'Message could not be delivered. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> sendVoiceMessage(String sessionId, File audioFile) async {
    if (!await _canSync()) return;

    final authUser = await Amplify.Auth.getCurrentUser();
    final userId = authUser.userId;
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

      final message = ChatMessage(
        sessionId: sessionId,
        senderId: userId,
        senderName: senderName,
        text: null,
        audioUrl: urlResult.url.toString(),
        isVoice: true,
        createdAt: TemporalDateTime.now(),
      );

      _onNewMessage(message);
      await Amplify.DataStore.save(message);
      print('✅ sendVoiceMessage: saved — id=${message.id}');
      observeChat(sessionId);
    } on StorageException catch (e) {
      print('❌ S3 Upload failed: ${e.message}');
      Get.snackbar(
        'Upload Failed',
        'Could not upload voice message. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('❌ sendVoiceMessage error: $e');
      Get.snackbar(
        'Voice Message Error',
        'Voice messages are unavailable. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Public wrapper so CheckoutController can inject system messages into
  // the reactive list without accessing private _onNewMessage directly.
  void injectLocalMessage(ChatMessage message) {
    _onNewMessage(message);
    // Ensure this chatId is observed so the recipient receives replies
    observeChat(message.sessionId);
  }

  void _removeOptimisticMessage(String sessionId, String messageId) {
    final current = List<ChatMessage>.from(sessionMessages[sessionId] ?? []);
    current.removeWhere((m) => m.id == messageId);
    sessionMessages[sessionId] = current;
    sessionMessages.refresh();
  }

  // ============================================================
  // CHAT — FETCH (DataStore is source of truth)
  // ============================================================

  Future<List<ChatMessage>> fetchMessagesFromAppSync(String chatId) async {
    if (!await _canSync()) return sessionMessages[chatId] ?? [];

    try {
      // Ensure subscribed before loading
      observeChat(chatId);

      final local = await Amplify.DataStore.query(
        ChatMessage.classType,
        where: ChatMessage.SESSIONID.eq(chatId),
      );

      local.sort(
        (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now()).compareTo(
          b.createdAt?.getDateTimeInUtc() ?? DateTime.now(),
        ),
      );

      print(
        '📦 fetchMessagesFromAppSync: ${local.length} messages '
        'from DataStore for $chatId',
      );

      // Merge DataStore records with any in-flight optimistic messages
      final existing = sessionMessages[chatId] ?? [];
      final localIds = local.map((m) => m.id).toSet();

      final seen = <String>{};
      final merged = <ChatMessage>[];

      for (final m in local) {
        if (seen.add(m.id)) merged.add(m);
      }
      // Keep optimistic messages not yet persisted to DataStore
      for (final m in existing) {
        if (!localIds.contains(m.id) && seen.add(m.id)) merged.add(m);
      }

      merged.sort(
        (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now()).compareTo(
          b.createdAt?.getDateTimeInUtc() ?? DateTime.now(),
        ),
      );

      sessionMessages[chatId] = merged;
      sessionMessages.refresh();

      return merged;
    } catch (e) {
      print('❌ fetchMessagesFromAppSync error: $e');
      return sessionMessages[chatId] ?? [];
    }
  }

  // ============================================================
  // CHAT — OBSERVE
  // ============================================================

  void observeChat(String chatId) {
    if (_observedChatIds.contains(chatId)) return;
    _observedChatIds.add(chatId);

    if (!_chatBaselineTime.containsKey(chatId)) {
      final storedMs = _storage.read<int>('$_kLastReadPrefix$chatId');
      if (storedMs != null) {
        _chatBaselineTime[chatId] = DateTime.fromMillisecondsSinceEpoch(
          storedMs,
          isUtc: true,
        );
      }
    }

    Amplify.DataStore.observeQuery(
      ChatMessage.classType,
      where: ChatMessage.SESSIONID.eq(chatId),
    ).listen((snapshot) async {
      final msgs = snapshot.items.whereType<ChatMessage>().toList();

      msgs.sort(
        (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now()).compareTo(
          b.createdAt?.getDateTimeInUtc() ?? DateTime.now(),
        ),
      );

      // First snapshot — set baseline time so we don't count old messages
      // as unread.
      if (!_chatBaselineTime.containsKey(chatId)) {
        final newestTime =
            msgs.isNotEmpty
                ? msgs.last.createdAt?.getDateTimeInUtc() ?? DateTime.now()
                : DateTime.now();
        _chatBaselineTime[chatId] = newestTime;
        _storage.write(
          '$_kLastReadPrefix$chatId',
          newestTime.millisecondsSinceEpoch,
        );
        sessionMessages[chatId] = msgs;
        sessionMessages.refresh();
        return;
      }

      final baseline = _chatBaselineTime[chatId]!;
      final existing = sessionMessages[chatId] ?? [];
      final existingIds = existing.map((m) => m.id).toSet();
      final myId = await _getOrCacheCurrentUserId();

      int newCount = 0;
      for (final msg in msgs) {
        if (existingIds.contains(msg.id)) continue;
        final msgTime = msg.createdAt?.getDateTimeInUtc();
        if (msgTime == null || !msgTime.isAfter(baseline)) continue;
        if (currentOpenChatId == chatId) continue;
        if (myId != null && msg.senderId == myId) continue;
        newCount++;
      }

      if (newCount > 0) {
        unreadCounts[chatId] = (unreadCounts[chatId] ?? 0) + newCount;
      }

      sessionMessages[chatId] = msgs;
      sessionMessages.refresh();
    }, onError: (e) => print('❌ observeChat($chatId) error: $e'));
  }

  void _onNewMessage(ChatMessage msg) {
    final chatId = msg.sessionId;
    if (chatId == null) return;

    final current = List<ChatMessage>.from(sessionMessages[chatId] ?? []);
    if (!current.any((m) => m.id == msg.id)) {
      current.add(msg);
      current.sort(
        (a, b) => (a.createdAt?.getDateTimeInUtc() ?? DateTime.now()).compareTo(
          b.createdAt?.getDateTimeInUtc() ?? DateTime.now(),
        ),
      );
      sessionMessages[chatId] = current;
    }

    final isOwnMessage =
        _currentAuthUserId != null && msg.senderId == _currentAuthUserId;

    if (currentOpenChatId != chatId && !isOwnMessage) {
      unreadCounts[chatId] = (unreadCounts[chatId] ?? 0) + 1;
    }

    sessionMessages.refresh();
  }

  void markSessionRead(String chatId) {
    unreadCounts[chatId] = 0;
    currentOpenChatId = chatId;
    final now = DateTime.now().toUtc();
    _chatBaselineTime[chatId] = now;
    _storage.write('$_kLastReadPrefix$chatId', now.millisecondsSinceEpoch);
    sessionMessages.refresh();
  }

  void clearCurrentOpenSession() => currentOpenChatId = null;

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  Future<void> deleteMessage(String chatId, ChatMessage message) async {
    if (!await _canSync()) return;

    // Optimistic removal from UI
    final current = List<ChatMessage>.from(sessionMessages[chatId] ?? []);
    current.removeWhere((m) => m.id == message.id);
    sessionMessages[chatId] = current;
    sessionMessages.refresh();

    try {
      // DataStore.delete handles owner auth automatically
      final local = await Amplify.DataStore.query(
        ChatMessage.classType,
        where: ChatMessage.ID.eq(message.id),
      );
      if (local.isNotEmpty) {
        await Amplify.DataStore.delete(local.first);
        print('✅ deleteMessage: deleted via DataStore — id=${message.id}');
        return;
      }

      // Fallback: direct AppSync delete for messages not in local DataStore
      const getDoc = r"""
        query GetChatMessage($id: ID!) {
          getChatMessage(id: $id) { id _version _deleted }
        }
      """;

      final getResponse =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: getDoc,
                  variables: {'id': message.id},
                ),
              )
              .response;

      int version = 1;
      if (getResponse.errors.isEmpty && getResponse.data != null) {
        final decoded = jsonDecode(getResponse.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final obj = root['getChatMessage'] as Map<String, dynamic>?;
        if (obj == null || obj['_deleted'] == true) return;
        final v = obj['_version'];
        if (v != null) version = (v as num).toInt();
      }

      const mutationDoc = r"""
        mutation DeleteChatMessage($input: DeleteChatMessageInput!) {
          deleteChatMessage(input: $input) { id _version }
        }
      """;

      await Amplify.API
          .mutate(
            request: GraphQLRequest<String>(
              document: mutationDoc,
              variables: {
                'input': {'id': message.id, '_version': version},
              },
            ),
          )
          .response;
    } catch (e) {
      print('❌ deleteMessage: $e');
    }
  }

  // ============================================================
  // DELETE SESSION
  // ============================================================

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
      activeSessions.removeWhere((s) => s.id == sessionId);

      final chatKeysToRemove =
          sessionMessages.keys.where((k) => k.startsWith(sessionId)).toList();
      for (final k in chatKeysToRemove) {
        sessionMessages.remove(k);
        unreadCounts.remove(k);
        _chatBaselineTime.remove(k);
        _observedChatIds.remove(k);
      }

      if (FavoritesController.instance.isFavourite(sessionId)) {
        await FavoritesController.instance.toggleFavorite(sessionId);
      }

      update();
      print('✅ Session $sessionId deleted');
      await _waitForSync();
      return true;
    } catch (e, st) {
      print('❌ Delete session failed: $e\n$st');
      return false;
    }
  }

  Future<void> undoDelete(TutoringSession deletedSession) async {
    if (!await _canSync()) return;
    try {
      await Amplify.DataStore.save(deletedSession);
      sessions.add(deletedSession);
      if (deletedSession.isFeatured == true) {
        featuredSessions.add(deletedSession);
      }
      if (popularSessions.length < 4) popularSessions.add(deletedSession);
      update();
      await _waitForSync();
    } catch (e, st) {
      print('❌ Error restoring session ${deletedSession.id}: $e\n$st');
    }
  }

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
      onTimeout: () => subscription.cancel(),
    );
  }

  void warmTutorCache(Tutor tutor) => _tutorCache[tutor.id] = tutor;
  void warmUserCache(User user) => _userCache[user.id] = user;

  // ============================================================
  // CLEAR ON LOGOUT
  // ============================================================

  void clearSessionState() {
    // Cancel global observer first to prevent it firing during cleanup
    _globalMessageObserver?.cancel();
    _globalMessageObserver = null;

    sessions.clear();
    featuredSessions.clear();
    popularSessions.clear();
    activeSessions.clear();
    sessionMessages.clear();
    unreadCounts.clear();
    _chatBaselineTime.clear();
    _observedChatIds.clear();
    _tutorCache.clear();
    _userCache.clear();
    _currentAuthUserId = null;
    _reviewUserIdMap.clear();
    _reviewTutorIdMap.clear();
    currentOpenChatId = null;
    print('✅ TutoringController: state cleared on logout');
  }

  void clearAuthCache() {
    _currentAuthUserId = null;
    unreadCounts.clear();
    _chatBaselineTime.clear();
    _observedChatIds.clear();
  }
}

// ============================================================
// Booking confirmation bottom sheet
// ============================================================
class _BookingConfirmationSheet extends StatelessWidget {
  const _BookingConfirmationSheet({required this.session, required this.price});

  final TutoringSession session;
  final double price;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF00C48C),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Added to Booking!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            session.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '₦${price.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: TColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.back();
                Get.to(() => const CheckoutScreen());
              },
              icon: const Icon(Iconsax.security_safe, size: 18),
              label: const Text(
                'Go to Checkout',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0BA4DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Keep Browsing',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
