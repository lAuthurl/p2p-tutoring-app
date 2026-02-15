import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
import '../Feautures/dashboard/Home/screens/home/home.dart';
import '../Feautures/favourites/favourite.dart';
import '../Feautures/checkout/screens/checkout.dart';
import '../screens/forget_password/forget_password_otp/otp_screen.dart';
import '../common/widgets/success_screen/success_screen.dart';
import '../personalization/screens/profile/re_authenticate_phone_otp_screen.dart';
import 'package:p2p_tutoring_app/Feautures/dashboard/Home/controllers/home_controller.dart';

class AppRoutes {
  static final pages = [
    // Splash & Auth flow
    GetPage(name: TRoutes.splash, page: () => SplashScreen(screenNumber: 1)),
    GetPage(name: TRoutes.onboarding, page: () => OnBoardingScreen()),
    GetPage(name: TRoutes.welcome, page: () => WelcomeScreen()),
    GetPage(name: TRoutes.logIn, page: () => LoginScreen()),

    // Auth helpers
    GetPage(name: TRoutes.phoneSignIn, page: () => OTPScreen()),
    GetPage(name: TRoutes.otpVerification, page: () => OTPScreen()),
    GetPage(
      name: TRoutes.reAuthenticateOtpVerification,
      page: () => ReAuthenticatePhoneOtpScreen(),
    ),

    // Home / Dashboards
    GetPage(name: TRoutes.home, page: () => ProfileScreen()),
    GetPage(name: TRoutes.mainDashboard, page: () => HomeScreen()),

    // Product / Session routes
    GetPage(
      name: TRoutes.sessions,
      page: () => const _FeaturePlaceholder('Sessions List'),
    ),
    GetPage(name: TRoutes.sessionDetail, page: () => SessionDetailScreen()),
    GetPage(name: TRoutes.productDetail, page: () => SessionDetailScreen()),

    // Booking / Cart / Checkout
    GetPage(name: TRoutes.bookings, page: () => BookingScreen()),
    GetPage(name: TRoutes.bookingScreen, page: () => BookingScreen()),
    GetPage(
      name: TRoutes.cartScreen,
      page: () => const _FeaturePlaceholder('Cart'),
    ),
    GetPage(name: TRoutes.checkoutScreen, page: () => CheckoutScreen()),
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

    // Favourites
    GetPage(
      name: TRoutes.favouritesScreen,
      page:
          () => FavouriteScreen(
            homeController:
                Get.find<HomeController>(), // Pass required controller
          ),
    ),

    // Profile & Notifications
    GetPage(name: TRoutes.profileScreen, page: () => ProfileScreen()),
    GetPage(
      name: TRoutes.notification,
      page: () => NotificationScreen(),
      binding: NotificationBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: TRoutes.notificationDetails,
      page: () => NotificationDetailScreen(),
      binding: NotificationBinding(),
      transition: Transition.fade,
    ),
  ];
}

/// Inline placeholder widget for unimplemented screens
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
