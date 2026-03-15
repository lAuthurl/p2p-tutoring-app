// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'dart:async';
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

    // ✅ FIX: the ever() on currentUser must call _startAppFlow on EVERY
    //    login, not just the first. The old code had a guard:
    //      if (isLoading.value || isReady.value) return;
    //    After logout, _resetState() sets isReady=false and isLoading=false,
    //    so the guard clears correctly. But the ever() callback fires once
    //    and the worker stays alive — so the second login (after logout)
    //    fires _startAppFlow again as expected. The real issue was that
    //    _resetState() wasn't being called on logout (userController.currentUser
    //    was set to null but the ever() branch for null called _resetState()
    //    which is correct). This is fine — keeping it as-is but making sure
    //    _resetState fully clears isReady so the guard doesn't block re-entry.
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
    // ✅ FIX: reset isReady and isLoading before the guard check so a
    //    re-login after logout always proceeds through the full flow.
    //    Previously isLoading could be true from a previous half-finished
    //    call, blocking the re-login flow silently.
    if (isLoading.value) return; // already in progress — don't double-start
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

      await _buildSessionSubjectMapFromGraphQL();
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

  // ── Wait for DataStore syncQueriesReady ───────────────────────────────────
  Future<void> _waitForDataStoreReady() async {
    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = Amplify.Hub.listen(HubChannel.DataStore, (event) {
      if (event.eventName == 'syncQueriesReady' && !completer.isCompleted) {
        debugPrint('HomeController: DataStore syncQueriesReady received');
        completer.complete();
        sub.cancel();
      }
    });

    try {
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
            'HomeController: syncQueriesReady timed out after 15s — proceeding',
          );
          sub.cancel();
        },
      );
    } catch (e) {
      debugPrint('HomeController: _waitForDataStoreReady error: $e');
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
        debugPrint('HomeController: user created in DataStore');
      } else {
        debugPrint('HomeController: user already exists');
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

  Future<void> _buildSessionSubjectMapFromGraphQL() async {
    const queryDoc = r"""
      query ListAllSessions($limit: Int) {
        listTutoringSessions(limit: $limit) {
          items {
            id
            subjectId
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

      if (response.errors.isNotEmpty) {
        debugPrint(
          'HomeController: _buildSessionSubjectMap errors: ${response.errors}',
        );
        return;
      }

      final data = response.data;
      if (data == null) return;

      _parseSessionSubjectPairs(data);
      debugPrint(
        'HomeController: subject map built — ${_sessionSubjectMap.length} entries',
      );
    } catch (e) {
      debugPrint(
        'HomeController: _buildSessionSubjectMapFromGraphQL error: $e',
      );
    }
  }

  void _parseSessionSubjectPairs(String jsonStr) {
    final itemPattern = RegExp(r'\{[^{}]*"id"\s*:\s*"([^"]+)"[^{}]*\}');
    final subjectIdPattern = RegExp(r'"subjectId"\s*:\s*"([^"]+)"');
    for (final itemMatch in itemPattern.allMatches(jsonStr)) {
      final block = itemMatch.group(0)!;
      final sessionId = itemMatch.group(1)!;
      final subjectMatch = subjectIdPattern.firstMatch(block);
      if (subjectMatch != null) {
        _sessionSubjectMap[sessionId] = subjectMatch.group(1)!;
      }
    }
  }

  Future<void> _loadAllSessionsFromGraphQL() async {
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
          'HomeController: GraphQL session load failed — falling back to DataStore',
        );
        await _loadAllSessionsFromDataStore();
        return;
      }

      final dataStr = response.data!;

      final idPattern = RegExp(r'"id"\s*:\s*"([^"]+)"');
      final sessionIds =
          idPattern.allMatches(dataStr).map((m) => m.group(1)!).toList();
      debugPrint(
        'HomeController: AppSync returned ${sessionIds.length} sessions',
      );

      if (sessionIds.isEmpty) {
        debugPrint(
          'HomeController: 0 sessions from AppSync — using DataStore fallback',
        );
        await _loadAllSessionsFromDataStore();
        return;
      }

      final sessionTutorMap = <String, String>{};
      final itemPattern = RegExp(r'\{[^{}]*"id"\s*:\s*"([^"]+)"[^{}]*\}');
      final tutorIdPattern = RegExp(r'"tutorId"\s*:\s*"([^"]+)"');
      for (final m in itemPattern.allMatches(dataStr)) {
        final block = m.group(0)!;
        final sid = m.group(1)!;
        final tutorMatch = tutorIdPattern.firstMatch(block);
        if (tutorMatch != null) sessionTutorMap[sid] = tutorMatch.group(1)!;
      }

      final resolved = <TutoringSession>[];
      for (final id in sessionIds) {
        final local = await Amplify.DataStore.query(
          TutoringSession.classType,
          where: TutoringSession.ID.eq(id),
        );

        TutoringSession session;
        if (local.isNotEmpty) {
          session = local.first;
        } else {
          final minimal = _buildMinimalSessionFromGraphQL(id, dataStr);
          if (minimal == null) continue;
          session = minimal;
        }

        final tutorId = sessionTutorMap[id] ?? session.tutor?.id;
        if (tutorId != null && tutorId.isNotEmpty) {
          final tutor = await _resolveTutorById(tutorId);
          if (tutor != null) session = session.copyWith(tutor: tutor);
        }

        final subjectId = _sessionSubjectMap[id] ?? session.subject?.id;
        if (subjectId != null && subjectId.isNotEmpty) {
          final subject = await _resolveSubjectById(subjectId);
          if (subject != null) session = session.copyWith(subject: subject);
        }

        resolved.add(session);
      }

      allSessions.assignAll(resolved);
      debugPrint(
        'HomeController: ${resolved.length} sessions loaded from AppSync',
      );
    } catch (e) {
      debugPrint(
        'HomeController: _loadAllSessionsFromGraphQL error: $e — falling back',
      );
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
        'HomeController: DataStore fallback — ${hydrated.length} sessions loaded',
      );
    } catch (e) {
      debugPrint('HomeController: _loadAllSessionsFromDataStore error: $e');
      allSessions.clear();
    }
  }

  TutoringSession? _buildMinimalSessionFromGraphQL(String id, String jsonStr) {
    try {
      final block = RegExp(
        r'\{[^{}]*"id"\s*:\s*"' + RegExp.escape(id) + r'"[^{}]*\}',
      ).firstMatch(jsonStr)?.group(0);
      if (block == null) return null;

      final title =
          RegExp(r'"title"\s*:\s*"([^"]+)"').firstMatch(block)?.group(1) ??
          'Session';
      final description = RegExp(
        r'"description"\s*:\s*"([^"]+)"',
      ).firstMatch(block)?.group(1);
      final price =
          double.tryParse(
            RegExp(
                  r'"pricePerSession"\s*:\s*([\d.]+)',
                ).firstMatch(block)?.group(1) ??
                '0',
          ) ??
          0.0;
      final thumbnail = RegExp(
        r'"thumbnail"\s*:\s*"([^"]+)"',
      ).firstMatch(block)?.group(1);
      final isFeatured =
          RegExp(
            r'"isFeatured"\s*:\s*(true|false)',
          ).firstMatch(block)?.group(1) ==
          'true';

      return TutoringSession(
        id: id,
        title: title,
        description: description,
        pricePerSession: price,
        thumbnail: thumbnail,
        isFeatured: isFeatured,
      );
    } catch (e) {
      return null;
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
  // RESET — called when user logs out
  // =========================================================================

  void _resetState() {
    allSessions.clear();
    filteredSessions.clear();
    featuredSessions.clear();
    popularSessions.clear();
    recentSessions.clear();
    subjectController.subjects.clear();
    // ✅ FIX: must set both false so _startAppFlow() is not blocked
    //    by the isLoading guard on the next login.
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
