// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
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
  // ✅ FIX: Retry with exponential back-off so that a hot-restart doesn't
  //    race DataStore sync and return 0 sessions. The tutor row IS in
  //    local SQLite; we just need to wait a moment for the sync engine to
  //    surface it.
  Future<String?> get currentUserTutorId async {
    const maxAttempts = 5;
    const delays = [0, 500, 1000, 2000, 3000]; // ms

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final delay = delays[attempt];
      if (delay > 0) {
        await Future.delayed(Duration(milliseconds: delay));
      }

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
          if (byEmail.isNotEmpty) {
            print(
              '✅ currentUserTutorId resolved by email on attempt ${attempt + 1}',
            );
            return byEmail.first.id;
          }
        }

        // Fallback: match by Cognito userId stored as Tutor.id
        final byId = await Amplify.DataStore.query(
          Tutor.classType,
          where: Tutor.ID.eq(authUser.userId),
        );
        if (byId.isNotEmpty) {
          print(
            '✅ currentUserTutorId resolved by auth userId on attempt ${attempt + 1}',
          );
          return byId.first.id;
        }

        print(
          '⚠️ Attempt ${attempt + 1}/$maxAttempts: tutor not found yet, retrying...',
        );
      } catch (e) {
        print('❌ currentUserTutorId attempt ${attempt + 1} error: $e');
      }
    }

    print('❌ currentUserTutorId: tutor not found after $maxAttempts attempts');
    return null;
  }

  // ---------------- Reactive State ----------------
  final sessions = <TutoringSession>[].obs;
  final featuredSessions = <TutoringSession>[].obs;
  final popularSessions = <TutoringSession>[].obs;

  /// Sessions belonging to the currently logged-in tutor.
  final activeSessions = <TutoringSession>[].obs;

  final selectedAttributes = <String, String>{}.obs;
  final selectedSessionImage = ''.obs;

  final favorites = <String, RxBool>{}.obs;
  final isSynced = false.obs;

  final sessionMessages = <String, List<ChatMessage>>{}.obs;

  // ---------------- Unread Counts ----------------
  final _unreadCounts = <String, int>{};
  String? currentOpenSessionId;
  int unreadCount(String sessionId) => _unreadCounts[sessionId] ?? 0;

  // ---------------- Caches ----------------
  final _tutorCache = <String, Tutor>{};

  // ✅ NEW: User cache — same pattern as tutor cache, avoids repeated
  //    DataStore queries when hydrating review user relations.
  final _userCache = <String, User>{};

  // ---------------- Reported Tutors ----------------
  // Persists for the lifetime of the controller (survives navigation).
  // Key: tutorId  Value: reason string shown in the investigation banner.
  final reportedTutors = <String, String>{}.obs;

  void reportTutor(String tutorId, String reason) {
    reportedTutors[tutorId] = reason;
  }

  String? getReportReason(String tutorId) => reportedTutors[tutorId];

  // ---------------- Lifecycle ----------------
  @override
  void onInit() {
    super.onInit();
    _observeSessions();
    _initTutorSessionsWhenReady();
  }

  void _initTutorSessionsWhenReady() {
    final userController = UserController.instance;
    if (userController.currentUser.value != null) {
      fetchTutorSessions();
      return;
    }
    late Worker worker;
    worker = ever<User?>(userController.currentUser, (user) {
      if (user != null) {
        fetchTutorSessions();
        worker.dispose();
      }
    });
  }

  // ---------------- Helper: Check if user can sync ----------------
  Future<bool> _canSync() async {
    try {
      await Amplify.Auth.getCurrentUser();
      return true;
    } catch (_) {
      print('⚠️ User not signed in, skipping DataStore operations');
      return false;
    }
  }

  // ============================================================
  // RELATION HYDRATION HELPERS
  // ============================================================
  // Root cause of all "Anonymous", "null tutor", "missing reviews" bugs:
  // Amplify v2 BelongsTo relations are lazy AsyncModel stubs. After a
  // restart the stub object exists (so ?. doesn't throw) but its fields
  // are all null except .id. We always resolve relations by querying
  // DataStore directly with the FK id and cache results to avoid redundant
  // round-trips.

  // ---------------- Tutor Resolution ----------------
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

  // ---------------- User Resolution ----------------
  // ✅ NEW: Resolves a User by id, used to hydrate review.user so that
  //    reviewer names are never shown as "Anonymous".
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

  // ---------------- Session Hydration ----------------
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

  // ---------------- Review Hydration ----------------
  // ✅ NEW: Hydrates both user and tutor relations on reviews so that
  //    review.user?.username and review.tutor?.name are always populated.
  Future<List<Review>> _hydrateReviews(List<Review> raw) async {
    return Future.wait(
      raw.map((review) async {
        Review hydrated = review;

        // ✅ FIX: For reviews fetched via GraphQL that haven't synced back to
        //    DataStore yet, the relation stubs (review.user, review.tutor) are
        //    null. But we stored the FK ids on the Review model directly via
        //    the _reviewUserIdMap. Check both the stub id AND the scalar FK.
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

  // FK id maps for reviews fetched from GraphQL before DataStore sync.
  // Keyed by review id — populated in fetchReviews and fetchReviewsByTutor.
  final _reviewUserIdMap = <String, String>{};
  final _reviewTutorIdMap = <String, String>{};

  // ---------------- AWS DataStore Observers ----------------
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
    try {
      for (final session in activeSessions) {
        final allMessages = await Amplify.DataStore.query(
          ChatMessage.classType,
        );
        final relatedChatIds =
            allMessages
                .where((m) => (m.sessionId).startsWith(session.id))
                .map((m) => m.sessionId)
                .toSet();
        for (final chatId in relatedChatIds) {
          if (!sessionMessages.containsKey(chatId)) observeChat(chatId);
        }
      }
    } catch (e) {
      print('❌ fetchAllStudentThreads error: $e');
    }
  }

  Future<void> fetchTutorSessions() async {
    if (!await _canSync()) return;
    try {
      final tutorId = await currentUserTutorId;
      if (tutorId == null) {
        print('⚠️ fetchTutorSessions: no tutor ID found after retries');
        return;
      }

      // ✅ Use direct GraphQL query with the byTutor index.
      //    DataStore.query with TUTOR.eq() fails because the local SQLite
      //    tutorId column is null for sessions created before this fix.
      //    GraphQL queries AppSync directly using the GSI, which always has
      //    tutorId set correctly since it was written there at creation time.
      const queryDoc = """
        query ListSessionsByTutor(\$tutorId: ID!, \$limit: Int) {
          listTutoringSessions(filter: {tutorId: {eq: \$tutorId}}, limit: \$limit) {
            items {
              id
              title
              description
              pricePerSession
              thumbnail
              tutorId
              subjectId
              isFeatured
              hasPaid
              createdAt
              updatedAt
            }
          }
        }
      """;

      final request = GraphQLRequest<String>(
        document: queryDoc,
        variables: {'tutorId': tutorId, 'limit': 100},
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        print('❌ GraphQL errors: ${response.errors}');
        await _fetchTutorSessionsFallback(tutorId);
        return;
      }

      final dataStr = response.data;
      if (dataStr == null) {
        print('⚠️ fetchTutorSessions: null response data');
        await _fetchTutorSessionsFallback(tutorId);
        return;
      }

      final resolvedTutor = await _resolveTutorById(tutorId);
      final sessionIds = _parseIds(dataStr);
      print(
        '🔍 fetchTutorSessions: GraphQL returned ${sessionIds.length} session IDs',
      );

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
          final s = results.first;
          hydrated.add(
            resolvedTutor != null ? s.copyWith(tutor: resolvedTutor) : s,
          );
        }
      }

      if (hydrated.isEmpty && sessionIds.isNotEmpty && resolvedTutor != null) {
        final minimalSessions = _buildMinimalSessions(dataStr, resolvedTutor);
        hydrated.addAll(minimalSessions);
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
    print('⚠️ fetchTutorSessions: using local fallback');
    final allRaw = await Amplify.DataStore.query(TutoringSession.classType);
    final resolvedTutor = await _resolveTutorById(tutorId);
    final hydrated =
        allRaw
            .map(
              (s) =>
                  resolvedTutor != null ? s.copyWith(tutor: resolvedTutor) : s,
            )
            .toList();
    activeSessions.assignAll(hydrated);
    for (final session in activeSessions) {
      observeChat(session.id);
    }
    print(
      "✅ fetchTutorSessions fallback: loaded ${activeSessions.length} sessions",
    );
  }

  // ============================================================
  // JSON PARSING HELPERS
  // ============================================================

  // ✅ Unified id parser — used by sessions, reviews, and any other model.
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
      final titlePattern = RegExp(r'"title"\s*:\s*"([^"]+)"');
      final idPattern = RegExp(r'"id"\s*:\s*"([^"]+)"');
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
    if ((session.thumbnail?.isNotEmpty ?? false))
      images.add(session.thumbnail!);
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

  // ✅ FIX: Use a direct GraphQL mutation instead of DataStore.save().
  //
  //    Root cause: DataStore serialises BelongsTo relations as {id: x}
  //    stubs when syncing to AppSync. AppSync then tries to return the
  //    full nested tutor/user types in the response selection set, cannot
  //    resolve them from just an id stub, and rejects the mutation with
  //    "Cannot return null for non-nullable type". The review was written
  //    to local SQLite but never reached AppSync so fetchReviewsByTutor
  //    (which queries AppSync) never saw it and names showed as Anonymous.
  //
  //    Solution: call AppSync directly with only scalar FK ids in the
  //    input and only scalar fields in the response selection set.
  Future<Review> addReview({
    required TutoringSession session,
    required double rating,
    required String comment,
  }) async {
    if (!await _canSync()) throw Exception("User not signed in");
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      final userId = authUser.userId;
      final tutorId = session.tutor?.id ?? '';
      if (tutorId.isEmpty) throw Exception("Session has no tutor assigned");

      // Resolve full objects into cache so _hydrateReviews works instantly.
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

      // Only scalar fields in input and response — no nested types.
      // Amplify codegen names BelongsTo FK inputs as:
      //   reviewTutorId  (relation field "tutor" on Review)
      //   reviewUserId   (relation field "user" on Review)
      // Check your AppSync CreateReviewInput type if names differ.
      // ✅ Field names confirmed from generated Review model schema:
      //    tutorId  → BelongsTo Tutor FK (targetNames: [tutorId])
      //    userId   → BelongsTo User FK  (targetNames: [userId])
      //    sessionId is ID! not String!
      //    reviewTutorId does NOT exist in CreateReviewInput
      const mutationDoc = """
        mutation CreateReview(
          \$id: ID!,
          \$sessionId: ID!,
          \$tutorId: ID!,
          \$userId: ID!,
          \$rating: Float!,
          \$comment: String,
          \$createdAt: AWSDateTime!
        ) {
          createReview(input: {
            id: \$id,
            sessionId: \$sessionId,
            tutorId: \$tutorId,
            userId: \$userId,
            rating: \$rating,
            comment: \$comment,
            createdAt: \$createdAt
          }) {
            id
            sessionId
            tutorId
            rating
            comment
            createdAt
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

      print('📦 createReview data: ${response.data}');
      if (response.errors.isNotEmpty) {
        print('❌ createReview GraphQL errors: ${response.errors}');
        throw Exception(
          'GraphQL mutation failed: ${response.errors.first.message}',
        );
      }

      print('✅ Review saved to AppSync via direct GraphQL: $reviewId');

      // ✅ Pre-populate FK maps so fetchReviews called immediately after
      //    can hydrate the user/tutor names without waiting for DataStore sync.
      _reviewUserIdMap[reviewId] = userId;
      _reviewTutorIdMap[reviewId] = tutorId;

      // Return fully hydrated Review for immediate UI display.
      // DataStore syncs the record back from AppSync in the background.
      return Review(
        id: reviewId,
        user: currentUser,
        sessionId: session.id,
        tutor: currentTutor,
        rating: rating,
        comment: comment,
        createdAt: now,
      );
    } catch (e) {
      print('❌ Error adding review for session ${session.id}: $e');
      rethrow;
    }
  }

  // ✅ FIX: Query AppSync directly via GraphQL instead of local DataStore.
  //    Since addReview now bypasses DataStore.save() and writes directly to
  //    AppSync, new reviews are NOT in local SQLite until DataStore syncs
  //    them back (which can take several seconds). Querying AppSync ensures
  //    newly submitted reviews appear immediately.
  Future<List<Review>> fetchReviews(String sessionId) async {
    if (!await _canSync()) return [];
    try {
      const queryDoc = """
        query ListReviewsBySession(\$sessionId: ID!, \$limit: Int) {
          listReviews(filter: {sessionId: {eq: \$sessionId}}, limit: \$limit) {
            items {
              id
              sessionId
              tutorId
              userId
              rating
              comment
              createdAt
            }
          }
        }
      """;

      final request = GraphQLRequest<String>(
        document: queryDoc,
        variables: {'sessionId': sessionId, 'limit': 200},
      );

      final response = await Amplify.API.query(request: request).response;

      List<Review> raw = [];

      if (response.errors.isEmpty && response.data != null) {
        final ids = _parseIds(response.data!);
        print(
          '🔍 fetchReviews: GraphQL returned ${ids.length} review IDs for session $sessionId',
        );

        // ✅ FIX: Parse userId + tutorId from GraphQL response and store in
        //    maps so _hydrateReviews can resolve names even before DataStore
        //    syncs the review back with its relation stubs populated.
        _parseReviewFkIds(response.data!);

        for (final id in ids) {
          // Try local DataStore first (faster), fall back to minimal object.
          final results = await Amplify.DataStore.query(
            Review.classType,
            where: Review.ID.eq(id),
          );
          if (results.isNotEmpty) {
            raw.add(results.first);
          } else {
            // DataStore hasn't synced this review back yet — build from GraphQL data.
            final minimal = _buildMinimalReviewById(
              id,
              response.data!,
              sessionId,
            );
            if (minimal != null) raw.add(minimal);
          }
        }
      } else {
        // Offline fallback: query local DataStore.
        print(
          '⚠️ fetchReviews falling back to DataStore for session $sessionId',
        );
        final local = await Amplify.DataStore.query(
          Review.classType,
          where: Review.SESSIONID.eq(sessionId),
        );
        raw = local.where((r) => r.createdAt != null).toList();
      }

      return await _hydrateReviews(raw);
    } catch (e) {
      print('❌ Error fetching reviews for session $sessionId: $e');
      return [];
    }
  }

  // ✅ Parses userId and tutorId scalars from a GraphQL reviews response
  //    and stores them in maps so _hydrateReviews can resolve names for
  //    reviews that haven't yet been synced back into local DataStore.
  void _parseReviewFkIds(String jsonStr) {
    // Match each {...} item block — must contain "id" field
    final itemPattern = RegExp(r'\{[^{}]*"id"\s*:\s*"([^"]+)"[^{}]*\}');
    final userIdPattern = RegExp(r'"userId"\s*:\s*"([^"]+)"');
    final tutorIdPattern = RegExp(r'"tutorId"\s*:\s*"([^"]+)"');

    for (final match in itemPattern.allMatches(jsonStr)) {
      final block = match.group(0)!;
      final reviewId = match.group(1)!;

      final userIdMatch = userIdPattern.firstMatch(block);
      if (userIdMatch != null) {
        _reviewUserIdMap[reviewId] = userIdMatch.group(1)!;
      }

      final tutorIdMatch = tutorIdPattern.firstMatch(block);
      if (tutorIdMatch != null) {
        _reviewTutorIdMap[reviewId] = tutorIdMatch.group(1)!;
      }
    }
  }

  // Build a minimal Review from the GraphQL JSON for a specific id,
  // used when DataStore hasn't synced the record back yet.
  Review? _buildMinimalReviewById(String id, String jsonStr, String sessionId) {
    try {
      // Find the item block containing this specific id.
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
      print('❌ _buildMinimalReviewById error for $id: $e');
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

  // ✅ FIX: Local SQLite tutorId FK column is null for BelongsTo in
  //    Amplify v2 — Review.TUTOR.eq(tutorId) returns nothing locally.
  //    Use GraphQL to query AppSync directly (same fix as fetchTutorSessions)
  //    then hydrate so tutor profile always shows reviews correctly.
  Future<List<Review>> fetchReviewsByTutor(String tutorId) async {
    if (!await _canSync()) return [];
    try {
      // ✅ FIX 1: Added userId to selection set — _parseReviewFkIds needs
      //    it to populate _reviewUserIdMap so _hydrateReviews can resolve
      //    usernames. Without this field the names always show as Anonymous.
      // ✅ FIX 2: Per-id fallback to _buildMinimalReviewById — same pattern
      //    as fetchReviews. Previously skipped any review not yet in local
      //    DataStore causing count mismatches (e.g. 2 instead of 4).
      const queryDoc = """
        query ListReviewsByTutor(\$tutorId: ID!, \$limit: Int) {
          listReviews(filter: {tutorId: {eq: \$tutorId}}, limit: \$limit) {
            items {
              id
              sessionId
              tutorId
              userId
              rating
              comment
              createdAt
            }
          }
        }
      """;

      final request = GraphQLRequest<String>(
        document: queryDoc,
        variables: {'tutorId': tutorId, 'limit': 200},
      );

      final response = await Amplify.API.query(request: request).response;

      List<Review> raw = [];

      if (response.errors.isEmpty && response.data != null) {
        final ids = _parseIds(response.data!);
        print(
          '🔍 fetchReviewsByTutor: GraphQL returned ${ids.length} review IDs',
        );

        // Populate FK maps FIRST so _hydrateReviews has userId for every id.
        _parseReviewFkIds(response.data!);

        for (final id in ids) {
          // Try local DataStore first (faster).
          final results = await Amplify.DataStore.query(
            Review.classType,
            where: Review.ID.eq(id),
          );
          if (results.isNotEmpty) {
            raw.add(results.first);
          } else {
            // DataStore hasn't synced this review yet — build from GraphQL.
            // Uses the sessionId stored in _reviewUserIdMap's sibling data.
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
        // Offline fallback: scan all local reviews
        print('⚠️ fetchReviewsByTutor falling back to DataStore');
        final all = await Amplify.DataStore.query(Review.classType);
        raw = all.where((r) => r.tutor?.id == tutorId).toList();
      }

      return await _hydrateReviews(raw);
    } catch (e) {
      print('❌ Error fetching reviews for tutor $tutorId: $e');
      return [];
    }
  }

  // Helper: parse the sessionId for a specific review id from GraphQL JSON.
  String? _parseSessionIdForReview(String reviewId, String jsonStr) {
    final block = RegExp(
      r'\{[^{}]*"id"\s*:\s*"' + RegExp.escape(reviewId) + r'"[^{}]*\}',
    ).firstMatch(jsonStr)?.group(0);
    if (block == null) return null;
    return RegExp(r'"sessionId"\s*:\s*"([^"]+)"').firstMatch(block)?.group(1);
  }

  // ---------------- Chat Sessions ----------------
  List<String> get chatSessions => sessionMessages.keys.toList();

  // ---------------- Chat ----------------
  // ✅ FIX: _resolveSenderName now uses the _userCache before hitting
  //    DataStore, preventing redundant queries on every message send.
  Future<String> _resolveSenderName(String userId) async {
    // Check user cache first
    if (_userCache.containsKey(userId)) {
      final cached = _userCache[userId]!;
      if (cached.username.isNotEmpty) return cached.username;
    }

    try {
      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(userId),
      );
      if (users.isNotEmpty && (users.first.username.isNotEmpty)) {
        _userCache[userId] = users.first;
        return users.first.username;
      }
    } catch (_) {}

    // Check tutor cache
    if (_tutorCache.containsKey(userId)) {
      final cached = _tutorCache[userId]!;
      if (cached.name.isNotEmpty) return cached.name;
    }

    try {
      final tutors = await Amplify.DataStore.query(
        Tutor.classType,
        where: Tutor.ID.eq(userId),
      );
      if (tutors.isNotEmpty && (tutors.first.name.isNotEmpty)) {
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
      _onNewMessage(message);
    } on StorageException catch (e) {
      print('❌ S3 Upload or URL failed: ${e.message}');
    }
  }

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

      final existing = sessionMessages[sessionId] ?? [];
      final existingIds = existing.map((m) => m.id).toSet();

      for (final msg in msgs) {
        if (!existingIds.contains(msg.id)) _onNewMessage(msg);
      }

      sessionMessages[sessionId] = msgs;
    });
  }

  void _onNewMessage(ChatMessage msg) {
    final id = msg.sessionId;
    if (id == null) return;

    sessionMessages.update(id, (list) => list..add(msg), ifAbsent: () => [msg]);

    if (currentOpenSessionId != id) {
      _unreadCounts[id] = (_unreadCounts[id] ?? 0) + 1;
      sessionMessages.refresh();
    }
  }

  void markSessionRead(String sessionId) {
    _unreadCounts[sessionId] = 0;
    currentOpenSessionId = sessionId;
    sessionMessages.refresh();
  }

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
      activeSessions.removeWhere((s) => s.id == sessionId);
      favorites.remove(sessionId);
      sessionMessages.remove(sessionId);
      _unreadCounts.remove(sessionId);

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
      if (popularSessions.length < 4) popularSessions.add(deletedSession);
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
      onTimeout: () => subscription.cancel(),
    );
  }

  // ---------------- Cache Warming ----------------
  /// Called by HomeController to share its already-resolved tutor objects,
  /// avoiding duplicate DataStore queries across controllers.
  void warmTutorCache(Tutor tutor) {
    _tutorCache[tutor.id] = tutor;
  }

  /// Called by HomeController to pre-populate user cache entries.
  void warmUserCache(User user) {
    _userCache[user.id] = user;
  }
}
