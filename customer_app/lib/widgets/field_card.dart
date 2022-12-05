import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';

class FieldCard extends StatelessWidget {
  final Widget child;
  final IconData? prefixIcon;
  final Widget? suffix;
  const FieldCard({
    Key? key,
    required this.child,
    this.prefixIcon,
    this.suffix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeConstant.defaultPadding,
          vertical: ThemeConstant.defaultPadding / 2,
        ),
        child: Row(
          children: [
            if (prefixIcon != null) Icon(prefixIcon),
            Expanded(child: child),
            if (suffix != null) suffix!,
          ],
        ),
      ),
    );
  }
}
