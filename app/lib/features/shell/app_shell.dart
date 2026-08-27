import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/brand_mark.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/staff.dart';
import '../../data/session.dart';

/// One app, three faces. The signed-in role decides which one opens.
class AppShellScreen extends ConsumerWidget {
  const AppShellScreen({
    super.key,
    required this.staff,
    required this.restaurant,
  });

  final Staff staff;
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;

    return Scaffold(
      body: Column(
        children: [
          _TopBar(staff: staff, restaurant: restaurant),
          Divider(height: 1, color: p.border),
          Expanded(
            child: switch (staff.role.shell) {
              AppShell.pos => const _Placeholder(
                  shell: 'Point of sale',
                  icon: Icons.point_of_sale_outlined,
                  blurb: 'Take orders, run the floor, settle bills.',
                  phase: 'Phase 2',
                  coming: [
                    'Floor plan and table status',
                    'Order taking with modifiers and kitchen notes',
                    'Send to kitchen, then split, discount and settle',
                  ],
                ),
              AppShell.kitchen => const _Placeholder(
                  shell: 'Kitchen display',
                  icon: Icons.soup_kitchen_outlined,
                  blurb: 'Live tickets, straight off the pass.',
                  phase: 'Phase 3',
                  coming: [
                    'Realtime tickets the moment an order is sent',
                    'Per-item status and bump to ready',
                    'Prep timers and ticket ageing',
                  ],
                ),
              AppShell.manager => const _Placeholder(
                  shell: 'Manager',
                  icon: Icons.tune_rounded,
                  blurb: 'Menu, staff, settings and the numbers.',
                  phase: 'Phase 1',
                  coming: [
                    'Categories, items and modifier groups',
                    'Tables, staff accounts and printers',
                    'Sales reporting and end-of-day',
                  ],
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.staff, required this.restaurant});

  final Staff staff;
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;

    return Container(
      height: 64,
      color: p.surface,
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Row(
        children: [
          const BrandMark(size: 32),
          const SizedBox(width: Space.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(restaurant.name,
                  style: AppType.bodyStrong.copyWith(color: p.textPrimary)),
              Text(
                '${restaurant.currencyCode} · ${restaurant.taxRate.toStringAsFixed(restaurant.taxRate % 1 == 0 ? 0 : 2)}% tax',
                style: AppType.caption.copyWith(color: p.textTertiary),
              ),
            ],
          ),
          const Spacer(),
          _StaffChip(staff: staff),
          const SizedBox(width: Space.xs),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            icon: Icon(Icons.logout_rounded, size: 20, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StaffChip extends StatelessWidget {
  const _StaffChip({required this.staff});

  final Staff staff;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(Space.xxs, Space.xxs, Space.sm, Space.xxs),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: Radii.pill,
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: p.brandSubtle, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(staff.initials,
                style: AppType.caption.copyWith(color: p.brand)),
          ),
          const SizedBox(width: Space.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(staff.name,
                  style: AppType.caption.copyWith(color: p.textPrimary)),
              Text(staff.role.label,
                  style: AppType.caption.copyWith(color: p.textTertiary, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Honest placeholder: says which shell you are in and what is coming to it,
/// rather than faking an interface that does nothing.
class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.shell,
    required this.icon,
    required this.blurb,
    required this.phase,
    required this.coming,
  });

  final String shell;
  final IconData icon;
  final String blurb;
  final String phase;
  final List<String> coming;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Center(
      child: SingleChildScrollView(
        padding: Space.screen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: p.brandSubtle,
                  borderRadius: Radii.large,
                ),
                child: Icon(icon, color: p.brand, size: 26),
              ),
              const SizedBox(height: Space.md),
              Text(shell, style: AppType.headline.copyWith(color: p.textPrimary)),
              const SizedBox(height: Space.xxs),
              Text(blurb, style: AppType.body.copyWith(color: p.textSecondary)),
              const SizedBox(height: Space.xl),
              Container(
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: Radii.large,
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('COMING IN',
                            style: AppType.overline.copyWith(color: p.textTertiary)),
                        const SizedBox(width: Space.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Space.xs, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.brandSubtle,
                            borderRadius: Radii.pill,
                          ),
                          child: Text(phase.toUpperCase(),
                              style: AppType.overline.copyWith(color: p.brand)),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    for (final item in coming)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: p.textTertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.xs),
                            Expanded(
                              child: Text(item,
                                  style: AppType.small
                                      .copyWith(color: p.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
