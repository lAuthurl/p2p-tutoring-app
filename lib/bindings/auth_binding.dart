import 'package:get/get.dart';
import '../authentication/controllers/google_auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(GoogleAuthController());
  }
}
