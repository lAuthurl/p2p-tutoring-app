// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/ModelProvider.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../Booking/controllers/booking_controller.dart';
import '../controllers/subject_controller.dart';

class HomeController extends GetxController {
  // ---------------- Singleton ----------------
  static HomeController get instance => Get.find<HomeController>();

  // ---------------- Dependencies ----------------
  late final UserController userController;
  late final SubjectController subjectController;

  // ---------------- State ----------------
  final RxBool isReady = false.obs;
  final RxBool isLoading = false.obs;

  // ---------------- Sessions ----------------
  final RxList<TutoringSession> allSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> featuredSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> popularSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> recentSessions = <TutoringSession>[].obs;

  // ---------------- Search ----------------
  final RxString searchQuery = ''.obs;
  final RxList<TutoringSession> filteredSessions = <TutoringSession>[].obs;

  // ---------------- Caches ----------------
  final _tutorCache = <String, Tutor>{};

  // sessionId -> subjectId sourced from GraphQL (AppSync always has this
  // correct; local SQLite subjectId column is null due to Amplify v2 bug)
  final _sessionSubjectMap = <String, String>{};

  // ---------------- Lifecycle ----------------
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

  // ---------------- Startup Flow ----------------
  Future<void> _startAppFlow() async {
    if (isLoading.value || isReady.value) return;

    isLoading.value = true;
    isReady.value = false;

    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        debugPrint("⚠️ User not signed in. Startup halted.");
        return;
      }

      final user = userController.currentUser.value!;
      await _ensureUserExists(user);
      _ensureBookingController();

      await subjectController.fetchSubjects();

      // ✅ Build the sessionId→subjectId map from GraphQL FIRST, before
      //    loading sessions, so _applyFilters has it ready immediately.
      await _buildSessionSubjectMapFromGraphQL();
      await _loadAllSessions();

      debugPrint("🏠 HomeController ready for ${user.username}");
      isReady.value = true;
    } catch (e) {
      debugPrint('❌ HomeController startup error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _ensureUserExists(User user) async {
    final existing = await Amplify.DataStore.query(
      User.classType,
      where: User.ID.eq(user.id),
    );
    if (existing.isEmpty) {
      await Amplify.DataStore.save(user);
      debugPrint('✅ User created in DataStore');
    } else {
      debugPrint('✅ User already exists');
    }
  }

  void _ensureBookingController() {
    if (!Get.isRegistered<BookingController>()) {
      Get.put(BookingController(), permanent: true);
    }
  }

  // ---------------- Build Subject Map from GraphQL ----------------
  // AppSync always stores subjectId correctly on every session row.
  // Local SQLite does not — the BelongsTo FK column is null after restart.
  // We query ALL sessions from AppSync (no tutorId filter) and parse out
  // the id→subjectId pairs.
  Future<void> _buildSessionSubjectMapFromGraphQL() async {
    const queryDoc = """
      query ListAllSessions(\$limit: Int) {
        listTutoringSessions(limit: \$limit) {
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
          '⚠️ _buildSessionSubjectMapFromGraphQL errors: ${response.errors}',
        );
        return;
      }

      final data = response.data;
      if (data == null) return;

      // Parse pairs of "id":"..." and "subjectId":"..." from the JSON.
      // Each session object has exactly one id and one subjectId (or null).
      _parseSessionSubjectPairs(data);

      debugPrint(
        '🗺️  Session→Subject map built from GraphQL: ${_sessionSubjectMap.length} entries',
      );
      // Log a sample so we can verify
      _sessionSubjectMap.entries
          .take(3)
          .forEach((e) => debugPrint('   ${e.key} → ${e.value}'));
    } catch (e) {
      debugPrint('❌ _buildSessionSubjectMapFromGraphQL error: $e');
    }
  }

  void _parseSessionSubjectPairs(String jsonStr) {
    // Match each {...} item block and extract id + subjectId from it.
    // Regex finds blocks between { } that contain "id" field.
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

  // ---------------- Load All Sessions ----------------
  Future<void> _loadAllSessions() async {
    try {
      final rawSessions = await Amplify.DataStore.query(
        TutoringSession.classType,
      );
      final hydrated = await _hydrateSessions(rawSessions);
      allSessions.assignAll(hydrated);
      debugPrint('🔹 Sessions loaded + hydrated: ${hydrated.length}');
    } catch (e) {
      debugPrint('❌ Error loading sessions: $e');
      allSessions.clear();
    }
  }

  // ---------------- Tutor Resolution ----------------
  Future<Tutor?> _resolveTutor(TutoringSession session) async {
    final tutorId = session.tutor?.id;
    if (tutorId == null || tutorId.isEmpty) return null;

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
      debugPrint('❌ _resolveTutor failed for $tutorId: $e');
      return null;
    }
  }

  // ---------------- Subject Resolution ----------------
  Future<Subject?> _resolveSubject(TutoringSession session) async {
    final subjectId = _sessionSubjectMap[session.id];
    if (subjectId == null || subjectId.isEmpty) return null;

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
      debugPrint('❌ _resolveSubject failed for $subjectId: $e');
      return null;
    }
  }

  // ---------------- Hydration ----------------
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

  // ---------------- Cache Warming ----------------
  void warmTutorCache(Tutor tutor) {
    _tutorCache[tutor.id] = tutor;
  }

  /// Called by SessionCreationController after a new session is saved so the
  /// subject map is immediately correct without a full reload.
  void warmSessionSubjectMap(String sessionId, String subjectId) {
    _sessionSubjectMap[sessionId] = subjectId;
    debugPrint('🗺️  Warmed subject map: $sessionId → $subjectId');
  }

  // ---------------- Reactive Filtering ----------------
  void _applyFilters() {
    final selectedSubject = subjectController.selectedSubject.value;
    final query = searchQuery.value.toLowerCase();

    final filtered =
        allSessions.where((s) {
          // Use the GraphQL-sourced map as the authoritative subjectId.
          // s.subject?.id may be null (lazy load not resolved) but the map
          // was populated from AppSync before sessions were loaded.
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

  // ---------------- Update Search Query ----------------
  void updateSearch(String query) => searchQuery.value = query;

  // ---------------- Reset on Logout ----------------
  void _resetState() {
    allSessions.clear();
    filteredSessions.clear();
    featuredSessions.clear();
    popularSessions.clear();
    recentSessions.clear();
    subjectController.subjects.clear();
    isReady.value = false;
    searchQuery.value = '';
    _tutorCache.clear();
    _sessionSubjectMap.clear();
  }

  // ---------------- Public Getters ----------------
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
