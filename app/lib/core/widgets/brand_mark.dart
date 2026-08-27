import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// The product mark: an ember, drawn rather than imported so it stays crisp at
/// every size and adds nothing to the bundle.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.brand, Color.lerp(p.brand, Colors.black, 0.28)!],
        ),
        boxShadow: [
          BoxShadow(
            color: p.brand.withValues(alpha: 0.32),
            blurRadius: size * 0.36,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size.square(size * 0.5),
          painter: _FlamePainter(color: p.onBrand),
        ),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer flame: a teardrop that leans, so it reads as movement not a balloon.
    final flame = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.86, h * 0.28, w * 1.0, h * 0.52, w * 0.86, h * 0.74)
      ..cubicTo(w * 0.74, h * 0.95, w * 0.26, h * 0.95, w * 0.14, h * 0.74)
      ..cubicTo(w * 0.0, h * 0.52, w * 0.2, h * 0.3, w * 0.42, h * 0.16)
      ..cubicTo(w * 0.46, h * 0.3, w * 0.4, h * 0.4, w * 0.46, h * 0.46)
      ..cubicTo(w * 0.56, h * 0.38, w * 0.52, h * 0.18, w * 0.5, 0)
      ..close();

    canvas.drawPath(flame, paint);
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.color != color;
}

/// Mark plus wordmark, for the top of setup and sign-in screens.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.subtitle, this.size = 44});

  final String? subtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mise', style: AppType.title.copyWith(color: p.textPrimary)),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppType.small.copyWith(color: p.textTertiary),
              ),
          ],
        ),
      ],
    );
  }
}
