// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/ModelProvider.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../Booking/controllers/booking_controller.dart';
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

  /// ✅ FIX: Load ALL sessions directly from the GraphQL JSON response.
  ///
  /// The previous approach fetched session IDs from AppSync then re-queried
  /// DataStore for each one. DataStore only contains sessions belonging to
  /// the current user's sync scope — sessions created by OTHER tutors are
  /// never in the local DataStore, so they were silently dropped.
  ///
  /// Now we decode the full AppSync response using dart:convert and build
  /// TutoringSession objects directly from the JSON maps. No DataStore
  /// lookup needed — every session AppSync returns gets shown regardless
  /// of which account created it.
  Future<void> _loadAllSessionsFromGraphQL() async {
    // ✅ Request ALL fields we need in one query — no second DataStore fetch.
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

      // ✅ Parse response with dart:convert — reliable for nested JSON.
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

        // ✅ Build session directly from the GraphQL map — no DataStore query.
        // This means sessions from ALL tutors are included, not just the
        // current user's DataStore scope.
        final tutorId = item['tutorId'] as String?;
        final subjectId = item['subjectId'] as String?;
        final createdAtStr = item['createdAt'] as String?;
        final updatedAtStr = item['updatedAt'] as String?;

        // Cache subject mapping.
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
          createdAt:
              createdAtStr != null
                  ? TemporalDateTime.fromString(createdAtStr)
                  : null,
          updatedAt:
              updatedAtStr != null
                  ? TemporalDateTime.fromString(updatedAtStr)
                  : null,
        );

        // Resolve tutor (cache-friendly — only one DataStore query per unique tutor).
        if (tutorId != null && tutorId.isNotEmpty) {
          final tutor = await _resolveTutorById(tutorId);
          if (tutor != null) session = session.copyWith(tutor: tutor);
        }

        // Resolve subject.
        if (subjectId != null && subjectId.isNotEmpty) {
          final subject = await _resolveSubjectById(subjectId);
          if (subject != null) session = session.copyWith(subject: subject);
        }

        resolved.add(session);
      }

      allSessions.assignAll(resolved);
      debugPrint(
        'HomeController: ${resolved.length} sessions loaded from AppSync '
        '(all tutors)',
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
  // FILTERING
  // =========================================================================

  void _applyFilters() {
    final selectedSubject = subjectController.selectedSubject.value;
    final query = searchQuery.value.toLowerCase();

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
          return matchesSubject && matchesSearch;
        }).toList();

    filteredSessions.assignAll(filtered);
    featuredSessions.value =
        filtered.where((s) => s.isFeatured ?? false).toList();
    popularSessions.value = filtered.toList();
    recentSessions.value = filtered.reversed.toList();
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
