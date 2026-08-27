import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// Standard heading for a manager page: title, one line of context, and the
/// primary action for that page.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.headline.copyWith(color: p.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: AppType.small.copyWith(color: p.textSecondary)),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: Space.md), action!],
        ],
      ),
    );
  }
}

/// Shown when a list has nothing in it yet. Always offers the way out.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: p.surfaceSunken,
                borderRadius: Radii.large,
                border: Border.all(color: p.border),
              ),
              child: Icon(icon, size: 26, color: p.textTertiary),
            ),
            const SizedBox(height: Space.md),
            Text(title, style: AppType.subtitle.copyWith(color: p.textPrimary)),
            const SizedBox(height: Space.xxs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppType.small.copyWith(color: p.textSecondary),
              ),
            ),
            if (action != null) ...[const SizedBox(height: Space.lg), action!],
          ],
        ),
      ),
    );
  }
}

/// Renders an [AsyncValue] so pages stop repeating the same three branches.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: data,
      loading: () => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 34, color: p.textTertiary),
              const SizedBox(height: Space.md),
              Text('Could not load this',
                  style: AppType.subtitle.copyWith(color: p.textPrimary)),
              const SizedBox(height: Space.xxs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  '$err',
                  textAlign: TextAlign.center,
                  style: AppType.small.copyWith(color: p.textSecondary),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: Space.lg),
                OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
