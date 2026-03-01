// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../../models/ModelProvider.dart';
import '../../../../../personalization/controllers/user_controller.dart';
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

  // Filtered session lists
  final RxList<TutoringSession> featuredSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> popularSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> recentSessions = <TutoringSession>[].obs;

  // ---------------- Search ----------------
  final RxString searchQuery = ''.obs;
  final RxList<TutoringSession> filteredSessions = <TutoringSession>[].obs;

  // ---------------- Lifecycle ----------------
  @override
  void onInit() {
    super.onInit();

    userController = Get.find<UserController>();
    subjectController = Get.find<SubjectController>();

    // React to user login state
    ever<User?>(userController.currentUser, (user) {
      if (user != null) {
        _startAppFlow();
      } else {
        _resetState();
      }
    });

    // React to subject selection to filter sessions
    ever(subjectController.selectedSubject, (_) => _applyFilters());

    // React to sessions being loaded to populate filtered lists
    ever(allSessions, (_) => _applyFilters());

    // React to search query changes
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
      allSessions.assignAll(sessions);

      debugPrint('🔹 All sessions loaded: ${sessions.length}');
    } catch (e) {
      debugPrint('❌ Error loading sessions: $e');
      allSessions.clear();
    }
  }

  // ---------------- Reactive Filtering ----------------
  /// Filters sessions by selected subject and search query (title or tutor name)
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

    // Update other reactive session lists
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
