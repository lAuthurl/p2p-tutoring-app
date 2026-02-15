/* -- App Text Strings -- */

import 'package:get/get.dart';
import '../../../personalization/controllers/user_controller.dart';

/// This class contains all the App Text in String formats.
class TTexts {
  // -- GLOBAL Texts
  static const String tNo = "No";
  static const String and = "and";
  static const String tYes = "Yes";
  static const String skip = "Skip";
  static const String done = "Done";
  static const String tNext = "Next";
  static const String tLogin = "Login";
  static const String tSignup = "Signup";
  static const String tLogout = "Logout";
  static const String submit = "Submit";
  static const String email = "E-Mail";
  static const String tEmail = "E-Mail";
  static const String password = "Password";
  static const String tPassword = "Password";
  static const String tPhoneNo = "Phone No";
  static const String tFullName = "Full Name";
  static const String tGetStarted = "Get Started";
  static const String tContinue = "Continue";
  static const String tForgetPassword = "Forget Password?";

  static const String appName = "P2P Tutoring App";

  /// Home AppBar title dynamically includes current user's name
  static String get homeAppbarTitle {
    final userController = Get.find<UserController>();
    final userName = userController.currentUser.value?.username ?? "User";
    return "Welcome, $userName";
  }

  static const String homeAppbarSubTitle =
      "Learn. Collaborate. Succeed."; // Subtext to relate all UI
  static const String tSignInWithGoogle = "Sign-In with Google";

  static const String ohSnap = "Oh Snap!"; // Error / feedback
  static const String tSuccess = "Success"; // Success feedback

  // -- Validation --
  static const String dateOfBirthError = "You must be at least 18 years old.";

  // -- SnackBar --
  static const String tOhSnap = "Oh Snap";

  // -- Splash Screen Text
  // (intentionally minimal – handled via design)

  // -- On Boarding Text (Figma Exact)
  static const String tOnBoardingTitle1 = "Find Your Learning Match";
  static const String tOnBoardingTitle2 = "Choose How You Learn";
  static const String tOnBoardingTitle3 = "Grow, Track & Achieve";

  static const String tOnBoardingSubTitle1 =
      "Connect with peers who match your subject needs, academic level, and schedule.";
  static const String tOnBoardingSubTitle2 =
      "Learn your way, join peer tutoring sessions online or meet offline.";
  static const String tOnBoardingSubTitle3 =
      "Monitor your learning journey, earn badges, and celebrate progress.";

  static const String tOnBoardingCounter1 = "1/3";
  static const String tOnBoardingCounter2 = "2/3";
  static const String tOnBoardingCounter3 = "3/3";

  // -- Welcome Screen Text
  static const String tWelcomeTitle = "Welcome to Peer Tutoring";
  static const String tWelcomeSubTitle =
      "Collaborate, learn, and succeed together.";

  // -- Login Screen Text
  static const String tDontHaveAnAccount = "Don’t have an account?";
  static const String tResetPassword = "Reset Password";
  static const String tOR = "OR";

  // -- Sign Up Screen Text
  // (intentionally minimal – design-driven)

  // -- Verify Email Screen Text
  static const String yourAccountCreatedTitle = "Account successfully created!";
  static const String yourAccountCreatedSubTitle = "";

  // -- Forget Password Text
  static const String tForgetPasswordTitle = "Password Recovery";
  static const String tForgetPasswordSubTitle =
      "Input your email in the text field";
  static const String tResetViaEMail = "Reset via Email";

  // -- OTP Screen Text
  static const String tOtpTitle = "OTP";
  static const String tOtpSubTitle = "Verification";
  static const String tOtpMessage = "";

  // -- Profile Screen - Text
  static const String tProfile = "Profile";
  static const String tEditProfile = "Edit Profile";
  static const String tLogoutDialogHeading = "Logout";
  static const String tProfileHeading = "Coding with T";
  static const String tProfileSubHeading = "superAdmin@codingwitht.com";

  // -- Update Profile Screen - Text
  static const String tDelete = "Delete";
  static const String tJoined = "Joined ";
  static const String tJoinedAt = " 31 October 2022";

  static const String phoneNo = '745-628-5429';
  static const String selectCountry = 'Select Country';
  static const String signupScreenTitle = "signupScreenTitle";
  static const String signupScreenSubTitle = "signupScreenSubTitle";
  static const String otpVerification = "OTP Verification";
  static const String signInSubTitle = "We will send a one time SMS message.";
  static const String selectCountryCode = "Select Country Code";
  static const String sendingOTP = "Sending OTP...";
  static const String phoneVerifiedTitle = "Phone Verified";
  static const String phoneVerifiedMessage =
      "Your phone number has been verified.";
  static const String noInternet = "No Internet";
  static const String checkInternetConnection =
      "Please check your internet connection and try again.";
  static const String unableToSendOTP = "Unable to send OTP";
  static const String otpSendTitle = "OTP Send";
  static const String otpSendMessage =
      "OTP Send to your phone number successfully.";
  static const String otpFooter = "Didn’t receive OTP?";
  static const String otpSubTitle =
      "Please enter the six digit OTP code that we’ve send to your phone number";
  static const String enter6digitOTPCode = "Enter 6 digit OTP Code";
  static const String inText = "in";
  static const String resendOTP = "Re-Send OTP";
  static const String thenLets = "Then let’s ";

  // -- Email Verification
  static const String tEmailVerificationTitle = "Verify Your Email";
  static const String tEmailVerificationSubTitle =
      "Please check your email and click the verification link to continue.";
  static const String tResendEmailLink = "Resend Verification Link";
  static const String tBackToLogin = "Back to Login";

  // -- Dashboard Screen - Text
  static const String tDashboardTitle = "Hey, Coding with T";
  static const String tDashboardHeading = "Explore Courses";
  static const String tDashboardSearch = "Search...";
  static const String tDashboardBannerTitle2 = "JAVA";
  static const String tDashboardButton = "View All";
  static const String tDashboardTopCourses = "Top Courses";
  static const String tDashboardBannerSubTitle = "10 Lessons";
  static const String tDashboardBannerTitle1 = "Android for Beginners";

  // -- App Screen Text
  static const String tAppName = "Peer Tutoring";
  static const String tAppTagLine = "Learn Together, Succeed Together";
}
