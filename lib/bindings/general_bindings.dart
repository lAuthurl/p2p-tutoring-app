import 'package:p2p_tutoring_app/personalization/controllers/theme_controller.dart';
import 'package:get/get.dart';

import '../data/repository/authentication_repository/authentication_repository.dart';
import '../data/services/notifications/notification_service.dart';
import '../authentication/controllers/login_controller.dart';
import '../authentication/controllers/on_boarding_controller.dart';
import '../authentication/controllers/otp_controller.dart';
import '../authentication/controllers/signup_controller.dart';
import '../authentication/controllers/phone_number_controller.dart';
import '../authentication/controllers/verify_email_controller.dart';
import '../authentication/controllers/mail_verification_controller.dart';
import '../utils/animations/fade_in_animation/fade_in_animation_controller.dart';
import '../personalization/controllers/create_notification_controller.dart';
import '../data/repository/notifications/notification_repository.dart';
import '../data/repository/user_repository/user_repository.dart';
import '../personalization/controllers/address_controller.dart';
import '../personalization/controllers/notification_controller.dart';
import '../personalization/controllers/user_controller.dart';
import '../utils/helpers/network_manager.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    /// -- Core
    Get.put(NetworkManager());

    /// -- Repository
    Get.lazyPut(() => AuthenticationRepository(), fenix: true);
    Get.put(ThemeController());
    Get.lazyPut(() => UserRepository(), fenix: true);
    Get.lazyPut(() => UserController());
    Get.lazyPut(() => AddressController());

    Get.lazyPut(() => OnBoardingController(), fenix: true);

    // UI/controllers used across screens
    Get.lazyPut(() => FadeInAnimationController(), fenix: true);
    Get.lazyPut(() => SignInController(), fenix: true);
    Get.lazyPut(() => VerifyEmailController(), fenix: true);
    Get.lazyPut(() => MailVerificationController(), fenix: true);
    Get.lazyPut(() => NotificationRepository(), fenix: true);
    Get.lazyPut(() => CreateNotificationController(), fenix: true);

    Get.lazyPut(() => LoginController(), fenix: true);
    Get.lazyPut(() => SignUpController(), fenix: true);
    Get.lazyPut(() => OTPController(), fenix: true);
    Get.put(TNotificationService());
    Get.lazyPut(() => NotificationController(), fenix: true);
  }
}
