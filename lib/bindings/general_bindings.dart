import 'package:get/get.dart';
import 'package:p2p_tutoring_app/personalization/controllers/theme_controller.dart';

import '../utils/helpers/network_manager.dart';
import '../data/services/notifications/notification_service.dart';

// Repositories
import '../data/repository/authentication_repository/authentication_repository.dart';
import '../data/repository/user_repository/user_repository.dart';
import '../data/repository/notifications/notification_repository.dart';

// Auth Controllers
import '../authentication/controllers/login_controller.dart';
import '../authentication/controllers/on_boarding_controller.dart';
import '../authentication/controllers/otp_controller.dart';
import '../authentication/controllers/signup_controller.dart';
import '../authentication/controllers/verify_email_controller.dart';
import '../authentication/controllers/mail_verification_controller.dart';

// Personalization Controllers
import '../personalization/controllers/user_controller.dart';
import '../personalization/controllers/address_controller.dart';
import '../personalization/controllers/notification_controller.dart';
import '../personalization/controllers/create_notification_controller.dart';

// Animations
import '../utils/animations/fade_in_animation/fade_in_animation_controller.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    // ================= CORE =================
    Get.put(NetworkManager(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    Get.put(TNotificationService(), permanent: true);

    // ================= REPOSITORIES =================
    Get.put(AuthenticationRepository(), permanent: true);
    Get.put(UserRepository(), permanent: true);
    Get.put(NotificationRepository(), permanent: true);

    // ================= GLOBAL CONTROLLERS =================
    Get.put(UserController(), permanent: true);
    Get.put(AddressController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
    Get.put(CreateNotificationController(), permanent: true);

    // Onboarding must exist BEFORE login routing decision
    Get.put(OnBoardingController(), permanent: true);

    // ================= AUTH FLOW =================
    Get.lazyPut(() => LoginController());
    Get.lazyPut(() => SignUpController());
    Get.lazyPut(() => OTPController());
    Get.lazyPut(() => VerifyEmailController());
    Get.lazyPut(() => MailVerificationController());

    // ================= ANIMATION CONTROLLER =================
    // Ensure FadeInAnimationController is available
    if (!Get.isRegistered<FadeInAnimationController>()) {
      Get.put(FadeInAnimationController(), permanent: true);
    }
  }
}
