import 'package:flutter/material.dart';

class TColors {
  // App theme colors
  static const Color primary = Color(0xFF8484FA); // Light Blue
  static const Color secondary = Color(0xFF202870); // Dark Blue
  static const Color accent = Color(0xFFF94A82); // Pink Accent
  static const Color primaryBackground = Color(0xFFFFFFFF); // White Background
  static const Color secondaryBackground = secondary; // Dark Blue Background

  // Dashboard Specific Colors
  static const Color dashboardAppbarBackground = primary;

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White titles
  static const Color textSecondary = Color(
    0xB3FFFFFF,
  ); // Semi-transparent white subtitles
  static const Color textDarkPrimary = Color(0xFF202870); // Dark Blue text
  static const Color textDarkSecondary = Color(0xFF8484FA); // Light Blue text
  static const Color textWhite = Colors.white;

  // Disabled
  static const Color disabledTextLight = textSecondary;
  static const Color disabledBackgroundLight = Color(
    0x33FFFFFF,
  ); // Transparent White
  static const Color disabledTextDark = textDarkSecondary;
  static const Color disabledBackgroundDark = Color(
    0x33102070,
  ); // Transparent Dark Blue

  // Background colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color darkBackground = secondary;

  // Background Container colors
  static const Color lightContainer = Color(0xFFF4F4F4);
  static const Color darkContainer = Color(0xFF202870);
  static const Color cardBackgroundColor = Color(0xFFFFFFFF);

  // Button colors
  static const Color buttonPrimary = accent; // Pink Accent
  static const Color buttonSecondary = primary; // Light Blue
  static const Color buttonDisabled = disabledBackgroundLight;

  // Social Buttons
  static const Color googleBackgroundColor = Color(0xFFFFFFFF);
  static const Color googleForegroundColor = secondary;
  static const Color facebookBackgroundColor = Color(0xFF202870);

  // ON-BOARDING COLORS
  static const Color onBoardingPage1Color = primary; // Light Blue
  static const Color onBoardingPage2Color = secondary; // Dark Blue
  static const Color onBoardingPage3Color = Color(
    0xFF4A6FFF,
  ); // Medium Blue for page 3
  static const Color onBoardingTextColor = Colors.white;

  // Icon colors
  static const Color iconPrimaryLight = Colors.white;
  static const Color iconSecondaryLight = Colors.white70;
  static const Color iconPrimaryDark = secondary;
  static const Color iconSecondaryDark = primary;

  // Border colors
  static const Color borderPrimary = primary;
  static const Color borderSecondary = secondary;
  static const Color borderLight = Colors.white70;
  static const Color borderDark = Colors.black54;

  // Error and validation colors
  static const Color error = Color(0xFFF94A82); // Pink Accent for errors
  static const Color success = primary; // Light Blue for success
  static const Color warning = accent;
  static const Color info = secondary;

  // Neutral Shades
  static const Color black = Color(0xFF000000);
  static const Color dark = secondary;
  static const Color grey = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);
}
