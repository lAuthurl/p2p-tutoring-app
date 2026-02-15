import 'dart:math';
import 'package:get/get.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/ModelProvider.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../Booking/controllers/booking_controller.dart';
import 'subject_controller.dart';

class HomeController extends GetxController {
  // ---------------- Singleton ----------------
  static HomeController get instance => Get.find<HomeController>();

  // ---------------- Controllers ----------------
  final UserController userController = Get.find<UserController>();
  final SubjectController subjectController = Get.find<SubjectController>();

  // ---------------- State ----------------
  final isReady = false.obs;
  final isLoading = false.obs;

  // ---------------- Carousel ----------------
  final carouselCurrentIndex = 0.obs;
  void updatePageIndicator(int index) => carouselCurrentIndex.value = index;

  // ---------------- Sessions ----------------
  final RxList<TutoringSession> featuredSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> popularSessions = <TutoringSession>[].obs;
  final RxList<TutoringSession> recentSessions = <TutoringSession>[].obs;

  // ---------------- Lifecycle ----------------
  @override
  void onReady() {
    super.onReady();

    // React to login/logout
    ever<User?>(userController.currentUser, (user) async {
      if (user != null) {
        await _startAfterLogin();
      } else {
        _clearData();
      }
    });

    // Trigger startup if already logged in
    if (userController.currentUser.value != null) {
      _startAfterLogin();
    }
  }

  // ---------------- After Login ----------------
  Future<void> _startAfterLogin() async {
    if (isReady.value || isLoading.value) return;

    isLoading.value = true;

    try {
      // Ensure user is signed in
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        isReady.value = true;
        return;
      }

      // Make sure BookingController is registered
      if (!Get.isRegistered<BookingController>()) {
        Get.put(BookingController(), permanent: true);
      }

      // ---------------- Safe user creation ----------------
      final currentUser = userController.currentUser.value!;
      final existingUsers = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(currentUser.id),
      );

      if (existingUsers.isEmpty) {
        await Amplify.DataStore.save(currentUser);
        print('✅ New user created in DataStore');
      } else {
        print('✅ User already exists, skipping creation');
      }

      // Fetch subjects and sessions
      await fetchSubjects();
      await fetchSessions();

      print("🏠 HomeController ready for user ${currentUser.username}");
    } catch (e) {
      print('❌ Error in HomeController startup: $e');
    } finally {
      isReady.value = true;
      isLoading.value = false;
    }
  }

  // ---------------- Clear on Logout ----------------
  void _clearData() {
    featuredSessions.clear();
    popularSessions.clear();
    recentSessions.clear();
    isReady.value = false;
  }

  // ---------------- Featured Subjects ----------------
  List<Subject> getFeaturedSubjects({int limit = 8}) {
    final subjects =
        subjectController.subjects.where((s) => s.isFeatured ?? false).toList();
    return subjects.length <= limit ? subjects : subjects.sublist(0, limit);
  }

  // ---------------- Get Sessions ----------------
  List<TutoringSession> getFeaturedSessions() => featuredSessions.toList();

  List<TutoringSession> getAllSessions() {
    final all = [...featuredSessions, ...popularSessions, ...recentSessions];
    final unique = {for (var s in all) s.id: s}.values.toList();
    return unique;
  }

  // ---------------- Fetch Subjects ----------------
  Future<void> fetchSubjects() async {
    try {
      final subjects = await Amplify.DataStore.query(Subject.classType);
      subjectController.subjects.assignAll(subjects);
      print('✅ Subjects loaded: ${subjects.length}');
    } catch (e) {
      print('❌ Error fetching subjects: $e');
    }
  }

  // ---------------- Fetch Sessions ----------------
  Future<void> fetchSessions() async {
    try {
      final sessions = await Amplify.DataStore.query(TutoringSession.classType);
      if (sessions.isEmpty) return;

      // Featured sessions
      final featured = sessions.where((s) => s.isFeatured ?? false).toList();
      featuredSessions.assignAll(featured);

      // Popular sessions: last 4 sessions
      final startPopular = max(0, sessions.length - 4);
      popularSessions.assignAll(sessions.sublist(startPopular));

      // Recent sessions: last 4 sessions reversed
      final startRecent = max(0, sessions.length - 4);
      recentSessions.assignAll(sessions.sublist(startRecent).reversed.toList());

      print(
        '🔹 Sessions loaded: total=${sessions.length}, featured=${featuredSessions.length}, popular=${popularSessions.length}, recent=${recentSessions.length}',
      );
    } catch (e) {
      print('❌ Error fetching sessions: $e');
    }
  }
}
