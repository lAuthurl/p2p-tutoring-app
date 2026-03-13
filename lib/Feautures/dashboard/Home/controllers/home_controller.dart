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

  // ---------------- Tutor Cache ----------------
  // Shared with TutoringController pattern: query Tutor by FK id directly
  // rather than relying on v2 AsyncModel lazy resolution which fails after
  // a restart. Cache survives reactive rebuilds.
  final _tutorCache = <String, Tutor>{};

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

  // ---------------- Load All Sessions ----------------
  Future<void> _loadAllSessions() async {
    try {
      final sessions = await Amplify.DataStore.query(TutoringSession.classType);

      // ✅ FIX: Amplify v2 BelongsTo relations are lazy (AsyncModel).
      //    After a restart `await session.tutor` silently returns null
      //    because the relation hasn't been pulled into local SQLite yet.
      //
      //    The FK id (session.tutor?.id) is ALWAYS stored on the session
      //    row. We query Tutor by that id directly and cache the result
      //    so subsequent observeQuery cycles re-apply it from memory
      //    without hitting DataStore again.
      final hydrated = await _hydrateSessions(sessions);

      allSessions.assignAll(hydrated);
      debugPrint('🔹 Sessions loaded + hydrated: ${hydrated.length}');
    } catch (e) {
      debugPrint('❌ Error loading sessions: $e');
      allSessions.clear();
    }
  }

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

  // ---------------- Cache Warming ----------------
  /// Allows external controllers (e.g. SessionCreationController) to warm
  /// this cache without accessing the private _tutorCache field directly.
  void warmTutorCache(Tutor tutor) {
    _tutorCache[tutor.id] = tutor;
  }

  // ---------------- Reactive Filtering ----------------
  void _applyFilters() {
    final selectedSubject = subjectController.selectedSubject.value;
    final query = searchQuery.value.toLowerCase();

    final filtered =
        allSessions.where((s) {
          final matchesSubject =
              selectedSubject == null || s.subject?.id == selectedSubject.id;

          final matchesSearch =
              query.isEmpty ||
              (s.title.toLowerCase().contains(query)) ||
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
