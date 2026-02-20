import 'dart:async';
import 'package:get/get.dart';
import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../authentication/controllers/login_controller.dart';
import '../../../routes/routes.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  Timer? _autoRedirectTimer;
  bool _initiallyVerified = false;

  @override
  void onInit() {
    super.onInit();
    _startVerificationFlow();
  }

  @override
  void onClose() {
    _autoRedirectTimer?.cancel();
    super.onClose();
  }

  /// Start the auto-verification and login flow
  Future<void> _startVerificationFlow() async {
    try {
      // Get initial verification status
      final user =
          await AuthenticationRepository.instance
              .refreshCurrentUserNoRedirect();
      _initiallyVerified = user?.emailVerified ?? false;
    } catch (_) {
      _initiallyVerified = false;
    }

    // Send verification email if needed
    await _sendEmailVerification();

    // Start periodic verification checks
    _startAutoRedirectTimer();
  }

  Future<void> _sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
    } catch (e) {
      print("Send Email Verification Failed: $e");
    }
  }

  void _startAutoRedirectTimer() {
    const checkInterval = Duration(seconds: 3);
    const maxChecks = 40; // ~2 minutes
    int checks = 0;

    _autoRedirectTimer = Timer.periodic(checkInterval, (timer) async {
      checks++;
      try {
        final user =
            await AuthenticationRepository.instance
                .refreshCurrentUserNoRedirect();
        final nowVerified = user?.emailVerified ?? false;

        if (nowVerified && !_initiallyVerified) {
          timer.cancel();
          await _autoLoginAfterVerification();
        }
      } catch (_) {}

      if (checks >= maxChecks) timer.cancel();
    });
  }

  /// Manually check email verification (e.g., on "Refresh" button)
  Future<void> checkEmailVerificationStatus() async {
    final user =
        await AuthenticationRepository.instance.refreshCurrentUserNoRedirect();
    if (user != null && user.emailVerified) {
      await _autoLoginAfterVerification();
    }
  }

  /// Confirm verification code from Cognito
  Future<void> confirmCode(String username, String code) async {
    final uname = username.trim();
    final confirmationCode = code.trim();
    if (uname.isEmpty || confirmationCode.isEmpty) return;

    try {
      await AuthenticationRepository.instance.confirmSignUp(
        uname,
        confirmationCode,
      );
      await _autoLoginAfterVerification();
    } catch (e) {
      print("Confirmation Failed: $e");
    }
  }

  /// Resend verification code
  Future<void> resendCode(String username) async {
    try {
      await AuthenticationRepository.instance.resendConfirmationCode(username);
    } catch (e) {
      print("Resend Code Failed: $e");
    }
  }

  /// Auto-login using remembered credentials
  Future<void> _autoLoginAfterVerification() async {
    try {
      final loginController = Get.find<LoginController>();

      final remember = loginController.rememberMe.value;
      final email = loginController.email.text.trim();
      final password = loginController.password.text;

      if (remember && email.isNotEmpty && password.isNotEmpty) {
        // Perform login
        await AuthenticationRepository.instance.loginWithEmailAndPassword(
          email,
          password,
        );
        Get.offAllNamed(TRoutes.home);
      } else {
        // Fallback to login screen
        Get.offAllNamed(TRoutes.logIn);
      }
    } catch (e) {
      print("Auto-login Failed: $e");
      Get.offAllNamed(TRoutes.logIn);
    }
  }

  /// Skip button action (immediate login)
  Future<void> skip() async {
    await _autoLoginAfterVerification();
  }
}
