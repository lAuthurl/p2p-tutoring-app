import 'package:flutter/material.dart';

import 'widget_themes/appbar_theme.dart';
import 'widget_themes/elevated_button_theme.dart';
import 'widget_themes/outlined_button_theme.dart';
import 'widget_themes/text_field_theme.dart';
import 'widget_themes/text_theme.dart';
import '../constants/colors.dart';

class TAppTheme {
  TAppTheme._();

  // Proper Light Theme
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: TColors.lightBackground,
    brightness: Brightness.light,
    textTheme: TTextTheme.lightTextTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2C2060),
      onPrimary: TColors.textWhite,
      surface: TColors.lightContainer,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    textTheme: TTextTheme.darkTextTheme,
    appBarTheme: TAppBarTheme.darkAppBarTheme,
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,
    colorScheme: const ColorScheme.dark(
      primary: TColors.primary,
      onPrimary: TColors.textWhite,
      surface: TColors.darkContainer,
    ),
  );
}
