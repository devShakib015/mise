import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';

class StaticLogoWidget extends StatelessWidget {
  const StaticLogoWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.25),
      child: Image.asset(Images.logo, color: ThemeConstant.primaryColor),
    );
  }
}

class CustomLoadingWidget extends StatelessWidget {
  final Color? color;
  final double scale;
  const CustomLoadingWidget({
    Key? key,
    this.color,
    this.scale = 2.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Images.loader,
      width: ThemeConstant.defaultPadding * scale,
      height: ThemeConstant.defaultPadding * scale,
      color: color ?? Theme.of(context).colorScheme.primary,
    );
  }
}
