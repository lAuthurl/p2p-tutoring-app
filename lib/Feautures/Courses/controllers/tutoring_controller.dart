// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'dart:async';
import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'package:path/path.dart' as p;
import '../../../personalization/controllers/user_controller.dart';
import '../../Booking/controllers/booking_controller.dart';
import '../../../../models/ModelProvider.dart';
import '../../dashboard/Home/controllers/favorites_controller.dart';
import '../../dashboard/Home/controllers/home_controller.dart';
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

  // ---------------- Reactive State ----------------
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

  // ---------------- Caches ----------------
  final _tutorCache = <String, Tutor>{};
  final _userCache = <String, User>{};
  String? _currentAuthUserId;

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

  // ── Persistent user watcher ───────────────────────────────────────────────
  // Kept alive for the controller's lifetime so it fires on EVERY login,
  // not just the first. The old one-shot worker disposed itself after the
  // first user load, meaning logout+login never re-triggered session/thread
  // fetching — leaving unreadCounts empty until the inbox was opened manually.
  Worker? _userWorker;

  // ---------------- Lifecycle ----------------
  @override
  void onInit() {
    super.onInit();
    _observeSessions();
    _listenToUserChanges();
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    super.onClose();
  }

  void _listenToUserChanges() {
    final userController = UserController.instance;

    // If user is already loaded on init (app restart with active session),
    // kick off immediately without waiting for the ever() callback.
    if (userController.currentUser.value != null) {
      _fetchSessionsAndThreads();
    }

    // ✅ FIX: persistent ever() worker — never disposed on user change.
    // The old code used a one-shot worker that called worker.dispose()
    // inside its own callback, so after the first login it was gone.
    // Logout+login never triggered _fetchSessionsAndThreads() again,
    // so activeSessions stayed empty and unreadCounts was never populated —
    // the inbox badge showed 0 until the user navigated to InboxScreen.
    _userWorker?.dispose();
    _userWorker = ever<User?>(userController.currentUser, (user) {
      if (user != null) {
        _fetchSessionsAndThreads();
      }
    });
  }

  Future<void> _fetchSessionsAndThreads() async {
    await fetchTutorSessions();
    await Future.delayed(const Duration(milliseconds: 800));
    await fetchAllStudentThreads();
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

  Future<List<Review>> _hydrateReviews(List<Review> raw) async {
    return Future.wait(
      raw.map((review) async {
        Review hydrated = review;
        final userId = review.user?.id ?? _reviewUserIdMap[review.id];
        if (userId != null && userId.isNotEmpty) {
          final user = await _resolveUserById(userId);
          if (user != null) hydrated = hydrated.copyWith(user: user);
        }
        final tutorId = review.tutor?.id ?? _reviewTutorIdMap[review.id];
        if (tutorId != null && tutorId.isNotEmpty) {
          final tutor = await _resolveTutorById(tutorId);
          if (tutor != null) hydrated = hydrated.copyWith(tutor: tutor);
        }
        return hydrated;
      }),
    );
  }

  final _reviewUserIdMap = <String, String>{};
  final _reviewTutorIdMap = <String, String>{};

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

  Future<void> fetchAllStudentThreads() async {
    if (!await _canSync()) return;
    if (activeSessions.isEmpty) return;
    try {
      final allMessages = await Amplify.DataStore.query(ChatMessage.classType);
      final sessionIds = activeSessions.map((s) => s.id).toSet();

      final chatIds =
          allMessages
              .where((m) => sessionIds.any((id) => m.sessionId.startsWith(id)))
              .map((m) => m.sessionId)
              .toSet();

      print('💬 fetchAllStudentThreads: found ${chatIds.length} chat threads');

      for (final chatId in chatIds) {
        observeChat(chatId);
      }
    } catch (e) {
      print('❌ fetchAllStudentThreads error: $e');
    }
  }

  Future<void> fetchTutorSessions() async {
    if (!await _canSync()) return;
    try {
      final tutorId = await currentUserTutorId;
      if (tutorId == null) return;

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

      final request = GraphQLRequest<String>(
        document: queryDoc,
        variables: {'tutorId': tutorId, 'limit': 100},
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty || response.data == null) {
        await _fetchTutorSessionsFallback(tutorId);
        return;
      }

      final resolvedTutor = await _resolveTutorById(tutorId);
      final sessionIds = _parseIds(response.data!);
      if (sessionIds.isEmpty) {
        await _fetchTutorSessionsFallback(tutorId);
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
      for (final session in activeSessions) {
        observeChat(session.id);
      }
      print("✅ fetchTutorSessions: loaded ${activeSessions.length} sessions");
    } catch (e) {
      print('❌ fetchTutorSessions error: $e');
    }
  }

  Future<void> _fetchTutorSessionsFallback(String tutorId) async {
    final allRaw = await Amplify.DataStore.query(TutoringSession.classType);
    final resolvedTutor = await _resolveTutorById(tutorId);
    activeSessions.assignAll(
      allRaw.map(
        (s) => resolvedTutor != null ? s.copyWith(tutor: resolvedTutor) : s,
      ),
    );
    for (final session in activeSessions) {
      observeChat(session.id);
    }
  }

  List<String> _parseIds(String jsonStr) {
    final ids = <String>[];
    final idPattern = RegExp(r'"id"\s*:\s*"([^"]+)"');
    for (final match in idPattern.allMatches(jsonStr)) {
      ids.add(match.group(1)!);
    }
    return ids;
  }

  List<TutoringSession> _buildMinimalSessions(String jsonStr, Tutor tutor) {
    final sessions = <TutoringSession>[];
    try {
      final idPattern = RegExp(r'"id"\s*:\s*"([^"]+)"');
      final titlePattern = RegExp(r'"title"\s*:\s*"([^"]+)"');
      final pricePattern = RegExp(r'"pricePerSession"\s*:\s*([\d.]+)');
      final thumbPattern = RegExp(r'"thumbnail"\s*:\s*"([^"]+)"');
      final descPattern = RegExp(r'"description"\s*:\s*"([^"]+)"');
      final ids =
          idPattern.allMatches(jsonStr).map((m) => m.group(1)!).toList();
      final titles =
          titlePattern.allMatches(jsonStr).map((m) => m.group(1)!).toList();
      final prices =
          pricePattern
              .allMatches(jsonStr)
              .map((m) => double.tryParse(m.group(1)!) ?? 0.0)
              .toList();
      final thumbs =
          thumbPattern.allMatches(jsonStr).map((m) => m.group(1)!).toList();
      final descs =
          descPattern.allMatches(jsonStr).map((m) => m.group(1)!).toList();
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

  // ---------------- Session Utilities ----------------
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
    Get.back();
    Get.snackbar(
      "Added to Booking",
      "Session added with your selected options",
      snackPosition: SnackPosition.BOTTOM,
    );
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

  Future<Review> addReview({
    required TutoringSession session,
    required double rating,
    required String comment,
  }) async {
    if (!await _canSync()) throw Exception("User not signed in");
    final authUser = await Amplify.Auth.getCurrentUser();
    final userId = authUser.userId;
    final tutorId = session.tutor?.id ?? '';
    if (tutorId.isEmpty) throw Exception("Session has no tutor assigned");

    final userList = await Amplify.DataStore.query(
      User.classType,
      where: User.ID.eq(userId),
    );
    if (userList.isEmpty) throw Exception("Current user not found");
    final currentUser = userList.first;
    _userCache[currentUser.id] = currentUser;

    final tutorList = await Amplify.DataStore.query(
      Tutor.classType,
      where: Tutor.ID.eq(tutorId),
    );
    if (tutorList.isEmpty) throw Exception("Tutor not found");
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
          id sessionId tutorId rating comment createdAt
        }
      }
    """;

    final request = GraphQLRequest<String>(
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
    );
    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(
        'GraphQL mutation failed: ${response.errors.first.message}',
      );
    }
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
      const queryDoc = """
        query ListReviewsBySession(\$sessionId: ID!, \$limit: Int) {
          listReviews(filter: {sessionId: {eq: \$sessionId}}, limit: \$limit) {
            items { id sessionId tutorId userId rating comment createdAt }
          }
        }
      """;
      final response =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: queryDoc,
                  variables: {'sessionId': sessionId, 'limit': 200},
                ),
              )
              .response;

      List<Review> raw = [];
      if (response.errors.isEmpty && response.data != null) {
        final ids = _parseIds(response.data!);
        _parseReviewFkIds(response.data!);
        for (final id in ids) {
          final results = await Amplify.DataStore.query(
            Review.classType,
            where: Review.ID.eq(id),
          );
          if (results.isNotEmpty) {
            raw.add(results.first);
          } else {
            final minimal = _buildMinimalReviewById(
              id,
              response.data!,
              sessionId,
            );
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
      return await _hydrateReviews(raw);
    } catch (e) {
      print('❌ fetchReviews error: $e');
      return [];
    }
  }

  void _parseReviewFkIds(String jsonStr) {
    final itemPattern = RegExp(r'\{[^{}]*"id"\s*:\s*"([^"]+)"[^{}]*\}');
    final userIdPattern = RegExp(r'"userId"\s*:\s*"([^"]+)"');
    final tutorIdPattern = RegExp(r'"tutorId"\s*:\s*"([^"]+)"');
    for (final match in itemPattern.allMatches(jsonStr)) {
      final block = match.group(0)!;
      final reviewId = match.group(1)!;
      final u = userIdPattern.firstMatch(block);
      if (u != null) _reviewUserIdMap[reviewId] = u.group(1)!;
      final t = tutorIdPattern.firstMatch(block);
      if (t != null) _reviewTutorIdMap[reviewId] = t.group(1)!;
    }
  }

  Review? _buildMinimalReviewById(String id, String jsonStr, String sessionId) {
    try {
      final blocks = RegExp(
        r'\{[^{}]*"id"\s*:\s*"' + RegExp.escape(id) + r'"[^{}]*\}',
      ).allMatches(jsonStr);
      if (blocks.isEmpty) return null;
      final block = blocks.first.group(0)!;
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
      return null;
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
    if (!await _canSync()) return [];
    try {
      const queryDoc = """
        query ListReviewsByTutor(\$tutorId: ID!, \$limit: Int) {
          listReviews(filter: {tutorId: {eq: \$tutorId}}, limit: \$limit) {
            items { id sessionId tutorId userId rating comment createdAt }
          }
        }
      """;
      final response =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: queryDoc,
                  variables: {'tutorId': tutorId, 'limit': 200},
                ),
              )
              .response;

      List<Review> raw = [];
      if (response.errors.isEmpty && response.data != null) {
        final ids = _parseIds(response.data!);
        _parseReviewFkIds(response.data!);
        for (final id in ids) {
          final results = await Amplify.DataStore.query(
            Review.classType,
            where: Review.ID.eq(id),
          );
          if (results.isNotEmpty) {
            raw.add(results.first);
          } else {
            final sessionId = _parseSessionIdForReview(id, response.data!);
            final minimal = _buildMinimalReviewById(
              id,
              response.data!,
              sessionId ?? '',
            );
            if (minimal != null) raw.add(minimal);
          }
        }
      } else {
        final all = await Amplify.DataStore.query(Review.classType);
        raw = all.where((r) => r.tutor?.id == tutorId).toList();
      }
      return await _hydrateReviews(raw);
    } catch (e) {
      print('❌ fetchReviewsByTutor error: $e');
      return [];
    }
  }

  String? _parseSessionIdForReview(String reviewId, String jsonStr) {
    final block = RegExp(
      r'\{[^{}]*"id"\s*:\s*"' + RegExp.escape(reviewId) + r'"[^{}]*\}',
    ).firstMatch(jsonStr)?.group(0);
    if (block == null) return null;
    return RegExp(r'"sessionId"\s*:\s*"([^"]+)"').firstMatch(block)?.group(1);
  }

  // ============================================================
  // CHAT
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
    await Amplify.DataStore.save(message);
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
      await Amplify.DataStore.save(message);
      _onNewMessage(message);
    } on StorageException catch (e) {
      print('❌ S3 Upload failed: ${e.message}');
    }
  }

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
    });
  }

  void _onNewMessage(ChatMessage msg) {
    final chatId = msg.sessionId;
    if (chatId == null) return;
    sessionMessages.update(
      chatId,
      (list) => list..add(msg),
      ifAbsent: () => [msg],
    );
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
    // ✅ Do NOT dispose _userWorker here — it must stay alive so the next
    //    login triggers _fetchSessionsAndThreads() automatically.
    //    The worker watches UserController.currentUser which goes null on
    //    logout and non-null again on the next login.
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
    print('✅ TutoringController: session state cleared on logout');
  }

  /// @deprecated Use clearSessionState() instead.
  void clearAuthCache() {
    _currentAuthUserId = null;
    unreadCounts.clear();
    _chatBaselineTime.clear();
    _observedChatIds.clear();
  }
}
