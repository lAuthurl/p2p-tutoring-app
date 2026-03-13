// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../../screens/signup/verify_email.dart';
import '../../../utils/security/password_hash.dart';
import 'package:p2p_tutoring_app/personalization/screens/profile/profile_screen.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  final isGoogleLoading = false.obs;
  final isFacebookLoading = false.obs;
  final hidePassword = true.obs;
  final isLoading = false.obs;

  final username = TextEditingController();
  final fullName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phoneNumber = TextEditingController();

  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  // Held in memory — DataStore save happens AFTER email confirmation
  // using the real Cognito userId, not the email placeholder
  String _pendingEmail = '';
  String _pendingPassword = '';
  String _pendingUsername = '';
  String _pendingPhone = '';

  String get pendingEmail => _pendingEmail;
  String get pendingPassword => _pendingPassword;
  String get pendingUsername => _pendingUsername;
  String get pendingPhone => _pendingPhone;

  Future<void> signup() async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'We are processing your information...',
        TImages.docerAnimation,
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        final storage = GetStorage();
        final offlineUsers = storage.read('offline_users') ?? <String, Map>{};
        final hashed = hashPassword(password.text.trim());
        offlineUsers[email.text.trim()] = {
          'passwordHash': hashed,
          'username':
              username.text.trim().isNotEmpty
                  ? username.text.trim()
                  : fullName.text.trim(),
          'fullName': fullName.text.trim(),
          'phone': phoneNumber.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        };
        storage.write('offline_users', offlineUsers);
        TFullScreenLoader.stopLoading();
        TLoaders.successSnackBar(
          title: 'Offline',
          message: 'Account created locally. Connect to sync.',
        );
        Get.offAll(() => const ProfileScreen());
        return;
      }

      if (!signupFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Cache credentials — NO DataStore write here
      _pendingEmail = email.text.trim();
      _pendingPassword = password.text.trim();
      _pendingUsername =
          username.text.trim().isNotEmpty
              ? username.text.trim()
              : fullName.text.trim();
      _pendingPhone = phoneNumber.text.trim();

      // Only registers with Cognito — does NOT sign in
      await AuthenticationRepository.instance.registerWithEmailAndPassword(
        _pendingEmail,
        _pendingPassword,
      );

      TFullScreenLoader.stopLoading();

      TLoaders.successSnackBar(
        title: 'Congratulations',
        message: 'Your account has been created! Verify email to continue.',
      );

      Get.to(() => VerifyEmailScreen(email: _pendingEmail));
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  Future<void> loginWithPhoneNumber(String phoneNo) async {
    try {
      await AuthenticationRepository.instance.loginWithPhoneNo(phoneNo);
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void onClose() {
    username.dispose();
    fullName.dispose();
    email.dispose();
    password.dispose();
    phoneNumber.dispose();
    super.onClose();
  }
}
