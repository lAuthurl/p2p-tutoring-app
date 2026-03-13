import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../data/models/app_user.dart';

class GoogleAuthService {
  /// Signs in with Google via Amplify's hosted UI.
  /// Returns an [AppUserCredential] on success, throws on failure.
  static Future<AppUserCredential> signInWithGoogle() async {
    try {
      await Amplify.Auth.signInWithWebUI(provider: AuthProvider.google);

      final authUser = await Amplify.Auth.getCurrentUser();
      final appUser = AppUser(uid: authUser.userId, email: authUser.username);

      return AppUserCredential(user: appUser);
    } on AmplifyException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Google sign-in failed. Please try again.';
    }
  }
}
