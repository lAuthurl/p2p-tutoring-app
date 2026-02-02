import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:flutter/material.dart';
import 'package:p2p_tutoring_app/Feautures/Courses/models/tutoring_session_model.dart';
import 'package:p2p_tutoring_app/personalization/screens/profile/re_authenticate_phone_otp_screen.dart';

import '../bindings/notification_binding.dart';
import '../screens/login/login_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/splash_screen/splash_screen.dart';
import '../screens/on_boarding/on_boarding_screen.dart';
import '../personalization/screens/notification/notification_screen.dart';
import '../personalization/screens/notification/notification_detail_screen.dart';
import '../personalization/screens/profile/profile_screen.dart';
import 'routes.dart';

// Feature screens
import '../Feautures/Courses/screens/product_detail/session_detail_screen.dart';
import '../Feautures/Booking/screens/booking_screen.dart';
import '../Feautures/dashboard/course/screens/dashboard/courses_dashboard.dart';
import '../Feautures/dashboard/Home/screens/home/home.dart';
import '../Feautures/favourites/favourite.dart';
import '../Feautures/checkout/screens/checkout.dart';
import '../screens/forget_password/forget_password_otp/otp_screen.dart';
import '../common/widgets/success_screen/success_screen.dart';

class AppRoutes {
  static final pages = [
    // Splash & Auth flow (in order)
    GetPage(
      name: TRoutes.splash,
      page: () => const SplashScreen(screenNumber: 1),
    ),
    GetPage(name: TRoutes.onboarding, page: () => const OnBoardingScreen()),
    GetPage(name: TRoutes.welcome, page: () => const WelcomeScreen()),
    GetPage(name: TRoutes.logIn, page: () => const LoginScreen()),

    // Auth helpers / placeholders
    GetPage(name: TRoutes.phoneSignIn, page: () => const OTPScreen()),
    GetPage(name: TRoutes.otpVerification, page: () => const OTPScreen()),
    GetPage(
      name: TRoutes.reAuthenticateOtpVerification,
      page: () => const ReAuthenticatePhoneOtpScreen(),
    ),

    // Home / Dashboards
    GetPage(name: TRoutes.home, page: () => const ProfileScreen()),
    GetPage(
      name: TRoutes.coursesDashboard,
      page: () => const CoursesDashboard(),
    ),
    GetPage(name: TRoutes.mainDashboard, page: () => const HomeScreen()),

    // Product / Session routes
    GetPage(
      name: TRoutes.sessions,
      page: () => const _FeaturePlaceholder('Sessions List'),
    ),
    GetPage(
      name: TRoutes.sessionDetail,
      page: () {
        final args = Get.arguments;
        if (args is TutoringSessionModel) {
          return SessionDetailScreen(session: args);
        }
        return const _FeaturePlaceholder('Session Detail (no args provided)');
      },
    ),
    GetPage(
      name: TRoutes.productDetail,
      page: () {
        final args = Get.arguments;
        if (args is TutoringSessionModel) {
          return SessionDetailScreen(session: args);
        }
        return const _FeaturePlaceholder('Product Detail (no args provided)');
      },
    ),

    // Booking / Cart / Checkout
    GetPage(name: TRoutes.bookings, page: () => BookingScreen()),
    GetPage(name: TRoutes.bookingScreen, page: () => BookingScreen()),
    GetPage(
      name: TRoutes.cartScreen,
      page: () => const _FeaturePlaceholder('Cart'),
    ),
    GetPage(name: TRoutes.checkoutScreen, page: () => const CheckoutScreen()),
    GetPage(
      name: TRoutes.paymentScreen,
      page:
          () => SuccessScreen(
            image: '',
            title: '',
            subTitle: '',
            onPressed: () {},
          ),
    ),
    GetPage(
      name: TRoutes.favouritesScreen,
      page: () => const FavouriteScreen(),
    ),

    // Profile & Notifications
    GetPage(name: TRoutes.profileScreen, page: () => const ProfileScreen()),
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

/// Small inline placeholder widget used for routes that don't have a dedicated screen yet.
class _FeaturePlaceholder extends StatelessWidget {
  final String title;
  const _FeaturePlaceholder(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title - screen not implemented yet')),
    );
  }
}
