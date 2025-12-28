import 'package:p2p_tutoring_app/personalization/controllers/create_notification_controller.dart';
import 'package:p2p_tutoring_app/utils/popups/exports.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../utils/security/password_hash.dart';

import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../data/services/notifications/notification_service.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../utils/constants/image_strings.dart';
import 'package:p2p_tutoring_app/screens/user_profiles/user_profiles_screen.dart';
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

  @override
  void onInit() {
    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    super.onInit();
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
          TFullScreenLoader.stopLoading();
          TLoaders.successSnackBar(
            title: 'Offline Login',
            message: 'Signed in locally',
          );
          Get.offAll(() => const UserProfilesScreen());
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

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Navigate to user profiles page after successful login
      Get.offAllNamed(TRoutes.coursesDashboard);
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
      Get.offAllNamed(TRoutes.coursesDashboard);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }
}
