import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../data/services/notifications/notification_service.dart';
import '../../../personalization/controllers/create_notification_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../personalization/models/user_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../../screens/signup/verify_email.dart';
import 'package:get_storage/get_storage.dart';
import '../../../utils/security/password_hash.dart';
import 'package:p2p_tutoring_app/screens/user_profiles/user_profiles_screen.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  final isGoogleLoading = false.obs;
  final isFacebookLoading = false.obs;

  // TextField Controllers to get data from TextFields

  final hidePassword = true.obs;
  final fullName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phoneNumber = TextEditingController();
  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  /// Loader
  final isLoading = false.obs;

  // As in the AuthenticationRepository we are calling _setScreen() Method
  // so, whenever there is change in the user state(), screen will be updated.
  // Therefore, when new user is authenticated, AuthenticationRepository() detects
  // the change and call _setScreen() to switch screens

  /// Register New User using either [EmailAndPassword] OR [PhoneNumber] authentication
  Future<void> signup() async {
    try {
      // Start Loading
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
        Get.offAll(() => const UserProfilesScreen());
        return;
      }

      // Form Validation
      if (!signupFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Register user in the Firebase Authentication & Save user data in the Firebase
      await AuthenticationRepository.instance.registerWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );

      final token = await TNotificationService.getToken();

      // Save Authenticated user data in the Firebase Firestore
      final newUser = UserModel(
        id: AuthenticationRepository.instance.getUserID,
        fullName: fullName.text.trim(),
        email: email.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        profilePicture: '',
        deviceToken: token,
        isEmailVerified: false,
        isProfileActive: false,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        verificationStatus: VerificationStatus.approved,
      );

      final userController = Get.find<UserController>();
      await userController.saveUserRecord(userData: newUser);

      Get.find<CreateNotificationController>();
      await CreateNotificationController.instance.createNotification();

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success Message
      TLoaders.successSnackBar(
        title: 'Congratulations',
        message: 'Your account has been created! Verify email to continue.',
      );

      // Move to Verify Email Screen
      Get.to(() => VerifyEmailScreen(email: email.text.trim()));
    } catch (e) {
      // Show some Generic Error to the user
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// [PhoneNoAuthentication]
  Future<void> loginWithPhoneNumber(String phoneNo) async {
    try {
      await AuthenticationRepository.instance.loginWithPhoneNo(phoneNo);
    } catch (e) {
      throw e.toString();
    }
  }
}
