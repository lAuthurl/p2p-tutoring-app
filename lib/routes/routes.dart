// routes.dart

class TRoutes {
  static const welcome = '/welcome-screen';
  static const splash = '/splash';
  static const onboarding = '/onboarding-screen';

  // Authentication
  static const logIn = '/log-in';
  static const phoneSignIn = '/phone-sign-in';
  static const otpVerification = '/otp-verification';
  static const reAuthenticateOtpVerification =
      '/re-authenticate-otp-verification';

  // Home / Dashboards
  static const home = '/home';
  static const mainDashboard = '/main-dashboard-screen';

  // Product / Session
  static const sessions = '/sessions';
  static const sessionDetail = '/session-detail';
  static const productDetail = '/product-detail';

  // Booking / Cart / Checkout
  static const bookings = '/bookings';
  static const bookingScreen = '/booking-screen';
  static const cartScreen = '/cart-screen';
  static const checkoutScreen = '/checkout-screen';
  static const paymentScreen = '/payment-screen';
  static const favouritesScreen = '/favourites-screen';

  // Profile & Notifications
  static const profileScreen = '/profile-screen';
  static const notification = '/notification';
  static const notificationDetails = '/notification-details';
}
