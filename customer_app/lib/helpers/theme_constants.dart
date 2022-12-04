import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConstant {
  ThemeConstant._();

  static const Color primaryColor = Color(0xff1bab4b);
  static const Color secondaryColor = Color(0xffa5deb7);
  static const Color darkBackgroundColor = Color(0xff181a20);

  static const double defaultPadding = 16;
  static const double defaultRadius = 16;

  static ThemeData getTheme(Brightness brightness) {
    return _buildTheme(brightness, primaryColor);
  }
}

ThemeData _buildTheme(Brightness brightness, Color primaryColor) {
  final swatch = {
    50: primaryColor.withOpacity(0.1),
    100: primaryColor.withOpacity(0.2),
    200: primaryColor.withOpacity(0.3),
    300: primaryColor.withOpacity(0.4),
    400: primaryColor.withOpacity(0.5),
    500: primaryColor.withOpacity(0.6),
    600: primaryColor.withOpacity(0.7),
    700: primaryColor.withOpacity(0.8),
    800: primaryColor.withOpacity(0.9),
    900: primaryColor.withOpacity(1),
  };

  final primarySwatch = MaterialColor(primaryColor.value, swatch);

  return ThemeData(
    brightness: brightness,
    primarySwatch: primarySwatch,
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? ThemeConstant.darkBackgroundColor
        : null,
    colorScheme: brightness == Brightness.dark
        ? ColorScheme.dark(primary: primaryColor, secondary: primaryColor)
        : ColorScheme.light(primary: primaryColor),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: brightness == Brightness.dark
          ? null
          : ThemeConstant.darkBackgroundColor,
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shadowColor: ThemeConstant.secondaryColor.withOpacity(0.2),
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstant.defaultRadius),
        ),
        foregroundColor: Colors.white,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(
            vertical: ThemeConstant.defaultPadding * 0.8,
            horizontal: ThemeConstant.defaultPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstant.defaultRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstant.defaultRadius),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstant.defaultRadius),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(
        horizontal: ThemeConstant.defaultPadding,
        vertical: ThemeConstant.defaultPadding / 2,
      ),
    ),
  );
}
