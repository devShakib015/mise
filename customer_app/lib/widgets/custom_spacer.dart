import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';

class DefaultVerticalSpacer extends StatelessWidget {
  final bool isHalf;
  const DefaultVerticalSpacer({
    Key? key,
    this.isHalf = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: isHalf
            ? ThemeConstant.defaultPadding / 2
            : ThemeConstant.defaultPadding);
  }
}

class DefaultHorizontalSpacer extends StatelessWidget {
  final bool isHalf;
  const DefaultHorizontalSpacer({
    Key? key,
    this.isHalf = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: isHalf
            ? ThemeConstant.defaultPadding / 2
            : ThemeConstant.defaultPadding);
  }
}
