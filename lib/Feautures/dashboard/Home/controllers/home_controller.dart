// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/ModelProvider.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../booking/controllers/booking_controller.dart';
import '../controllers/subject_controller.dart';

class HomeController extends GetxController {
  static HomeController get instance => Get.find<HomeController>();

  late final UserController userController;
  late final SubjectController subjectController;

  final RxBool isReady = false.obs;
  final RxBool isLoading = false.obs;

  final RxList<TutoringSession> allSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> featuredSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> popularSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> recentSessions = <TutoringSession>[].obs;

  final RxString searchQuery = ''.obs;
  final RxList<TutoringSession> filteredSessions = <TutoringSession>[].obs;

  final _tutorCache = <String, Tutor>{};
  final _sessionSubjectMap = <String, String>{};

  @override
  void onInit() {
    super.onInit();
    userController = Get.find<UserController>();
    subjectController = Get.find<SubjectController>();

    ever<User?>(userController.currentUser, (user) {
      if (user != null) {
        _startAppFlow();
      } else {
        _resetState();
      }
    });

    ever(subjectController.selectedSubject, (_) => _applyFilters());
    ever(allSessions, (_) => _applyFilters());
    ever(searchQuery, (_) => _applyFilters());
  }

  @override
  void onReady() {
    super.onReady();
    if (userController.currentUser.value != null) _startAppFlow();
  }

  // =========================================================================
  // STARTUP FLOW
  // =========================================================================

  Future<void> _startAppFlow() async {
    if (isLoading.value) return;
    isLoading.value = true;
    isReady.value = false;

    try {
      final authSession = await Amplify.Auth.fetchAuthSession();
      if (!authSession.isSignedIn) {
        debugPrint('HomeController: user not signed in, halting');
        return;
      }

      final user = userController.currentUser.value!;
      await _ensureUserExists(user);
      _ensureBookingController();
      await subjectController.fetchSubjects();

      await _waitForDataStoreReady();
      await Future.delayed(const Duration(milliseconds: 800));

      await _loadAllSessionsFromGraphQL();

      debugPrint('HomeController: ready for ${user.username}');
      isReady.value = true;
    } catch (e) {
      debugPrint('HomeController startup error: $e');
      await _loadAllSessionsFromDataStore();
      isReady.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _waitForDataStoreReady() async {
    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = Amplify.Hub.listen(HubChannel.DataStore, (event) {
      if (event.eventName == 'syncQueriesReady' && !completer.isCompleted) {
        completer.complete();
        sub.cancel();
      }
    });
    try {
      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('HomeController: syncQueriesReady timed out — proceeding');
          sub.cancel();
        },
      );
    } catch (e) {
      sub.cancel();
    }
  }

