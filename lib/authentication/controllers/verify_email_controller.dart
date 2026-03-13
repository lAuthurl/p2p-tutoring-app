// ignore_for_file: avoid_print

import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:get/get.dart';

import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../authentication/controllers/login_controller.dart';
import '../../../authentication/controllers/signup_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../personalization/controllers/create_notification_controller.dart';
import '../../../data/services/notifications/notification_service.dart';
import '../../../models/ModelProvider.dart';
import '../../../utils/constants/enums.dart';
import '../../../routes/routes.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  Timer? _autoRedirectTimer;
  bool _initiallyVerified = false;
  bool _navigationComplete = false;

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

  // =========================================================
  // VERIFICATION FLOW
  // =========================================================

  Future<void> _startVerificationFlow() async {
    try {
      final user =
          await AuthenticationRepository.instance
              .refreshCurrentUserNoRedirect();
      _initiallyVerified = user?.emailVerified ?? false;
    } catch (_) {
      _initiallyVerified = false;
    }

    await _sendEmailVerification();
    _startAutoRedirectTimer();
  }

  Future<void> _sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
    } catch (e) {
      print('Send Email Verification Failed: $e');
    }
  }

  void _startAutoRedirectTimer() {
    const checkInterval = Duration(seconds: 3);
    const maxChecks = 40;
    int checks = 0;

    _autoRedirectTimer = Timer.periodic(checkInterval, (timer) async {
      if (_navigationComplete) {
        timer.cancel();
        return;
      }
      checks++;
      try {
        final user =
            await AuthenticationRepository.instance
                .refreshCurrentUserNoRedirect();
        final nowVerified = user?.emailVerified ?? false;

        if (nowVerified && !_initiallyVerified) {
          timer.cancel();
          await _completeSignUpAndLogin();
        }
      } catch (_) {}

      if (checks >= maxChecks) timer.cancel();
    });
  }

  // =========================================================
  // PUBLIC ACTIONS
  // =========================================================

  Future<void> checkEmailVerificationStatus() async {
    final user =
        await AuthenticationRepository.instance.refreshCurrentUserNoRedirect();
    if (user != null && user.emailVerified) {
      await _completeSignUpAndLogin();
    }
  }

  Future<void> confirmCode(String username, String code) async {
    final uname = username.trim();
    final confirmationCode = code.trim();
    if (uname.isEmpty || confirmationCode.isEmpty) return;

    try {
      await AuthenticationRepository.instance.confirmSignUp(
        uname,
        confirmationCode,
      );
      await _completeSignUpAndLogin();
    } catch (e) {
      print('Confirmation Failed: $e');
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> resendCode(String username) async {
    try {
      await AuthenticationRepository.instance.resendConfirmationCode(username);
      Get.snackbar('Sent', 'Verification code resent to $username');
    } catch (e) {
      print('Resend Code Failed: $e');
    }
  }

  Future<void> skip() async => _completeSignUpAndLogin();

  // =========================================================
  // CORE: sign in → real userId → save ONE DataStore record → navigate
  // =========================================================

  Future<void> _completeSignUpAndLogin() async {
    if (_navigationComplete) return;
    _navigationComplete = true;
    _autoRedirectTimer?.cancel();

    try {
      String email = '';
      String password = '';
      String pendingUsername = '';
      String pendingPhone = '';

      // Priority 1: fresh signup credentials still in memory
      if (Get.isRegistered<SignUpController>()) {
        final sc = Get.find<SignUpController>();
        email = sc.pendingEmail;
        password = sc.pendingPassword;
        pendingUsername = sc.pendingUsername;
        pendingPhone = sc.pendingPhone;
      }

      // Priority 2: remembered credentials from LoginController
      if ((email.isEmpty || password.isEmpty) &&
          Get.isRegistered<LoginController>()) {
        final lc = Get.find<LoginController>();
        if (email.isEmpty) email = lc.email.text.trim();
        if (password.isEmpty) password = lc.password.text.trim();
      }

      if (email.isEmpty || password.isEmpty) {
        Get.offAllNamed(TRoutes.logIn);
        return;
      }

      // Step 1: Sign in — get real Cognito userId
      await AuthenticationRepository.instance.loginWithEmailAndPassword(
        email,
        password,
      );

      // Step 2: Start DataStore with valid auth token
      await Amplify.DataStore.start();

      // Step 3: Get the real userId (UUID, not email)
      final authUser = await Amplify.Auth.getCurrentUser();
      final realUserId = authUser.userId;

      // Step 4: Null-safe device token
      String token = '';
      try {
        token = await TNotificationService.getToken() ?? ''; // ✅ null-safe
      } catch (_) {}

      // Step 5: Query by real userId first, then by email as fallback
      // to avoid duplicate records from sync race conditions
      User? existingUser;

      final byId = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(realUserId),
      );

      if (byId.isNotEmpty) {
        existingUser = byId.first;
      } else {
        // ✅ Fallback: check by email in case record was saved with wrong id
        final byEmail = await Amplify.DataStore.query(
          User.classType,
          where: User.EMAIL.eq(email),
        );
        if (byEmail.isNotEmpty) {
          existingUser = byEmail.first;
        }
      }

      late User userToSave;

      if (existingUser != null) {
        // Update existing record — preserve all profile data
        userToSave = existingUser.copyWith(
          username:
              pendingUsername.isNotEmpty
                  ? pendingUsername
                  : existingUser.username,
          phoneNumber:
              pendingPhone.isNotEmpty ? pendingPhone : existingUser.phoneNumber,
          isEmailVerified: true,
          deviceToken: token,
          updatedAt: TemporalDateTime.now(),
        );
      } else {
        // Create new record with REAL Cognito userId
        userToSave = User(
          id: realUserId,
          username: pendingUsername,
          email: email,
          phoneNumber: pendingPhone,
          profilePicture: '',
          deviceToken: token,
          isEmailVerified: true,
          isProfileActive: false,
          createdAt: TemporalDateTime.now(),
          updatedAt: TemporalDateTime.now(),
          role: AppRole.user.name,
          verificationStatus: VerificationStatus.approved.name,
        );
      }

      await Amplify.DataStore.save(userToSave);

      // Step 6: Inject controllers and populate profile
      if (!Get.isRegistered<UserController>()) {
        Get.put(UserController(), permanent: true);
      }
      UserController.instance.currentUser.value = userToSave;
      UserController.instance.assignDataToProfile();

      // Step 7: Welcome notification
      try {
        if (Get.isRegistered<CreateNotificationController>()) {
          await CreateNotificationController.instance.createNotification();
        }
      } catch (_) {}

      // Step 8: Navigate to dashboard
      Get.offAllNamed(TRoutes.mainDashboard);
    } catch (e) {
      print('_completeSignUpAndLogin failed: $e');
      _navigationComplete = false;
      Get.snackbar('Error', 'Login failed: ${e.toString()}');
      Get.offAllNamed(TRoutes.logIn);
    }
  }
}
