import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void configLoading(Brightness brightness) {
  EasyLoading.instance
    ..loadingStyle = EasyLoadingStyle.custom
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