  Future<void> _ensureUserExists(User user) async {
    try {
      final existing = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(user.id),
      );
      if (existing.isEmpty) {
        await Amplify.DataStore.save(user);
      }
    } catch (e) {
      debugPrint('HomeController: _ensureUserExists error: $e');
    }
  }

  void _ensureBookingController() {
    if (!Get.isRegistered<BookingController>()) {
      Get.put(BookingController(), permanent: true);
    }
  }

  // =========================================================================
  // SESSION LOADING
  // =========================================================================

  Future<void> _loadAllSessionsFromGraphQL() async {
    // ✅ maxStudents + enrolledCount added to query
    const queryDoc = r"""
      query ListAllSessionsFull($limit: Int) {
        listTutoringSessions(limit: $limit) {
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
            maxStudents
            enrolledCount
            createdAt
            updatedAt
          }
        }
      }
    """;

    try {
      final request = GraphQLRequest<String>(
        document: queryDoc,
        variables: {'limit': 1000},
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty || response.data == null) {
        debugPrint(
          'HomeController: GraphQL failed — falling back to DataStore',
        );
        await _loadAllSessionsFromDataStore();
        return;
      }

      final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
      final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
      final listObj = root['listTutoringSessions'] as Map<String, dynamic>?;
      final items = listObj?['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) {
        debugPrint(
          'HomeController: 0 sessions from AppSync — DataStore fallback',
        );
        await _loadAllSessionsFromDataStore();
        return;
      }

      debugPrint('HomeController: AppSync returned ${items.length} sessions');

      final resolved = <TutoringSession>[];

      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        final id = item['id'] as String?;
        if (id == null) continue;

        final tutorId = item['tutorId'] as String?;
        final subjectId = item['subjectId'] as String?;
        final createdAtStr = item['createdAt'] as String?;
        final updatedAtStr = item['updatedAt'] as String?;

        if (subjectId != null && subjectId.isNotEmpty) {
          _sessionSubjectMap[id] = subjectId;
        }

        TutoringSession session = TutoringSession(
          id: id,
          title: item['title'] as String? ?? 'Session',
          description: item['description'] as String?,
          pricePerSession: (item['pricePerSession'] as num?)?.toDouble(),
          thumbnail: item['thumbnail'] as String?,
          isFeatured: item['isFeatured'] as bool?,
          // ✅ NEW: read capacity fields from GraphQL response
          maxStudents: item['maxStudents'] as int?,
          enrolledCount: item['enrolledCount'] as int? ?? 0,
          createdAt:
              createdAtStr != null
                  ? TemporalDateTime.fromString(createdAtStr)
                  : null,
          updatedAt:
              updatedAtStr != null
                  ? TemporalDateTime.fromString(updatedAtStr)
                  : null,
        );

        if (tutorId != null && tutorId.isNotEmpty) {
          final tutor = await _resolveTutorById(tutorId);
          if (tutor != null) session = session.copyWith(tutor: tutor);
        }

        if (subjectId != null && subjectId.isNotEmpty) {
          final subject = await _resolveSubjectById(subjectId);
          if (subject != null) session = session.copyWith(subject: subject);
        }

        resolved.add(session);
      }

      allSessions.assignAll(resolved);
      debugPrint(
        'HomeController: ${resolved.length} sessions loaded from AppSync (all tutors)',
      );
    } catch (e) {
      debugPrint('HomeController: _loadAllSessionsFromGraphQL error: $e');
      await _loadAllSessionsFromDataStore();
    }
  }

  Future<void> _loadAllSessionsFromDataStore() async {
    try {
      final rawSessions = await Amplify.DataStore.query(
        TutoringSession.classType,
      );
      final hydrated = await _hydrateSessions(rawSessions);
      allSessions.assignAll(hydrated);
      debugPrint(
        'HomeController: DataStore fallback — ${hydrated.length} sessions',
      );
    } catch (e) {
      debugPrint('HomeController: _loadAllSessionsFromDataStore error: $e');
      allSessions.clear();
    }
  }

  // =========================================================================
  // RELATION RESOLUTION
  // =========================================================================

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
      return null;
    }
  }

  Future<Subject?> _resolveSubject(TutoringSession session) async {
    final subjectId = _sessionSubjectMap[session.id] ?? session.subject?.id;
    if (subjectId == null || subjectId.isEmpty) return null;
    return _resolveSubjectById(subjectId);
  }

  Future<Subject?> _resolveSubjectById(String subjectId) async {
    try {
      return subjectController.subjects.firstWhere((s) => s.id == subjectId);
    } catch (_) {}
    try {
      final results = await Amplify.DataStore.query(
        Subject.classType,
        where: Subject.ID.eq(subjectId),
      );
      return results.isEmpty ? null : results.first;
    } catch (e) {
      return null;
    }
  }

  Future<List<TutoringSession>> _hydrateSessions(
    List<TutoringSession> raw,
  ) async {
    return Future.wait(
      raw.map((session) async {
        final tutor = await _resolveTutor(session);
        final subject = await _resolveSubject(session);
        TutoringSession hydrated = session;
        if (tutor != null) hydrated = hydrated.copyWith(tutor: tutor);
        if (subject != null) hydrated = hydrated.copyWith(subject: subject);
        return hydrated;
      }),
    );
  }

  // =========================================================================
  // CACHE WARMING
  // =========================================================================

  void warmTutorCache(Tutor tutor) => _tutorCache[tutor.id] = tutor;

  void warmSessionSubjectMap(String sessionId, String subjectId) {
    _sessionSubjectMap[sessionId] = subjectId;
  }

  // =========================================================================
  // CAPACITY HELPERS
  // =========================================================================

  /// Returns true when a session has a cap AND is full.
  /// Used by _applyFilters to exclude full sessions from browse lists.
  bool _isFull(TutoringSession s) {
    final max = s.maxStudents;
    if (max == null || max <= 0) return false;
    return (s.enrolledCount ?? 0) >= max;
  }

  /// Remaining spots. Returns null when no cap is set (unlimited).
  int? spotsLeft(TutoringSession s) {
    final max = s.maxStudents;
    if (max == null || max <= 0) return null;
    return (max - (s.enrolledCount ?? 0)).clamp(0, max);
  }

  /// Increments enrolledCount on the local copy of a session after payment.
  /// Also persists the new count to AppSync via a GraphQL mutation.
  Future<void> incrementEnrolledCount(String sessionId) async {
    final idx = allSessions.indexWhere((s) => s.id == sessionId);
    if (idx == -1) return;

    final old = allSessions[idx];
    final newCount = (old.enrolledCount ?? 0) + 1;
    final updated = old.copyWith(enrolledCount: newCount);

    // Optimistic local update — UI reacts immediately
    allSessions[idx] = updated;

    // Persist to AppSync
    try {
      const mutationDoc = r"""
        mutation IncrementEnrolled($id: ID!, $enrolledCount: Int!, $expectedVersion: Int!) {
          updateTutoringSession(input: {
            id: $id,
            enrolledCount: $enrolledCount,
            _version: $expectedVersion
          }) {
            id enrolledCount _version
          }
        }
      """;

      // Fetch current _version first to avoid conflict errors
      const getDoc = r"""
        query GetSessionVersion($id: ID!) {
          getTutoringSession(id: $id) { id _version enrolledCount }
        }
      """;

      final getResp =
          await Amplify.API
              .query(
                request: GraphQLRequest<String>(
                  document: getDoc,
                  variables: {'id': sessionId},
                ),
              )
              .response;

      int version = 1;
      if (getResp.errors.isEmpty && getResp.data != null) {
        final decoded = jsonDecode(getResp.data!) as Map<String, dynamic>;
        final root = (decoded['data'] as Map<String, dynamic>?) ?? decoded;
        final obj = root['getTutoringSession'] as Map<String, dynamic>?;
        if (obj != null) {
          version = (obj['_version'] as num?)?.toInt() ?? 1;
          // Use server's actual count + 1 to avoid races between devices
          final serverCount = (obj['enrolledCount'] as num?)?.toInt() ?? 0;
          final trustedCount = serverCount + 1;
          // Re-patch local if server had a different value
          if (trustedCount != newCount) {
            allSessions[idx] = old.copyWith(enrolledCount: trustedCount);
          }
        }
      }

      await Amplify.API
          .mutate(
            request: GraphQLRequest<String>(
              document: mutationDoc,
              variables: {
                'id': sessionId,
                'enrolledCount': newCount,
                'expectedVersion': version,
              },
            ),
          )
          .response;

      debugPrint(
        'HomeController: enrolledCount incremented for $sessionId → $newCount',
      );
    } catch (e) {
      debugPrint('HomeController: incrementEnrolledCount error: $e');
    }
  }

  // =========================================================================
  // FILTERING & RANKING
  // =========================================================================

  void _applyFilters() {
    final selectedSubject = subjectController.selectedSubject.value;
    final query = searchQuery.value.toLowerCase();

    // Step 1: apply subject + search filter
    // ✅ Full sessions are excluded from browse lists (filteredSessions,
    //    featuredSessions, popularSessions, recentSessions).
    //    They remain in allSessions so favorites can still display them.
    final filtered =
        allSessions.where((s) {
          final resolvedSubjectId = _sessionSubjectMap[s.id] ?? s.subject?.id;
          final matchesSubject =
              selectedSubject == null ||
              resolvedSubjectId == selectedSubject.id;
          final matchesSearch =
              query.isEmpty ||
              s.title.toLowerCase().contains(query) ||
              (s.tutor?.name.toLowerCase().contains(query) ?? false);
          // ✅ Exclude full sessions from public browse
          final notFull = !_isFull(s);
          return matchesSubject && matchesSearch && notFull;
        }).toList();

    // Step 2: sort all sessions newest-first (true recency sort)
    filtered.sort((a, b) {
      final aTime = a.createdAt?.getDateTimeInUtc() ?? DateTime(0);
      final bTime = b.createdAt?.getDateTimeInUtc() ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

    filteredSessions.assignAll(filtered);

    // Step 3: featured = top-scored sessions via composite quality signal.
    final scored =
        filtered.map((s) => (session: s, score: _featuredScore(s))).toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    final topScored =
        scored.where((e) => e.score > 0).take(4).map((e) => e.session).toList();

    featuredSessions.value =
        topScored.isNotEmpty ? topScored : filtered.take(4).toList();

    // Step 4: popular = highest-priced first, then highest-rated, then newest.
    final byPopularity = List<TutoringSession>.from(filtered)..sort((a, b) {
      final priceDiff = (b.pricePerSession ?? 0).compareTo(
        a.pricePerSession ?? 0,
      );
      if (priceDiff != 0) return priceDiff;
      final ratingDiff = _avgRating(b).compareTo(_avgRating(a));
      if (ratingDiff != 0) return ratingDiff;
      final aTime = a.createdAt?.getDateTimeInUtc() ?? DateTime(0);
      final bTime = b.createdAt?.getDateTimeInUtc() ?? DateTime(0);
      return bTime.compareTo(aTime);
    });
    popularSessions.value = byPopularity;

    // Step 5: recentSessions mirrors filteredSessions — already newest-first.
    recentSessions.value = filtered;
  }

  /// Composite score used to rank "Featured" sessions.
  double _featuredScore(TutoringSession s) {
    double score = 0;

    if (s.isFeatured == true) score += 40;
    if (s.thumbnail != null && s.thumbnail!.isNotEmpty) score += 30;
    if (s.description != null && s.description!.isNotEmpty) score += 20;
    if (s.tutor?.name != null && s.tutor!.name.isNotEmpty) score += 10;

    // Rating signal with confidence weighting
    final reviews = s.reviews;
    if (reviews != null && reviews.isNotEmpty) {
      final count = reviews.length;
      final avgRating =
          reviews.fold<double>(0, (sum, r) => sum + r.rating) / count;
      final confidence = (count.clamp(0, 10) / 10).toDouble();
      score += (avgRating / 5) * 25 * confidence;
    }

    // Recency bonus — linear decay over 30 days
    final created = s.createdAt?.getDateTimeInUtc();
    if (created != null) {
      final ageInDays = DateTime.now().toUtc().difference(created).inDays;
      if (ageInDays <= 30) {
        score += (1 - ageInDays / 30) * 10;
      }
    }

    // Price signal — proportional up to ₦10,000
    final price = s.pricePerSession ?? 0;
    if (price > 0) {
      score += (price.clamp(0, 10000) / 10000) * 10;
    }

    return score;
  }

  /// Average rating helper — returns 0.0 if no reviews.
  double _avgRating(TutoringSession s) {
    final reviews = s.reviews;
    if (reviews == null || reviews.isEmpty) return 0.0;
    return reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;
  }

  void updateSearch(String query) => searchQuery.value = query;

  // =========================================================================
  // RESET
  // =========================================================================

  void _resetState() {
    allSessions.clear();
    filteredSessions.clear();
    featuredSessions.clear();
    popularSessions.clear();
    recentSessions.clear();
    subjectController.subjects.clear();
    isReady.value = false;
    isLoading.value = false;
    searchQuery.value = '';
    _tutorCache.clear();
    _sessionSubjectMap.clear();
  }

  // =========================================================================
  // PUBLIC GETTERS
  // =========================================================================

  List<TutoringSession> getAllSessions() {
    final all = [...featuredSessions, ...popularSessions, ...recentSessions];
    return {for (var s in all) s.id: s}.values.toList();
  }

  List<Subject> getFeaturedSubjects({int limit = 10}) {
    final featured = subjectController.featuredSubjects;
    return featured.length <= limit
        ? featured.toList()
        : featured.sublist(0, limit);
  }
}
