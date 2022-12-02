import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Foodie';

  static const String translationsPath = 'assets/i18n';
  static const List<Locale> supportedLocales = [
    Locale('en'), //Don't remove this line

    //Add your other supported locales here
    Locale('bn'),
  ];
}
