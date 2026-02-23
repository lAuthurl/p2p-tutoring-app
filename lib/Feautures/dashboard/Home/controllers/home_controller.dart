import 'package:flutter/material.dart';
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
        debugPrint("⚠️ User not signed in. Startup halted.");
        return;
      }

      final user = userController.currentUser.value!;
      await _ensureUserExists(user);

      _ensureBookingController();
      await subjectController.fetchSubjects();
      await _loadSessions();

      debugPrint("🏠 HomeController fully ready for ${user.username}");
      isReady.value = true;
    } catch (e) {
      debugPrint('❌ HomeController startup error: $e');
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
      debugPrint('✅ User created in DataStore');
    } else {
      debugPrint('✅ User already exists');
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

    // Featured: only sessions with isFeatured = true
    featuredSessions.assignAll(sessions.where((s) => s.isFeatured ?? false));

    // Popular & Recent: assign all sessions (no slicing)
    popularSessions.assignAll(sessions);
    recentSessions.assignAll(sessions.reversed.toList());

    debugPrint(
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
    // Deduplicate by ID
    return {for (var s in all) s.id: s}.values.toList();
  }

  /// ---------------- Fetch All Sessions Without Limit ----------------
  Future<List<TutoringSession>> fetchAllSessions() async {
    try {
      final sessions = await Amplify.DataStore.query(TutoringSession.classType);
      final uniqueSessions = {for (var s in sessions) s.id: s}.values.toList();

      // Sort newest first
      uniqueSessions.sort((a, b) {
        final aTime =
            a.createdAt?.getDateTimeInUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.createdAt?.getDateTimeInUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      debugPrint('🔹 fetchAllSessions: total=${uniqueSessions.length}');
      return uniqueSessions;
    } catch (e) {
      debugPrint('❌ fetchAllSessions error: $e');
      return [];
    }
  }

  List<Subject> getFeaturedSubjects({int limit = 10}) {
    return subjectController.getFeaturedSubjects(limit: limit);
  }
}
