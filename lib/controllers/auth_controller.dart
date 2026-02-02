import 'package:get/get.dart';

class AuthController extends GetxController {
  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return email == 'test@example.com' && password == 'password';
  }
}
