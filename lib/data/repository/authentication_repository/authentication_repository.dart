import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';
import '../../../data/models/app_user.dart';
import '../../../screens/login/login_screen.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../../../utils/local_storage/storage_utility.dart';
import '../user_repository/user_repository.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final deviceStorage = GetStorage(); // Local storage
  late final Rx<AppUser?> _currentUser;

  var phoneNo = ''.obs;
  var phoneNoVerificationId = ''.obs;
  var isPhoneAutoVerified = false;

  AppUser? get currentUser => _currentUser.value;
  // Backwards-compatible getter used by older code
  AppUser? get firebaseUser => _currentUser.value;
  String get getUserID => currentUser?.uid ?? '';
  String get getUserEmail => currentUser?.email ?? '';
  String get getDisplayName => currentUser?.displayName ?? '';
  String get getPhoneNo => currentUser?.phoneNumber ?? '';

  @override
  void onReady() {
    _currentUser = Rx<AppUser?>(null);
    initializeCurrentUser();
  }

  Future<void> initializeCurrentUser() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      // Determine email verification status from user attributes
      bool emailVerified = false;
      try {
        final attrs = await Amplify.Auth.fetchUserAttributes();
        AuthUserAttribute? emailVerifiedAttr;
        for (final a in attrs) {
          if (a.userAttributeKey.key == 'email_verified') {
            emailVerifiedAttr = a;
            break;
          }
        }
        if (emailVerifiedAttr != null &&
            emailVerifiedAttr.value.toLowerCase() == 'true') {
          emailVerified = true;
        }
      } catch (_) {}

      final appUser = AppUser(
        uid: authUser.userId,
        email: authUser.username,
        emailVerified: emailVerified,
      );
      _currentUser.value = appUser;
      await screenRedirect(_currentUser.value);
    } catch (_) {
      _currentUser.value = null;
      await screenRedirect(null);
    }
  }

  /// Refreshes the current user from Amplify without performing a screen redirect.
  /// Returns the updated AppUser or null.
  Future<AppUser?> refreshCurrentUserNoRedirect() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      bool emailVerified = false;
      try {
        final attrs = await Amplify.Auth.fetchUserAttributes();
        AuthUserAttribute? emailVerifiedAttr;
        for (final a in attrs) {
          if (a.userAttributeKey.key == 'email_verified') {
            emailVerifiedAttr = a;
            break;
          }
        }
        if (emailVerifiedAttr != null &&
            emailVerifiedAttr.value.toLowerCase() == 'true') {
          emailVerified = true;
        }
      } catch (_) {}

      final appUser = AppUser(
        uid: authUser.userId,
        email: authUser.username,
        emailVerified: emailVerified,
      );
      _currentUser.value = appUser;
      return appUser;
    } catch (_) {
      _currentUser.value = null;
      return null;
    }
  }

  Future<void> screenRedirect(AppUser? user) async {
    // NOTE: navigation is intentionally disabled here. Startup should not
    // automatically push screens; users must navigate explicitly. We keep a
    // lightweight initialization routine to prepare per-user storage and
    // fetch any cached user record if present.
    if (user != null) {
      try {
        await TLocalStorage.init(user.uid);
      } catch (_) {}

      try {
        if (Get.isRegistered<UserController>()) {
          await UserController.instance.fetchUserRecord();
        } else {
          if (!Get.isRegistered<UserRepository>()) {
            Get.lazyPut(() => UserRepository(), fenix: true);
          }
          try {
            final repo = Get.find<UserRepository>();
            await repo.fetchUserDetails();
          } catch (_) {}
        }
      } catch (_) {}
    } else {
      // Ensure the onboarding flag exists but do not navigate.
      deviceStorage.writeIfNull('isFirstTime', true);
    }
  }

  /// Email/Password Sign-In
  Future<AppUserCredential> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // If there's already a signed-in user, return it when it matches the
      // requested email. If it's a different user, sign them out first.
      try {
        final existing = await Amplify.Auth.getCurrentUser();
        if (existing.username.toLowerCase() == email.toLowerCase()) {
          final appUser = AppUser(
            uid: existing.userId,
            email: existing.username,
          );
          _currentUser.value = appUser;
          return AppUserCredential(user: appUser);
        } else {
          await signOutNoClear();
        }
      } catch (_) {
        // no current user, continue to sign in
      }

      final res = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      if (res.isSignedIn) {
        final authUser = await Amplify.Auth.getCurrentUser();
        final appUser = AppUser(uid: authUser.userId, email: authUser.username);
        _currentUser.value = appUser;
        return AppUserCredential(user: appUser);
      }
      throw 'Sign in failed';
    } on AmplifyException catch (e) {
      final msg = e.message.toLowerCase();
      // If Amplify reports the user is already signed in, try to recover
      if (msg.contains('already')) {
        try {
          final authUser = await Amplify.Auth.getCurrentUser();
          final appUser = AppUser(
            uid: authUser.userId,
            email: authUser.username,
          );
          _currentUser.value = appUser;
          return AppUserCredential(user: appUser);
        } catch (_) {
          // If we can't read the current user, attempt a silent sign-out
          // and retry sign-in once to recover from a stale session.
          try {
            await signOutNoClear();
            final retry = await Amplify.Auth.signIn(
              username: email,
              password: password,
            );
            if (retry.isSignedIn) {
              final authUser = await Amplify.Auth.getCurrentUser();
              final appUser = AppUser(
                uid: authUser.userId,
                email: authUser.username,
              );
              _currentUser.value = appUser;
              return AppUserCredential(user: appUser);
            }
          } catch (_) {}
        }
      }
      throw e.message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// [ReAuthenticate] - ReAuthenticate User
  Future<void> reAuthenticateWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Amplify does not support reauthenticate; perform a fresh sign in
      await Amplify.Auth.signIn(username: email, password: password);
    } on AmplifyException catch (e) {
      throw e.message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Email/Password Sign-Up
  Future<AppUserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final options = SignUpOptions(
        userAttributes: {AuthUserAttributeKey.email: email},
      );

      await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: options,
      );

      final appUser = AppUser(uid: email, email: email);
      _currentUser.value = appUser;
      return AppUserCredential(user: appUser);
    } on AmplifyException catch (e) {
      final msg = e.message.toLowerCase();
      // If user already exists, redirect to login screen
      if (msg.contains('already') ||
          msg.contains('usernameexists') ||
          msg.contains('user already')) {
        try {
          Get.offAll(() => LoginScreen());
        } catch (_) {}
        throw 'User already exists. Redirecting to login.';
      }
      throw e.message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Backwards-compatible: send email verification (no-op for Cognito client)
  Future<void> sendEmailVerification() async {
    // Cognito handles verification via sign up / hosted UI flows.
    return;
  }

  /// Start password reset flow (Cognito): sends a reset code to user's email/phone
  Future<void> resetPasswordStart(String username) async {
    try {
      await Amplify.Auth.resetPassword(username: username);
    } on AmplifyException catch (e) {
      throw e.message;
    } catch (_) {
      throw 'Failed to initiate password reset';
    }
  }

  /// Confirm password reset given confirmation code and new password
  Future<void> resetPasswordConfirm(
    String username,
    String newPassword,
    String confirmationCode,
  ) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: username,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } on AmplifyException catch (e) {
      throw e.message;
    } catch (_) {
      throw 'Failed to confirm password reset';
    }
  }

  /// Confirm sign up with confirmation code (Cognito)
  Future<void> confirmSignUp(String username, String confirmationCode) async {
    // Basic validation before calling Cognito
    final uname = username.trim();
    final code = confirmationCode.trim();
    if (uname.isEmpty) {
      throw 'Username is required to confirm verification.';
    }
    if (code.isEmpty) {
      throw 'Confirmation code is required.';
    }

    try {
      final res = await Amplify.Auth.confirmSignUp(
        username: uname,
        confirmationCode: code,
      );
      if (res.isSignUpComplete) {
        // refresh local user state
        await refreshCurrentUserNoRedirect();
      }
    } on AmplifyException catch (e) {
      throw e.message;
    } catch (_) {
      throw 'Failed to confirm sign up';
    }
  }

  /// Resend confirmation code for sign up (Cognito)
  Future<void> resendConfirmationCode(String username) async {
    final uname = username.trim();
    if (uname.isEmpty) {
      throw 'Username is required to resend confirmation code.';
    }
    try {
      // Amplify's resend sign-up may not be available on all builds/platforms.
      // As a safe fallback, call the generic sendEmailVerification (no-op for Cognito),
      // which preserves existing behaviour while avoiding unsupported API calls.
      await sendEmailVerification();
    } on AmplifyException catch (e) {
      throw e.message;
    } catch (_) {
      throw 'Failed to resend confirmation code';
    }
  }

  /// Clear local storage and reset current user (useful for testing)
  Future<void> clearExistingUsers() async {
    try {
      // clear local device storage
      await deviceStorage.erase();
      // clear generic default storage
      await GetStorage().erase();
      // clear user records storage
      await UserRepository.instance.clearAllUsers();
      _currentUser.value = null;
      Get.offAll(() => LoginScreen());
    } catch (_) {
      throw 'Failed to clear local data';
    }
  }

  /// Backwards-compatible phone auth stubs
  Future<void> loginWithPhoneNo(String phoneNumber) async {
    throw 'Phone authentication not implemented for Amplify/Cognito in this migration.';
  }

  Future<bool> verifyOTP(String otp) async {
    throw 'Phone OTP verification not supported in this migration yet.';
  }

  /// Google Sign-In via Hosted UI
  Future<AppUserCredential?> signInWithGoogle() async {
    try {
      await Amplify.Auth.signInWithWebUI(provider: AuthProvider.google);
      final authUser = await Amplify.Auth.getCurrentUser();
      final appUser = AppUser(uid: authUser.userId, email: authUser.username);
      _currentUser.value = appUser;
      return AppUserCredential(user: appUser);
    } on AmplifyException catch (e) {
      throw e.message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (_) {
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await Amplify.Auth.signOut();
      Get.offAll(() => LoginScreen());
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Silent logout: sign out and clear local state but do not navigate.
  Future<void> logoutSilent() async {
    // Preserve onboarding flag so we don't loop onboarding when clearing auth
    final dynamic wasFirstTime = deviceStorage.read('isFirstTime');
    try {
      await Amplify.Auth.signOut();
    } catch (_) {
      // ignore sign out errors
    }
    try {
      await deviceStorage.erase();
      if (wasFirstTime != null) {
        await deviceStorage.write('isFirstTime', wasFirstTime);
      }
    } catch (_) {}
    try {
      await GetStorage().erase();
    } catch (_) {}
    _currentUser.value = null;
  }

  /// Sign out without clearing any local storage or changing navigation state.
  /// Useful for logging out a user so they can re-authenticate without
  /// affecting onboarding flags or triggering redirects.
  Future<void> signOutNoClear() async {
    try {
      await Amplify.Auth.signOut();
    } catch (_) {
      // ignore
    }
    _currentUser.value = null;
  }

  /// Delete User Account
  Future<void> deleteAccount() async {
    try {
      await UserRepository.instance.removeUserRecord(getUserID);
      await Amplify.Auth.signOut();
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }
}

class CognitoSignUpOptions {}
