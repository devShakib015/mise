import 'dart:ui';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';

Future showCustomDialog(
  BuildContext context, {
  bool barrierDismissible = true,
  required Widget child,
}) async {
  return showGeneralDialog(
    context: context,
    transitionDuration: const Duration(milliseconds: 200),
    barrierDismissible: true,
    barrierLabel: '',
    transitionBuilder: (context, a1, a2, widget) {
      return SlideTransition(
        position:
            Tween(begin: const Offset(0, 1), end: Offset.zero).animate(a1),
        child: widget,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: child,
        ),
      );
    },
  );
}

Future<void> showCustomSnackBar(
  BuildContext context, {
  required String content,
  Widget? leading,
  Widget? trailing,
  int durationInSec = 2,
}) async {
  showGeneralDialog(
    context: context,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, a1, a2, widget) {
      return SlideTransition(
        position:
            Tween(begin: const Offset(0, 1), end: Offset.zero).animate(a1),
        child: widget,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: ThemeConstant.defaultPadding),
            child: Dialog(
              alignment: Alignment.bottomCenter,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(ThemeConstant.defaultRadius),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ThemeConstant.defaultPadding,
                  vertical: ThemeConstant.defaultPadding / 2,
                ),
                title: Text(
                  content,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).textTheme.headline5!.color,
                      ),
                ),
                leading: leading,
                trailing: trailing,
              ),
            ),
          ),
        ),
      );
    },
  );
  await Future.delayed(Duration(seconds: durationInSec))
      .then((value) => Navigator.pop(context));
}
