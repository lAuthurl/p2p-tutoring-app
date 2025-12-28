import 'package:get/get.dart';
import '../../../data/services/auth/google_auth_service.dart';

class GoogleAuthController extends GetxController {
  final isLoading = false.obs;

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      await GoogleAuthService.signInWithGoogle();

      // Navigate after success
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        'Google sign-in was cancelled or failed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
