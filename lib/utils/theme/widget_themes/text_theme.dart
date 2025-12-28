import 'package:flutter/material.dart';
// Using bundled font family 'Poppins' via assets; do not fetch via GoogleFonts.

import '../../constants/colors.dart';

/* -- Light & Dark Text Themes -- */
class TTextTheme {
  TTextTheme._(); //To avoid creating instances

  /* -- Light Text Theme -- */
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      color: TColors.dark,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
      color: TColors.dark,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24.0,
      fontWeight: FontWeight.normal,
      color: TColors.dark,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: TColors.dark,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18.0,
      fontWeight: FontWeight.normal,
      color: TColors.dark,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
      color: TColors.dark,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14.0,
      color: TColors.dark,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14.0,
      color: TColors.dark.withValues(alpha: 0.8),
    ),
  );

  /* -- Dark Text Theme -- */
  static TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      color: TColors.white,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
      color: TColors.white,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24.0,
      fontWeight: FontWeight.normal,
      color: TColors.white,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: TColors.white,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18.0,
      fontWeight: FontWeight.normal,
      color: TColors.white,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
      color: TColors.white,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14.0,
      color: TColors.white,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14.0,
      color: TColors.white.withValues(alpha: 0.8),
    ),
  );
}
