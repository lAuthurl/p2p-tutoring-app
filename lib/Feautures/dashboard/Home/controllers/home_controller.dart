// ignore_for_file: avoid_print

import 'dart:math';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../../models/ModelProvider.dart';
import '../../../../../personalization/controllers/user_controller.dart';
import '../../../Booking/controllers/booking_controller.dart';
import '../controllers/subject_controller.dart';

class HomeController extends GetxController {
  static HomeController get instance => Get.find<HomeController>();

  // ---------------- Dependencies ----------------
  late final UserController userController;
  late final SubjectController subjectController;

  // ---------------- State ----------------
  final RxBool isReady = false.obs;
  final RxBool isLoading = false.obs;

  // ---------------- Sessions ----------------
  final RxList<TutoringSession> featuredSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> popularSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> recentSessions = <TutoringSession>[].obs;

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
  }

  @override
  void onReady() {
    super.onReady();

    if (userController.currentUser.value != null) {
      _startAppFlow();
    }
  }

  // ---------------- Main Startup Flow ----------------
  Future<void> _startAppFlow() async {
    if (isLoading.value || isReady.value) return;

    isLoading.value = true;
    isReady.value = false;

    try {
      final session = await Amplify.Auth.fetchAuthSession();

      if (!session.isSignedIn) {
        print("⚠️ Not signed in. Startup halted.");
        return;
      }

      final user = userController.currentUser.value!;
      await _ensureUserExists(user);

      _ensureBookingController();

      // ✅ Updated: use fetchSubjects()
      await subjectController.fetchSubjects();

      await _loadSessions();

      print("🏠 HomeController fully ready for ${user.username}");
      isReady.value = true;
    } catch (e) {
      print('❌ Startup error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- Ensure User Exists ----------------
  Future<void> _ensureUserExists(User user) async {
    final existing = await Amplify.DataStore.query(
      User.classType,
      where: User.ID.eq(user.id),
    );

    if (existing.isEmpty) {
      await Amplify.DataStore.save(user);
      print('✅ User created in DataStore');
    } else {
      print('✅ User already exists');
    }
  }

  // ---------------- BookingController ----------------
  void _ensureBookingController() {
    if (!Get.isRegistered<BookingController>()) {
      Get.put(BookingController(), permanent: true);
    }
  }

  // ---------------- Load Sessions ----------------
  Future<void> _loadSessions() async {
    final sessions = await Amplify.DataStore.query(TutoringSession.classType);

    if (sessions.isEmpty) {
      featuredSessions.clear();
      popularSessions.clear();
      recentSessions.clear();
      return;
    }

    featuredSessions.assignAll(sessions.where((s) => s.isFeatured ?? false));

    final start = max(0, sessions.length - 4);

    popularSessions.assignAll(sessions.sublist(start));

    recentSessions.assignAll(sessions.sublist(start).reversed.toList());

    print(
      '🔹 Sessions loaded: total=${sessions.length}, '
      'featured=${featuredSessions.length}, '
      'popular=${popularSessions.length}, '
      'recent=${recentSessions.length}',
    );
  }

  // ---------------- Clear on Logout ----------------
  void _resetState() {
    featuredSessions.clear();
    popularSessions.clear();
    recentSessions.clear();

    subjectController.subjects.clear();

    isReady.value = false;
  }

  // ---------------- Public Getters ----------------
  List<TutoringSession> getAllSessions() {
    final all = [...featuredSessions, ...popularSessions, ...recentSessions];

    return {for (var s in all) s.id: s}.values.toList();
  }

  List<Subject> getFeaturedSubjects({int limit = 10}) {
    return subjectController.getFeaturedSubjects(limit: limit);
  }
}
