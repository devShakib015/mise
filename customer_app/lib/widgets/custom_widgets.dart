import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

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

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isFilled;
  const CustomIconButton({
    Key? key,
    required this.icon,
    required this.onTap,
    this.isFilled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding / 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFilled ? Theme.of(context).colorScheme.primary : null,
          border: isFilled
              ? null
              : Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
        child: Icon(icon, color: isFilled ? Colors.white : null, size: 20),
      ),
    );
  }
}
