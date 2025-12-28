import 'package:p2p_tutoring_app/screens/on_boarding/on_boarding_screen.dart';
// ProfileScreen removed; route now points to UserProfilesScreen
import 'package:p2p_tutoring_app/routes/routes.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

import '../bindings/notification_binding.dart';
// Phone sign-in screens removed from routing to disable phone-based login
import '../screens/login/login_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/splash_screen/splash_screen.dart';
import '../personalization/screens/notification/notification_detail_screen.dart';
import '../personalization/screens/notification/notification_screen.dart';
import '../screens/user_profiles/user_profiles_screen.dart';

class AppRoutes {
  static final pages = [
    GetPage(name: TRoutes.welcome, page: () => const WelcomeScreen()),
    // Splash route shown first
    GetPage(name: TRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: TRoutes.onboarding, page: () => const OnBoardingScreen()),

    // Dashboard route (mapped to UserProfiles for now)
    GetPage(
      name: TRoutes.coursesDashboard,
      page: () => const UserProfilesScreen(),
    ),

    // Login route
    GetPage(name: TRoutes.logIn, page: () => const LoginScreen()),
    // Phone sign-in routes removed to disable phone-based login in this build.
    GetPage(
      name: TRoutes.profileScreen,
      page: () => const UserProfilesScreen(),
    ),

    GetPage(
      name: TRoutes.notification,
      page: () => const NotificationScreen(),
      binding: NotificationBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: TRoutes.notificationDetails,
      page: () => const NotificationDetailScreen(),
      binding: NotificationBinding(),
      transition: Transition.fade,
    ),
  ];
}
