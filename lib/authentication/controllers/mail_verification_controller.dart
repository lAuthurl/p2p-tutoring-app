import 'dart:async';

import 'package:get/get.dart';

import '../../../../utils/constants/text_strings.dart';
import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../utils/popups/loaders.dart';

class MailVerificationController extends GetxController {
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    sendVerificationEmail();
    setTimerForAutoRedirect();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// -- Send OR Resend Email Verification
  Future<void> sendVerificationEmail() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.tOhSnap, message: e.toString());
    }
  }

  /// -- Set Timer to check if Verification Completed then Redirect
  void setTimerForAutoRedirect() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      AuthenticationRepository.instance.initializeCurrentUser();
      final user = AuthenticationRepository.instance.firebaseUser;
      if (user != null && user.emailVerified) {
        timer.cancel();
        AuthenticationRepository.instance.screenRedirect(user);
      }
    });
  }

  /// -- Manually Check if Verification Completed then Redirect
  void manuallyCheckEmailVerificationStatus() {
    AuthenticationRepository.instance.initializeCurrentUser();
    final user = AuthenticationRepository.instance.firebaseUser;
    if (user != null && user.emailVerified) {
      AuthenticationRepository.instance.screenRedirect(user);
    }
  }
}
