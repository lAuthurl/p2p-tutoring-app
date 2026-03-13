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

  final username = TextEditingController();
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
    username.text = localStorage.read('REMEMBER_ME_USERNAME') ?? '';
    rememberMe.value = localStorage.read('REMEMBER_ME') ?? false;

    ever<bool>(rememberMe, (val) async {
      localStorage.write('REMEMBER_ME', val);
      if (!val) {
        localStorage.remove('REMEMBER_ME_EMAIL');
        localStorage.remove('REMEMBER_ME_USERNAME');
        await SecureStorageService.instance.delete('REMEMBER_ME_PASSWORD');
      }
    });

    _autoLogin();
  }

  // =========================================================
  // AUTO LOGIN
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

      final String loginIdentifier = await _resolveLoginIdentifier();

      if (loginIdentifier.isEmpty) {
        _stopLoading();
        TLoaders.errorSnackBar(
          title: 'Login Failed',
          message: 'No account found for that username or email.',
        );
        return;
      }

      await AuthenticationRepository.instance.loginWithEmailAndPassword(
        loginIdentifier,
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
  // RESOLVE LOGIN IDENTIFIER
  // Cognito uses email as username. If user typed display-username,
  // look up their email from DataStore.
  // =========================================================

  Future<String> _resolveLoginIdentifier() async {
    final emailInput = email.text.trim();
    final usernameInput = username.text.trim();

    if (emailInput.isNotEmpty) return emailInput;

    if (usernameInput.isNotEmpty) {
      try {
        final users = await Amplify.DataStore.query(
          User.classType,
          where: User.USERNAME.eq(usernameInput),
        );
        if (users.isNotEmpty) {
          return users.first.email ?? '';
        }
      } catch (e) {
        print('⚠️ Username lookup failed: $e');
      }
    }

    return '';
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
  // PREPARE USER SESSION
  // Queries by real userId first, falls back to email to prevent
  // duplicate records from DataStore sync race conditions.
  // =========================================================

  Future<void> _prepareUserSession({dynamic googleUser}) async {
    final authUser = await Amplify.Auth.getCurrentUser();

    // Null-safe token
    String token = '';
    try {
      token = await TNotificationService.getToken() ?? ''; // ✅ null-safe
    } catch (_) {}

    // Step 1: Try finding by real userId
    User? existingUser;

    final byId = await Amplify.DataStore.query(
      User.classType,
      where: User.ID.eq(authUser.userId),
    );

    if (byId.isNotEmpty) {
      existingUser = byId.first;
    } else {
      // ✅ Step 2: Fallback to email lookup — catches records saved with
      // wrong id (email placeholder) before confirmation was complete
      final lookupEmail =
          googleUser?.email ??
          (email.text.trim().isNotEmpty ? email.text.trim() : null);

      if (lookupEmail != null) {
        final byEmail = await Amplify.DataStore.query(
          User.classType,
          where: User.EMAIL.eq(lookupEmail),
        );
        if (byEmail.isNotEmpty) {
          existingUser = byEmail.first;
        }
      }
    }

    late User currentUser;

    if (existingUser != null) {
      // Update existing — preserve all profile data, only refresh mutable fields
      currentUser = existingUser.copyWith(
        username: googleUser?.displayName ?? existingUser.username,
        email: googleUser?.email ?? existingUser.email,
        profilePicture: googleUser?.photoURL ?? existingUser.profilePicture,
        deviceToken: token,
        updatedAt: TemporalDateTime.now(),
      );
    } else {
      // Truly new user (e.g. first-time Google sign-in)
      currentUser = User(
        id: authUser.userId,
        username:
            googleUser?.displayName ??
            (username.text.trim().isNotEmpty
                ? username.text.trim()
                : authUser.username),
        email:
            googleUser?.email ??
            (email.text.trim().isNotEmpty
                ? email.text.trim()
                : authUser.username),
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
  // NAVIGATION
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
      localStorage.write('REMEMBER_ME_USERNAME', username.text.trim());
      await SecureStorageService.instance.write(
        'REMEMBER_ME_PASSWORD',
        password.text.trim(),
      );
    } else {
      localStorage.remove('REMEMBER_ME_EMAIL');
      localStorage.remove('REMEMBER_ME_USERNAME');
      await SecureStorageService.instance.delete('REMEMBER_ME_PASSWORD');
    }
  }

  void _stopLoading() {
    TFullScreenLoader.stopLoading();
    isLoading.value = false;
    isGoogleLoading.value = false;
  }

  @override
  void onClose() {
    username.dispose();
    email.dispose();
    password.dispose();
    super.onClose();
  }
}
