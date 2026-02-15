// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../data/services/notifications/notification_service.dart';
import '../../../personalization/controllers/create_notification_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../../screens/signup/verify_email.dart';
import '../../../utils/security/password_hash.dart';
import 'package:p2p_tutoring_app/personalization/screens/profile/profile_screen.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../models/ModelProvider.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  final isGoogleLoading = false.obs;
  final isFacebookLoading = false.obs;

  // TextField Controllers
  final hidePassword = true.obs;
  final fullName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phoneNumber = TextEditingController();
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  /// Loader
  final isLoading = false.obs;

  /// Register New User using Email & Password
  Future<void> signup() async {
    try {
      // Start Loader
      TFullScreenLoader.openLoadingDialog(
        'We are processing your information...',
        TImages.docerAnimation,
      );

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        // Offline signup: store credentials locally (hashed)
        final storage = GetStorage();
        final offlineUsers = storage.read('offline_users') ?? <String, Map>{};
        final hashed = hashPassword(password.text.trim());
        offlineUsers[email.text.trim()] = {
          'passwordHash': hashed,
          'fullName': fullName.text.trim(),
          'phone': phoneNumber.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        };
        storage.write('offline_users', offlineUsers);

        TFullScreenLoader.stopLoading();
        TLoaders.successSnackBar(
          title: 'Offline',
          message: 'Account created locally. Connect to the internet to sync.',
        );
        Get.offAll(() => const ProfileScreen());
        return;
      }

      // Form Validation
      if (!signupFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Register user in Firebase/Auth backend
      await AuthenticationRepository.instance.registerWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );

      final token = await TNotificationService.getToken();

      // Save user in Amplify DataStore
      final newUser = User(
        id: AuthenticationRepository.instance.getUserID,
        username: fullName.text.trim(),
        email: email.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        profilePicture: '',
        deviceToken: token,
        isEmailVerified: false,
        isProfileActive: false,
        createdAt: TemporalDateTime.now(),
        updatedAt: TemporalDateTime.now(),
        role: AppRole.user.name,
        verificationStatus: VerificationStatus.approved.name,
      );

      await Amplify.DataStore.save(newUser);

      // Update UserController
      final userController = Get.find<UserController>();
      userController.currentUser.value = newUser;

      // Create welcome notification
      Get.find<CreateNotificationController>();
      await CreateNotificationController.instance.createNotification();

      // Stop Loader
      TFullScreenLoader.stopLoading();

      // Show success
      TLoaders.successSnackBar(
        title: 'Congratulations',
        message: 'Your account has been created! Verify email to continue.',
      );

      // Navigate to Email Verification
      Get.to(() => VerifyEmailScreen(email: email.text.trim()));
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Login with Phone Number (optional)
  Future<void> loginWithPhoneNumber(String phoneNo) async {
    try {
      await AuthenticationRepository.instance.loginWithPhoneNo(phoneNo);
    } catch (e) {
      throw e.toString();
    }
  }
}
