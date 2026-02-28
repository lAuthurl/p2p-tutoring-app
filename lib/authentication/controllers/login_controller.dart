// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../routes/routes.dart';
import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../personalization/controllers/create_notification_controller.dart';
import '../../../models/ModelProvider.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/local_storage/secure_storage_service.dart';
import '../../../utils/popups/exports.dart';
import '../../../utils/constants/image_strings.dart';
import '../../Feautures/Booking/controllers/booking_controller.dart';
import '../../Feautures/dashboard/Home/controllers/home_controller.dart';
import '../../Feautures/dashboard/Home/controllers/subject_controller.dart';
import '../../data/services/notifications/notification_service.dart';
import '../../../utils/constants/enums.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // ---------------- STATE ----------------
  final hidePassword = true.obs;
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;

  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  final rememberMe = false.obs;
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  bool _isNavigating = false;

  // ---------------- INIT ----------------
  @override
  void onInit() {
    super.onInit();

    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    rememberMe.value = localStorage.read('REMEMBER_ME') ?? false;

    ever<bool>(rememberMe, (val) async {
      localStorage.write('REMEMBER_ME', val);
      if (!val) {
        localStorage.remove('REMEMBER_ME_EMAIL');
        await SecureStorageService.instance.delete('REMEMBER_ME_PASSWORD');
      }
    });

    _autoLogin();
  }

  // =========================================================
  // AUTO LOGIN (NO NAVIGATION HERE)
  // =========================================================

  Future<void> _autoLogin() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();

      if (!session.isSignedIn) return;

      print('✔️ Auto-login: user is already signed in');

      await _prepareUserSession();

      _goToDashboard();
    } catch (e) {
      print('⚠️ Auto-login skipped: $e');
    }
  }

  // =========================================================
  // MAIN LOGIN
  // =========================================================

  Future<void> emailAndPasswordLogin() async {
    try {
      isLoading.value = true;

      TFullScreenLoader.openLoadingDialog(
        'Logging you in...',
        TImages.docerAnimation,
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        _stopLoading();
        TLoaders.customToast(message: 'No Internet connection.');
        return;
      }

      if (!loginFormKey.currentState!.validate()) {
        _stopLoading();
        return;
      }

      await AuthenticationRepository.instance.loginWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );

      await _prepareUserSession();

      _persistRememberMe();

      _stopLoading();

      _goToDashboard();
    } catch (e) {
      _stopLoading();
      TLoaders.errorSnackBar(title: 'Login Failed', message: e.toString());
    }
  }

  // =========================================================
  // GOOGLE LOGIN
  // =========================================================

  Future<void> googleSignIn() async {
    try {
      isGoogleLoading.value = true;

      TFullScreenLoader.openLoadingDialog(
        'Logging you in...',
        TImages.docerAnimation,
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        _stopLoading();
        return;
      }

      final credentials =
          await AuthenticationRepository.instance.signInWithGoogle();

      if (credentials?.user == null) {
        throw Exception('Google user data not available');
      }

      await _prepareUserSession(googleUser: credentials!.user);

      await CreateNotificationController.instance.createNotification();

      _stopLoading();

      _goToDashboard();
    } catch (e) {
      _stopLoading();
      TLoaders.errorSnackBar(title: 'Login Failed', message: e.toString());
    }
  }

  // =========================================================
  // PREPARE USER SESSION (NO NAVIGATION HERE)
  // =========================================================

  Future<void> _prepareUserSession({dynamic googleUser}) async {
    final authUser = await Amplify.Auth.getCurrentUser();

    final users = await Amplify.DataStore.query(
      User.classType,
      where: User.ID.eq(authUser.userId),
    );

    final token = await TNotificationService.getToken();

    late User currentUser;

    if (users.isNotEmpty) {
      final existing = users.first;

      currentUser = existing.copyWith(
        username: googleUser?.displayName ?? existing.username,
        email: googleUser?.email ?? existing.email,
        profilePicture: googleUser?.photoURL ?? existing.profilePicture,
        deviceToken: token,
        updatedAt: TemporalDateTime.now(),
      );
    } else {
      currentUser = User(
        id: authUser.userId,
        username: googleUser?.displayName ?? authUser.username,
        email: googleUser?.email ?? authUser.username,
        profilePicture: googleUser?.photoURL ?? '',
        deviceToken: token,
        createdAt: TemporalDateTime.now(),
        updatedAt: TemporalDateTime.now(),
        role: AppRole.user.name,
        verificationStatus: VerificationStatus.approved.name,
      );
    }

    await Amplify.DataStore.save(currentUser);

    _injectControllers(currentUser);
  }

  // =========================================================
  // CONTROLLER INJECTION
  // =========================================================

  void _injectControllers(User user) {
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }

    if (!Get.isRegistered<SubjectController>()) {
      Get.put(SubjectController(), permanent: true);
    }

    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController(), permanent: true);
    }

    if (!Get.isRegistered<BookingController>()) {
      Get.put(BookingController(), permanent: true);
    }

    UserController.instance.currentUser.value = user;
  }

  // =========================================================
  // NAVIGATION (ONLY HERE)
  // =========================================================

  void _goToDashboard() {
    if (_isNavigating) return;

    _isNavigating = true;

    if (Get.currentRoute != TRoutes.mainDashboard) {
      Get.offAllNamed(TRoutes.mainDashboard);
    }

    _isNavigating = false;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  void _persistRememberMe() async {
    if (rememberMe.value) {
      localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
      await SecureStorageService.instance.write(
        'REMEMBER_ME_PASSWORD',
        password.text.trim(),
      );
    } else {
      localStorage.remove('REMEMBER_ME_EMAIL');
      await SecureStorageService.instance.delete('REMEMBER_ME_PASSWORD');
    }
  }

  void _stopLoading() {
    TFullScreenLoader.stopLoading();
    isLoading.value = false;
    isGoogleLoading.value = false;
  }
}
