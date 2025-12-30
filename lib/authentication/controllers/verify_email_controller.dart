import 'dart:async';

import 'package:get/get.dart';

import '../../../common/widgets/success_screen/success_screen.dart';
import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../routes/routes.dart';
import '../../../utils/popups/loaders.dart';
import '../../../screens/login/login_screen.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  @override
  void onInit() {
    /// Send Email Whenever Verify Screen appears & Set Timer for auto redirect.
    // Capture the initial verified state so we only redirect when verification
    // transitions from false -> true (prevents immediate redirect on load).
    _captureInitialVerificationStateAndStart();

    super.onInit();
  }

  bool _initiallyVerified = false;
  Timer? _autoRedirectTimer;

  Future<void> _captureInitialVerificationStateAndStart() async {
    try {
      final current =
          await AuthenticationRepository.instance
              .refreshCurrentUserNoRedirect();
      _initiallyVerified = current?.emailVerified ?? false;
    } catch (_) {
      _initiallyVerified = false;
    }
    await sendEmailVerification();
    setTimerForAutoRedirect();
  }

  /// Send Email Verification link
  Future<void> sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
      TLoaders.successSnackBar(
        title: 'Email Sent',
        message: 'Please Check your inbox and verify your email.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Timer to automatically redirect on Email Verification
  void setTimerForAutoRedirect() {
    // Check every 2 seconds for up to 2 minutes.
    const checkInterval = Duration(seconds: 2);
    const maxChecks = 60; // ~2 minutes
    int checks = 0;

    _autoRedirectTimer = Timer.periodic(checkInterval, (timer) async {
      checks++;
      try {
        final user =
            await AuthenticationRepository.instance
                .refreshCurrentUserNoRedirect();
        final nowVerified = user?.emailVerified ?? false;
        // Only redirect when verification transitioned from false -> true.
        if (nowVerified && !_initiallyVerified) {
          timer.cancel();
          Get.off(
            () => SuccessScreen(
              image: TImages.successfullyRegisterAnimation,
              title: TTexts.yourAccountCreatedTitle,
              subTitle: TTexts.yourAccountCreatedSubTitle,
              onPressed: () => Get.offAllNamed(TRoutes.profileScreen),
            ),
          );
        }
      } catch (_) {}

      if (checks >= maxChecks) {
        timer.cancel();
      }
    });
  }

  /// Manually Check if Email Verified
  Future<void> checkEmailVerificationStatus() async {
    await AuthenticationRepository.instance.refreshCurrentUserNoRedirect();
    final currentUser = AuthenticationRepository.instance.firebaseUser;
    if (currentUser != null && currentUser.emailVerified) {
      Get.off(
        () => SuccessScreen(
          image: TImages.successfullyRegisterAnimation,
          title: TTexts.yourAccountCreatedTitle,
          subTitle: TTexts.yourAccountCreatedSubTitle,
          onPressed: () => Get.offAllNamed(TRoutes.profileScreen),
        ),
      );
    }
  }

  /// Confirm an email verification code (from Cognito sign up)
  Future<void> confirmCode(String username, String code) async {
    final uname = username.trim();
    final confirmationCode = code.trim();
    if (uname.isEmpty) {
      TLoaders.errorSnackBar(
        title: 'Verification Failed',
        message: 'No username/email provided.',
      );
      return;
    }
    if (confirmationCode.isEmpty) {
      TLoaders.errorSnackBar(
        title: 'Verification Failed',
        message: 'Please enter the confirmation code.',
      );
      return;
    }

    try {
      await AuthenticationRepository.instance.confirmSignUp(
        uname,
        confirmationCode,
      );
      // Navigate to the success screen only after confirmation succeeds.
      Get.off(
        () => SuccessScreen(
          image: TImages.successfullyRegisterAnimation,
          title: TTexts.yourAccountCreatedTitle,
          subTitle: TTexts.yourAccountCreatedSubTitle,
          onPressed: () => Get.offAllNamed(TRoutes.profileScreen),
        ),
      );
      // also refresh verification status in background
      await checkEmailVerificationStatus();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Verification Failed',
        message: e.toString(),
      );
    }
  }

  /// Resend confirmation code (Cognito)
  Future<void> resendCode(String username) async {
    try {
      await AuthenticationRepository.instance.resendConfirmationCode(username);
      TLoaders.successSnackBar(
        title: 'Email Sent',
        message: 'Verification code resent. Please check your inbox.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Resend Failed', message: e.toString());
    }
  }

  /// Clear local users/storage
  Future<void> clearLocalUsers() async {
    try {
      await AuthenticationRepository.instance.clearExistingUsers();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: e.toString());
    }
  }
}
