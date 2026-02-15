import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../routes/routes.dart';
import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../personalization/controllers/create_notification_controller.dart';
import '../../../models/ModelProvider.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/local_storage/secure_storage_service.dart';
import '../../../utils/popups/exports.dart';
import '../../../utils/constants/image_strings.dart';
import '../../Feautures/Booking/controllers/booking_controller.dart';
import '../../Feautures/dashboard/Home/controllers/home_controller.dart';
import '../../Feautures/dashboard/Home/controllers/subject_controller.dart';
import '../../data/services/notifications/notification_service.dart';
import '../../../utils/constants/enums.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // ---------------- State ----------------
  final hidePassword = true.obs;
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;

  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  final rememberMe = false.obs;
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  // ---------------- Init ----------------
  @override
  void onInit() {
    super.onInit();

    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    rememberMe.value = localStorage.read('REMEMBER_ME') ?? false;

    ever<bool>(rememberMe, (val) async {
      localStorage.write('REMEMBER_ME', val);
      if (!val) {
        localStorage.remove('REMEMBER_ME_EMAIL');
        await SecureStorageService.instance.delete('REMEMBER_ME_PASSWORD');
      }
    });

    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final pwd = await SecureStorageService.instance.read(
        'REMEMBER_ME_PASSWORD',
      );
      if (pwd != null && pwd.isNotEmpty) {
        password.text = pwd;
        if (rememberMe.value && email.text.trim().isNotEmpty) {
          await emailAndPasswordLogin(autoLogin: true);
        }
      }
    } catch (_) {}
  }

  // ---------------- Post-Login Controller Init ----------------
  void _injectControllers(User user) {
    final userController = Get.put(UserController(), permanent: true);
    userController.currentUser.value = user;

    if (!Get.isRegistered<SubjectController>()) {
      Get.put(SubjectController(), permanent: true);
    }

    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController(), permanent: true);
    }

    if (!Get.isRegistered<BookingController>()) {
      Get.put(BookingController(currentUser: user), permanent: true);
    }
  }

  // ---------------- Email & Password Login ----------------
  Future<void> emailAndPasswordLogin({bool autoLogin = false}) async {
    try {
      isLoading.value = true;
      TFullScreenLoader.openLoadingDialog(
        'Logging you in...',
        TImages.docerAnimation,
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        isLoading.value = false;
        TLoaders.customToast(message: 'No Internet connection.');
        return;
      }

      if (!loginFormKey.currentState!.validate() && !autoLogin) {
        TFullScreenLoader.stopLoading();
        isLoading.value = false;
        return;
      }

      // Authenticate via Amplify
      await AuthenticationRepository.instance.loginWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );

      await AuthenticationRepository.instance.refreshCurrentUserNoRedirect();
      final authUser = await Amplify.Auth.getCurrentUser();

      // Load or create user record
      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(authUser.userId),
      );

      late User userRecord;
      if (users.isNotEmpty) {
        userRecord = users.first;
      } else {
        userRecord = User(
          id: authUser.userId,
          username: email.text.trim(),
          email: email.text.trim(),
          createdAt: TemporalDateTime.now(),
          updatedAt: TemporalDateTime.now(),
          role: AppRole.user.name,
          verificationStatus: VerificationStatus.approved.name,
        );
        await Amplify.DataStore.save(userRecord);
      }

      // Persist remember-me
      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        await SecureStorageService.instance.write(
          'REMEMBER_ME_PASSWORD',
          password.text.trim(),
        );
      } else {
        localStorage.remove('REMEMBER_ME_EMAIL');
        await SecureStorageService.instance.delete('REMEMBER_ME_PASSWORD');
      }

      // ✅ Inject Controllers
      _injectControllers(userRecord);

      TFullScreenLoader.stopLoading();
      isLoading.value = false;
      Get.offAllNamed(TRoutes.mainDashboard);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      isLoading.value = false;
      TLoaders.errorSnackBar(title: 'Login Failed', message: e.toString());
    }
  }

  // ---------------- Google Sign-In ----------------
  Future<void> googleSignIn() async {
    try {
      isGoogleLoading.value = true;
      TFullScreenLoader.openLoadingDialog(
        'Logging you in...',
        TImages.docerAnimation,
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) return;

      final userCredentials =
          await AuthenticationRepository.instance.signInWithGoogle();
      final googleUser = userCredentials?.user;

      if (googleUser == null) {
        TFullScreenLoader.stopLoading();
        isGoogleLoading.value = false;
        TLoaders.errorSnackBar(
          title: 'Login Failed',
          message: 'Google user data not available',
        );
        return;
      }

      final authUser = await Amplify.Auth.getCurrentUser();
      final users = await Amplify.DataStore.query(
        User.classType,
        where: User.ID.eq(authUser.userId),
      );

      final token = await TNotificationService.getToken();
      late User userRecord;

      if (users.isNotEmpty) {
        final existing = users.first;
        userRecord = existing.copyWith(
          username: googleUser.displayName ?? existing.username,
          email: googleUser.email ?? existing.email,
          profilePicture: googleUser.photoURL ?? existing.profilePicture,
          deviceToken: token,
          updatedAt: TemporalDateTime.now(),
          role: AppRole.user.name,
          verificationStatus: VerificationStatus.approved.name,
        );
      } else {
        userRecord = User(
          id: authUser.userId,
          username: googleUser.displayName ?? '',
          email: googleUser.email ?? '',
          profilePicture: googleUser.photoURL ?? '',
          deviceToken: token,
          createdAt: TemporalDateTime.now(),
          updatedAt: TemporalDateTime.now(),
          role: AppRole.user.name,
          verificationStatus: VerificationStatus.approved.name,
        );
      }

      await Amplify.DataStore.save(userRecord);

      // ✅ Inject Controllers
      _injectControllers(userRecord);

      await CreateNotificationController.instance.createNotification();

      TFullScreenLoader.stopLoading();
      isGoogleLoading.value = false;
      Get.offAllNamed(TRoutes.mainDashboard);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      isGoogleLoading.value = false;
      TLoaders.errorSnackBar(title: 'Login Failed', message: e.toString());
    }
  }
}
