import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';
import '../../../Feautures/favourites/controllers/favorites_controller.dart';
import '../../../Feautures/sessions/controllers/tutoring_controller.dart';
import '../../../bindings/app_bindings.dart';
import '../../../data/models/app_user.dart';
import '../../../routes/routes.dart';
import '../../../authentication/screens/login/login_screen.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../../../utils/local_storage/storage_utility.dart';
import '../../../utils/security/password_hash.dart';
import '../../../utils/local_storage/secure_storage_service.dart';
import '../user_repository/user_repository.dart';
import '../../../Feautures/booking/controllers/booking_controller.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final deviceStorage = GetStorage();
  late final Rx<AppUser?> _currentUser;

  var phoneNo = ''.obs;
  var phoneNoVerificationId = ''.obs;
  var isPhoneAutoVerified = false;

  AppUser? get currentUser => _currentUser.value;
  AppUser? get firebaseUser => _currentUser.value;
  String get getUserID => currentUser?.uid ?? '';
  String get getUserEmail => currentUser?.email ?? '';
  String get getDisplayName => currentUser?.displayName ?? '';
  String get getPhoneNo => currentUser?.phoneNumber ?? '';

  static const _kIsFirstTime = 'isFirstTime';
  static const _kRememberMe = 'REMEMBER_ME';

  bool _startupNavigationDone = false;
  bool get startupNavigationDone => _startupNavigationDone;

  bool get _isFirstTime {
    final val = deviceStorage.read<bool>(_kIsFirstTime);
    return val != false;
  }

  bool get _rememberMe {
    final val = deviceStorage.read<bool>(_kRememberMe);
    return val ?? true;
  }

  void markOnboardingComplete() {
    deviceStorage.write(_kIsFirstTime, false);
  }

  @override
  void onReady() {
    _currentUser = Rx<AppUser?>(null);
    initializeCurrentUser();
  }

  Future<bool> isSignedIn() async {
    try {
      final res = await Amplify.Auth.getCurrentUser();
      return res.userId.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // CLEAR ALL USER STATE ON LOGOUT
  // =========================================================

  void _clearAllUserState() {
    if (Get.isRegistered<TutoringController>()) {
      TutoringController.instance.clearSessionState();
    }
    if (Get.isRegistered<FavoritesController>()) {
      FavoritesController.instance.clearOnLogout();
    }
    if (Get.isRegistered<BookingController>()) {
      BookingController.instance.clearOnLogout();
    }
  }

  // =========================================================
  // RELOAD USER CONTROLLERS AFTER LOGIN
  // =========================================================

  Future<void> _reloadUserControllers() async {
    final favCtrl =
        Get.isRegistered<FavoritesController>()
            ? FavoritesController.instance
            : Get.put(FavoritesController(), permanent: true);

    final futures = <Future>[favCtrl.reloadForUser()];
    if (Get.isRegistered<BookingController>()) {
      futures.add(BookingController.instance.reloadForUser());
    }
    await Future.wait(futures);
  }

  // =========================================================
  // INITIALIZE CURRENT USER
  // Stays on splash until fully resolved — no login flash
  // =========================================================

  Future<void> initializeCurrentUser() async {
    // Remember Me off — go straight to login, never onboarding
    if (!_rememberMe) {
      try {
        await Amplify.Auth.signOut();
      } catch (_) {}
      _currentUser.value = null;
      _startupNavigationDone = true;
      Get.offAllNamed(TRoutes.logIn);
      return;
    }

    // Stay on splash — collect result before any navigation
    AppUser? resolvedUser;

    try {
      final authUser = await Amplify.Auth.getCurrentUser();

      bool emailVerified = false;
      try {
        final attrs = await Amplify.Auth.fetchUserAttributes();
        for (final a in attrs) {
          if (a.userAttributeKey.key == 'email_verified' &&
              a.value.toLowerCase() == 'true') {
            emailVerified = true;
            break;
          }
        }
      } catch (_) {}

      final appUser = AppUser(
        uid: authUser.userId,
        email: authUser.username,
        emailVerified: emailVerified,
      );
      _currentUser.value = appUser;

      if (await isSignedIn()) {
        await UserController.instance.loadUserData();
        await _reloadUserControllers();
      }

      resolvedUser = _currentUser.value;
    } catch (_) {
      // Try remembered credentials
      try {
        final bool remember =
            (deviceStorage.read('REMEMBER_ME') as bool?) ?? false;
        final email = deviceStorage.read('REMEMBER_ME_EMAIL') ?? '';
        final password =
            await SecureStorageService.instance.read('REMEMBER_ME_PASSWORD') ??
            '';

        if (remember && email.isNotEmpty && password.isNotEmpty) {
          try {
            final cred = await loginWithEmailAndPassword(email, password);
            _currentUser.value = cred.user;
            resolvedUser = cred.user;
          } catch (_) {
            try {
              final storage = GetStorage();
              final offlineUsers =
                  storage.read('offline_users') ?? <String, dynamic>{};
              final record = offlineUsers[email.trim()];
              if (record != null) {
                final hashed = hashPassword(password.trim());
                if (hashed == record['passwordHash']) {
                  final appUser = AppUser(
                    uid: email.trim(),
                    email: email.trim(),
                  );
                  _currentUser.value = appUser;
                  resolvedUser = appUser;
                }
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    // ONE navigation call after everything is resolved
    _doStartupNavigate(resolvedUser);
  }

  // ── Single guarded navigation call for startup ───────────────────────────
  void _doStartupNavigate(AppUser? user) {
    _startupNavigationDone = true;
    screenRedirect(user);
  }

  // =========================================================
  // SCREEN REDIRECT
  // =========================================================

  Future<void> screenRedirect(AppUser? user) async {
    if (user != null) {
      // ✅ Signed in — always go to dashboard, never onboarding
      deviceStorage.write(_kIsFirstTime, false);

      try {
        await TLocalStorage.init(user.uid);
      } catch (_) {}

      try {
        if (Get.isRegistered<UserController>()) {
          await UserController.instance.fetchUserRecord(
            showErrorSnackBar: false,
          );
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

      if (Get.currentRoute != TRoutes.mainDashboard) {
        Get.offAllNamed(TRoutes.mainDashboard);
      }
    } else {
      // ✅ Not signed in
      if (_isFirstTime) {
        // Fresh install, never logged in — show onboarding
        Get.offAllNamed(TRoutes.onboarding);
      } else {
        // Has used the app before but not signed in — go to login
        Get.offAllNamed(TRoutes.logIn);
      }
    }
  }

  // =========================================================
  // ON LOGIN SUCCESS
  // =========================================================

  Future<void> onLoginSuccess() async {
    await Amplify.DataStore.start();
    AppBindings().dependencies();
    await _reloadUserControllers();
    Get.offAllNamed(TRoutes.mainDashboard);
  }

  // =========================================================
  // EMAIL + PASSWORD LOGIN
  // =========================================================

  Future<AppUserCredential> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
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
      } catch (_) {}

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

  Future<void> reAuthenticateWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
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

  // =========================================================
  // REGISTER
  // =========================================================

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

  Future<void> sendEmailVerification() async {}

  Future<void> confirmSignUp(String username, String confirmationCode) async {
    final uname = username.trim();
    final code = confirmationCode.trim();
    if (uname.isEmpty) throw 'Username is required to confirm verification.';
    if (code.isEmpty) throw 'Confirmation code is required.';
    try {
      final res = await Amplify.Auth.confirmSignUp(
        username: uname,
        confirmationCode: code,
      );
      if (res.isSignUpComplete) await refreshCurrentUserNoRedirect();
    } on AmplifyException catch (e) {
      throw e.message;
    } catch (_) {
      throw 'Failed to confirm sign up';
    }
  }

  Future<void> resendConfirmationCode(String username) async {
    final uname = username.trim();
    if (uname.isEmpty) {
      throw 'Username is required to resend confirmation code.';
    }
    try {
      await Amplify.Auth.resendSignUpCode(username: uname);
    } on AmplifyException catch (e) {
      throw e.message;
    } catch (_) {
      throw 'Failed to resend confirmation code';
    }
  }

  Future<void> resetPasswordStart(String username) async {
    try {
      await Amplify.Auth.resetPassword(username: username);
    } on AmplifyException catch (e) {
      throw e.message;
    } catch (_) {
      throw 'Failed to initiate password reset';
    }
  }

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

  Future<AppUserCredential?> signInWithGoogle() async {
    try {
      await Amplify.Auth.signInWithWebUI(provider: AuthProvider.google);
      final authUser = await Amplify.Auth.getCurrentUser();
      final appUser = AppUser(uid: authUser.userId, email: authUser.username);
      _currentUser.value = appUser;
      await _reloadUserControllers();
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

  Future<void> loginWithPhoneNo(String phoneNumber) async {
    throw 'Phone authentication not implemented for Amplify/Cognito.';
  }

  Future<bool> verifyOTP(String otp) async {
    throw 'Phone OTP verification not supported yet.';
  }

  // =========================================================
  // REFRESH CURRENT USER (no navigation)
  // =========================================================

  Future<AppUser?> refreshCurrentUserNoRedirect() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      bool emailVerified = false;
      try {
        final attrs = await Amplify.Auth.fetchUserAttributes();
        for (final a in attrs) {
          if (a.userAttributeKey.key == 'email_verified' &&
              a.value.toLowerCase() == 'true') {
            emailVerified = true;
            break;
          }
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

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    try {
      _clearAllUserState();
      await Amplify.Auth.signOut();
      try {
        await deviceStorage.remove('REMEMBER_ME');
        await deviceStorage.remove('REMEMBER_ME_EMAIL');
        await deviceStorage.remove('REMEMBER_ME_USERNAME');
        await SecureStorageService.instance.delete('REMEMBER_ME_PASSWORD');
        await deviceStorage.write(_kIsFirstTime, false);
      } catch (_) {}
      _startupNavigationDone = false;
      Get.offAllNamed(TRoutes.logIn);
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> logoutSilent() async {
    _clearAllUserState();
    try {
      await Amplify.Auth.signOut();
    } catch (_) {}
    try {
      await deviceStorage.erase();
      await deviceStorage.write(_kIsFirstTime, false);
    } catch (_) {}
    try {
      await GetStorage().erase();
    } catch (_) {}
    _currentUser.value = null;
    _startupNavigationDone = false;
  }

  Future<void> signOutNoClear() async {
    try {
      await Amplify.Auth.signOut();
    } catch (_) {}
    _currentUser.value = null;
  }

  Future<void> deleteAccount() async {
    try {
      _clearAllUserState();
      await UserRepository.instance.removeUserRecord(getUserID);
      await Amplify.Auth.signOut();
      await deviceStorage.write(_kIsFirstTime, false);
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> clearExistingUsers() async {
    try {
      _clearAllUserState();
      await deviceStorage.erase();
      await GetStorage().erase();
      await deviceStorage.write(_kIsFirstTime, false);
      await UserRepository.instance.clearAllUsers();
      _currentUser.value = null;
      Get.offAll(() => LoginScreen());
    } catch (_) {
      throw 'Failed to clear local data';
    }
  }
}

class CognitoSignUpOptions {}
