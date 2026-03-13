import 'package:get/get.dart';
import '../../../authentication/controllers/login_controller.dart';
import '../../../utils/popups/loaders.dart';

class GoogleAuthController extends GetxController {
  final isLoading = false.obs;

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // ✅ Delegate entirely to LoginController.googleSignIn()
      // This handles: Amplify sign-in, DataStore user save,
      // device token, notification, controller injection, and navigation.
      final loginController =
          Get.isRegistered<LoginController>()
              ? Get.find<LoginController>()
              : Get.put(LoginController(), permanent: true);

      await loginController.googleSignIn();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Login Failed',
        message: 'Google sign-in was cancelled or failed.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
