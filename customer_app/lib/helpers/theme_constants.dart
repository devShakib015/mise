import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeConstant {
  ThemeConstant._();

  static const Color primaryColor = Color(0xff1bab4b);

  static const Color darkBackgroundColor = Color(0xff181a20);
  static const Color darkCardColor = Color(0xff20232b);

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
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.all(primaryColor),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.all(primaryColor),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: brightness == Brightness.dark
          ? ThemeConstant.darkBackgroundColor
          : null,
      selectedItemColor: primaryColor,
      unselectedItemColor: brightness == Brightness.dark
          ? Colors.white.withOpacity(0.5)
          : Colors.black.withOpacity(0.5),
      selectedIconTheme: IconThemeData(
        color: primaryColor,
      ),
      unselectedIconTheme: IconThemeData(
        color: brightness == Brightness.dark
            ? Colors.white.withOpacity(0.5)
            : Colors.black.withOpacity(0.5),
      ),
      selectedLabelStyle: TextStyle(
        color: primaryColor,
      ),
      unselectedLabelStyle: TextStyle(
        color: brightness == Brightness.dark
            ? Colors.white.withOpacity(0.5)
            : Colors.black.withOpacity(0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shadowColor: ThemeConstant.primaryColor.withOpacity(0.2),
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstant.defaultRadius),
        ),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
      color: brightness == Brightness.dark ? ThemeConstant.darkCardColor : null,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(
        horizontal: ThemeConstant.defaultPadding,
        vertical: ThemeConstant.defaultPadding / 2,
      ),
    ),
    tabBarTheme: TabBarTheme(
      unselectedLabelColor: brightness == Brightness.dark
          ? Colors.white.withOpacity(0.5)
          : Colors.black.withOpacity(0.5),
      labelColor: brightness == Brightness.dark
          ? Colors.white.withOpacity(0.9)
          : Colors.black.withOpacity(0.9),
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      tilePadding: EdgeInsets.symmetric(
        horizontal: ThemeConstant.defaultPadding,
        vertical: ThemeConstant.defaultPadding / 4,
      ),
      childrenPadding: EdgeInsets.symmetric(
        horizontal: ThemeConstant.defaultPadding,
        vertical: ThemeConstant.defaultPadding / 2,
      ),
      expandedAlignment: Alignment.centerLeft,
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstant.defaultRadius),
      ),
      backgroundColor:
          brightness == Brightness.dark ? ThemeConstant.darkCardColor : null,
    ),
  );
}
