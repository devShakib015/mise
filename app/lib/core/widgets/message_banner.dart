import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';
import '../theme/tokens.dart';

enum BannerTone { info, warning, danger, success }

/// Inline message. Used instead of a snackbar wherever the message explains why
/// the thing in front of the user did not work — it needs to stay on screen.
class MessageBanner extends StatelessWidget {
  const MessageBanner({
    super.key,
    required this.message,
    this.tone = BannerTone.danger,
    this.icon,
  });

  final String message;
  final BannerTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final (fg, bg, defaultIcon) = switch (tone) {
      BannerTone.info => (p.info, p.infoSubtle, Icons.info_outline),
      BannerTone.warning => (p.warning, p.warningSubtle, Icons.warning_amber_rounded),
      BannerTone.danger => (p.danger, p.dangerSubtle, Icons.error_outline),
      BannerTone.success => (p.success, p.successSubtle, Icons.check_circle_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: Radii.medium,
        border: Border.all(color: fg.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 18, color: fg),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(
              message,
              style: AppType.small.copyWith(
                color: p.isDark ? p.textPrimary : fg,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
