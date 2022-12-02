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
