import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/tokens.dart';
import 'brand_mark.dart';

/// The shell behind connect, setup and sign-in: a warm, softly lit canvas with
/// a single panel floating on it.
class CenteredPanel extends StatelessWidget {
  const CenteredPanel({
    super.key,
    required this.child,
    this.maxWidth = 460,
    this.subtitle,
    this.footer,
  });

  final Widget child;
  final double maxWidth;
  final String? subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.75),
            radius: 1.15,
            colors: [
              Color.lerp(p.canvas, p.brand, p.isDark ? 0.07 : 0.035)!,
              p.canvas,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.xl,
                vertical: Space.xxl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BrandLockup(subtitle: subtitle),
                    ),
                    const SizedBox(height: Space.xl),
                    Container(
                      padding: const EdgeInsets.all(Space.xl),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: Radii.extraLarge,
                        border: Border.all(color: p.border),
                        boxShadow: [
                          BoxShadow(
                            color: p.shadow,
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: Space.md),
                      DefaultTextStyle.merge(
                        textAlign: TextAlign.center,
                        child: footer!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
