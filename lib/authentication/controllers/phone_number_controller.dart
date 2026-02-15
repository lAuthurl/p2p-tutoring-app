import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../data/services/notifications/notification_service.dart';
import '../../../personalization/controllers/create_notification_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../../models/ModelProvider.dart';

class SignInController extends GetxController {
  static SignInController get instance => Get.find();

  /// Variables
  final localStorage = GetStorage();
  final phone = TextEditingController();
  final selectedCountryCode = RxString('+225'); // Controller for country code
  GlobalKey<FormState> signInFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    phone.text = localStorage.read('REMEMBER_ME_PHONE') ?? '';
    super.onInit();
  }

  /// Method to handle login with phone number
  Future<void> loginWithPhoneNumber() async {
    try {
      if (selectedCountryCode.value.isEmpty) {
        TLoaders.customToast(message: TTexts.selectCountryCode);
        return;
      }

      if (!signInFormKey.currentState!.validate()) return;

      TFullScreenLoader.openLoadingDialog(
        "Authenticating...",
        TImages.docerAnimation,
      );

      if (!await _checkInternetConnectivity()) return;

      String formattedPhoneNumber = TFormatter.formatPhoneNumberWithCountryCode(
        selectedCountryCode.value,
        phone.text.trim(),
      );

      // Send OTP
      await AuthenticationRepository.instance.loginWithPhoneNo(
        formattedPhoneNumber,
      );

      // Redirect to OTP verification screen
      bool otpVerified = await Get.toNamed(
        TRoutes.otpVerification,
        parameters: {
          'phoneNumberWithCountryCode': formattedPhoneNumber,
          'phoneNumber': phone.text.trim(),
        },
      );

      if (!otpVerified) {
        TFullScreenLoader.stopLoading();
        return;
      }

      TLoaders.successSnackBar(
        title: TTexts.phoneVerifiedTitle,
        message: TTexts.phoneVerifiedMessage,
      );

      // Fetch the current Amplify user
      final authUser = await Amplify.Auth.getCurrentUser();
      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(authUser.userId),
      );

      final token = await TNotificationService.getToken();

      User userRecord;

      if (users.isNotEmpty) {
        // Update existing user with device token & timestamps
        final existing = users.first;
        userRecord = existing.copyWith(
          deviceToken: token,
          updatedAt: TemporalDateTime.now(),
        );
      } else {
        // Create new user record
        userRecord = User(
          id: authUser.userId,
          username: '',
          email: '',
          phoneNumber: formattedPhoneNumber,
          profilePicture: '',
          deviceToken: token,
          isEmailVerified: false,
          isProfileActive: false,
          createdAt: TemporalDateTime.now(),
          updatedAt: TemporalDateTime.now(),
          role: AppRole.user.name,
          verificationStatus: VerificationStatus.approved.name,
        );
      }

      // Save directly to Amplify
      await Amplify.DataStore.save(userRecord);

      // Assign user to UserController
      Get.find<UserController>().currentUser.value = userRecord;

      // Optionally create a welcome notification
      await CreateNotificationController.instance.createNotification();

      // Redirect to main dashboard
      TFullScreenLoader.stopLoading();
      await AuthenticationRepository.instance.screenRedirect(
        AuthenticationRepository.instance.firebaseUser,
      );
    } catch (e) {
      TFullScreenLoader.stopLoading();
      debugPrint('SignIn error: $e');
      _handleException(e);
    }
  }

  Future<bool> _checkInternetConnectivity() async {
    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: TTexts.noInternet.tr,
        message: TTexts.checkInternetConnection.tr,
      );
      return false;
    }
    return true;
  }

  void _handleException(Object e) {
    TFullScreenLoader.stopLoading();
    TLoaders.errorSnackBar(title: TTexts.ohSnap, message: e.toString());
  }
}
