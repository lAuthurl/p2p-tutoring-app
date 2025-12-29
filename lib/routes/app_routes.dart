import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

import '../bindings/notification_binding.dart';
import '../screens/login/login_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/splash_screen/splash_screen.dart';
import '../screens/on_boarding/on_boarding_screen.dart';
import '../personalization/screens/notification/notification_screen.dart';
import '../personalization/screens/notification/notification_detail_screen.dart';
import '../screens/user_profiles/user_profiles_screen.dart';
import 'routes.dart';

class AppRoutes {
  static final pages = [
    GetPage(name: TRoutes.welcome, page: () => const WelcomeScreen()),

    // Splash route (choose screenNumber 1, 2, or 3)
    GetPage(
      name: TRoutes.splash,
      page: () => const SplashScreen(screenNumber: 1),
    ),

    GetPage(name: TRoutes.onboarding, page: () => const OnBoardingScreen()),

    // Dashboard route
    GetPage(
      name: TRoutes.coursesDashboard,
      page: () => const UserProfilesScreen(),
    ),

    // Login route
    GetPage(name: TRoutes.logIn, page: () => const LoginScreen()),

    // Profile
    GetPage(
      name: TRoutes.profileScreen,
      page: () => const UserProfilesScreen(),
    ),

    // Notifications
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
