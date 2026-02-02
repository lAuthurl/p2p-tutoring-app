import 'package:p2p_tutoring_app/personalization/controllers/create_notification_controller.dart';
import 'package:p2p_tutoring_app/utils/popups/exports.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../utils/security/password_hash.dart';
import '../../../utils/local_storage/secure_storage_service.dart';

import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../data/services/notifications/notification_service.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../utils/constants/image_strings.dart';
import 'package:p2p_tutoring_app/personalization/screens/profile/profile_screen.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../routes/routes.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  /// TextField Controllers to get data from TextFields
  final hidePassword = true.obs;
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  /// Loader
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final isFacebookLoading = false.obs;

  final RxBool rememberMe = false.obs;

  @override
  void onInit() {
    // Load remembered credentials (email is stored in GetStorage; password is in secure storage)
    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    rememberMe.value = localStorage.read('REMEMBER_ME') ?? false;

    // Persist remember-me toggle immediately so it can be used on next app run
    ever<bool>(rememberMe, (val) {
      try {
        localStorage.write('REMEMBER_ME', val);
        if (!val) {
          localStorage.remove('REMEMBER_ME_EMAIL');
          // remove secure password when toggled off
          SecureStorageService.instance.delete('REMEMBER_ME_PASSWORD');
        }
      } catch (_) {}
    });

    // Load secure password asynchronously and attempt auto-login if requested
    _loadRememberedCredentials();

    super.onInit();
  }

  // Async helper to load password and trigger auto-login
  Future<void> _loadRememberedCredentials() async {
    try {
      final pwd = await SecureStorageService.instance.read(
        'REMEMBER_ME_PASSWORD',
      );
      if (pwd != null && pwd.isNotEmpty) {
        password.text = pwd;

        // If remember toggle is on and we have credentials, try to login automatically
        if (rememberMe.value && email.text.trim().isNotEmpty) {
          try {
            await AuthenticationRepository.instance.loginWithEmailAndPassword(
              email.text.trim(),
              pwd,
            );

            await AuthenticationRepository.instance
                .refreshCurrentUserNoRedirect();
            final token = await TNotificationService.getToken();
            try {
              final userController = Get.find<UserController>();
              await userController.updateUserRecordWithToken(token);
              await userController.fetchUserRecord();
            } catch (_) {}

            Get.offAllNamed(TRoutes.mainDashboard);
            return;
          } catch (_) {
            // Auto-login failed — leave fields populated so user can retry
          }
        }
      }
    } catch (_) {}
  }

  /// [EmailAndPasswordLogin]
  Future<void> emailAndPasswordLogin() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
        'Logging you in...',
        TImages.docerAnimation,
      );

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        // Attempt offline login using locally stored hashed credentials
        final storage = GetStorage();
        final offlineUsers =
            storage.read('offline_users') ?? <String, dynamic>{};
        final record = offlineUsers[email.text.trim()];
        if (record == null) {
          TFullScreenLoader.stopLoading();
          TLoaders.customToast(
            message: 'No Internet Connection and no offline account found',
          );
          return;
        }
        final hashed = hashPassword(password.text.trim());
        if (hashed == record['passwordHash']) {
          // Persist remember-me locally if requested
          if (rememberMe.value) {
            localStorage.write('REMEMBER_ME', true);
            localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
            // store password securely
            await SecureStorageService.instance.write(
              'REMEMBER_ME_PASSWORD',
              password.text.trim(),
            );
          }

          TFullScreenLoader.stopLoading();
          TLoaders.successSnackBar(
            title: 'Offline Login',
            message: 'Signed in locally',
          );
          Get.offAll(() => const ProfileScreen());
          return;
        } else {
          TFullScreenLoader.stopLoading();
          TLoaders.errorSnackBar(
            title: 'Login Failed',
            message: 'Invalid credentials for offline login',
          );
          return;
        }
      }

      // Form Validation (null-safe)
      final isValid = loginFormKey.currentState?.validate() ?? false;
      if (!isValid) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Login user using EMail & Password Authentication
      await AuthenticationRepository.instance.loginWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );

      // Refresh local user and update tokens/records
      await AuthenticationRepository.instance.refreshCurrentUserNoRedirect();
      final token = await TNotificationService.getToken();
      try {
        final userController = Get.find<UserController>();
        await userController.updateUserRecordWithToken(token);
        // Assign user data to RxUser of UserController to use in app
        await userController.fetchUserRecord();
      } catch (_) {
        // UserController not registered or failed; skip profile update
      }

      // Persist 'remember me' if checked
      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME', true);
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        await SecureStorageService.instance.write(
          'REMEMBER_ME_PASSWORD',
          password.text.trim(),
        );
      } else {
        localStorage.remove('REMEMBER_ME');
        localStorage.remove('REMEMBER_ME_EMAIL');
        await SecureStorageService.instance.delete('REMEMBER_ME_PASSWORD');
      }

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Navigate to user profiles page after successful login
      Get.offAllNamed(TRoutes.mainDashboard);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }

  /// [GoogleSignInAuthentication]
  Future<void> googleSignIn() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
        'Logging you in...',
        TImages.docerAnimation,
      );

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Sign In with Google
      final userCredentials =
          await AuthenticationRepository.instance.signInWithGoogle();

      final userController = Get.find<UserController>();
      // Save Authenticated user data in the Firebase Firestore
      await userController.saveUserRecord(userCredentials: userCredentials);

      Get.find<CreateNotificationController>();
      await CreateNotificationController.instance.createNotification();

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Redirect to User Profiles screen after successful Google sign-in
      Get.offAllNamed(TRoutes.mainDashboard);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }
}
