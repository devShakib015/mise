import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void configLoading(Brightness brightness) {
  EasyLoading.instance
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorColor = brightness == Brightness.dark
        ? Colors.white38
        : ThemeConstant.darkBackgroundColor
    ..backgroundColor = brightness == Brightness.dark
        ? ThemeConstant.darkCardColor
        : Colors.white
    ..textColor = brightness == Brightness.dark
        ? Colors.white
        : ThemeConstant.darkBackgroundColor
    ..progressColor = brightness == Brightness.dark
        ? Colors.white
        : ThemeConstant.darkBackgroundColor
    ..textStyle = const TextStyle(fontWeight: FontWeight.bold)
    ..animationStyle = EasyLoadingAnimationStyle.scale
    ..animationDuration = const Duration(milliseconds: 100)
    ..toastPosition = EasyLoadingToastPosition.bottom
    ..boxShadow = const [
      BoxShadow(
        color: Colors.black12,
        offset: Offset(0.0, 3.0),
        blurRadius: 3.0,
        spreadRadius: 1.0,
        blurStyle: BlurStyle.outer,
      )
    ]
    ..maskType = EasyLoadingMaskType.black
    ..dismissOnTap = false;
}
