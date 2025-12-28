import 'package:amplify_flutter/amplify_flutter.dart';

class GoogleAuthService {
  static Future<void> signInWithGoogle() async {
    try {
      await Amplify.Auth.signInWithWebUI(provider: AuthProvider.google);
    } on AuthException catch (e) {
      safePrint('Google Sign-In Error: ${e.message}');
      rethrow;
    }
  }
}
