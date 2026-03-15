import 'package:get/get.dart';
import 'package:p2p_tutoring_app/Feautures/Booking/controllers/booking_controller.dart';
import 'package:p2p_tutoring_app/Feautures/dashboard/Home/controllers/home_controller.dart';
import 'package:p2p_tutoring_app/Feautures/dashboard/Home/controllers/subject_controller.dart';
import 'package:p2p_tutoring_app/personalization/controllers/theme_controller.dart';

import '../Feautures/dashboard/Home/controllers/favorites_controller.dart';
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

    // ================= PERSISTENT APP CONTROLLERS =================
    // These must be permanent so they survive navigation and are
    // available immediately when the user reaches the dashboard.
    Get.put(SubjectController(), permanent: true);
    Get.put(HomeController(), permanent: true);
    Get.put(BookingController(), permanent: true);

    // ✅ FavoritesController: registered here so it loads the current
    //    user's favorites from AppSync on startup — before the home
    //    screen renders. permanent: true keeps it alive across all
    //    navigation so heart icons stay in sync everywhere.
    Get.put(FavoritesController(), permanent: true);

    // ================= AUTH FLOW =================
    // lazyPut / fenix: true — created only when navigated to,
    // recreated automatically if GetX disposes them.
    Get.lazyPut(() => LoginController(), fenix: true);
    Get.lazyPut(() => SignUpController(), fenix: true);
    Get.lazyPut(() => OTPController(), fenix: true);
    Get.lazyPut(() => VerifyEmailController(), fenix: true);
    Get.lazyPut(() => MailVerificationController(), fenix: true);

    // ================= ANIMATION CONTROLLER =================
    if (!Get.isRegistered<FadeInAnimationController>()) {
      Get.put(FadeInAnimationController(), permanent: true);
    }
  }
}
