import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/ui_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../data/models/audit.dart';
import '../../../data/models/staff.dart';
import '../../../data/repositories/service_repository.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../data/session.dart';

final _dayOffsetProvider = uiValue<int>(0);
final _moneyOnlyProvider = uiValue<bool>(false);

/// What staff did, and who did it.
///
/// The log was written from the first day and read by nobody, which made it
/// decoration. This is the half that makes it worth having.
class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final offset = ref.watch(_dayOffsetProvider);
    final moneyOnly = ref.watch(_moneyOnlyProvider);
    final day = DateTime.now().subtract(Duration(days: offset));
    final range = DateRange.day(day);

    final entries = ref.watch(auditProvider(range));
    final staff = ref.watch(staffListProvider).value ?? const <Staff>[];
    final names = {for (final s in staff) s.id: s.name};

    return Column(
      children: [
        PageHeader(
          title: 'Activity',
          subtitle: 'Discounts, voids and cancellations, with a name against each.',
          action: _Toggle(
            label: 'Money leaving only',
            value: moneyOnly,
            onChanged: (v) => ref.read(_moneyOnlyProvider.notifier).set(v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.md),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Earlier',
                onPressed: () => ref.read(_dayOffsetProvider.notifier).set(offset + 1),
                icon: Icon(Icons.chevron_left_rounded, size: 22, color: p.textSecondary),
              ),
              Expanded(
                child: Text(
                  _label(offset, day),
                  textAlign: TextAlign.center,
                  style: AppType.subtitle.copyWith(color: p.textPrimary),
                ),
              ),
              IconButton(
                tooltip: 'Later',
                onPressed: offset == 0
                    ? null
                    : () => ref.read(_dayOffsetProvider.notifier).set(offset - 1),
                icon: Icon(Icons.chevron_right_rounded,
                    size: 22, color: offset == 0 ? p.textTertiary : p.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<AuditEntry>>(
            value: entries,
            onRetry: () => ref.invalidate(auditProvider(range)),
            data: (all) {
              final shown = moneyOnly
                  ? all.where((e) => e.isMoneyLeaving).toList()
                  : all;

              if (shown.isEmpty) {
                return EmptyState(
                  icon: Icons.history_rounded,
                  title: moneyOnly ? 'Nothing given away' : 'Nothing recorded',
                  message: moneyOnly
                      ? 'No discounts, voids or cancellations that day.'
                      : 'Actions worth recording show up here as they happen.',
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xxl),
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final e in shown)
                            _Row(entry: e, who: names[e.staffId] ?? 'Removed'),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static String _label(int offset, DateTime day) {
    if (offset == 0) return 'Today';
    if (offset == 1) return 'Yesterday';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${day.day} ${months[day.month - 1]} ${day.year}';
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.entry, required this.who});

  final AuditEntry entry;
  final String who;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';
    final tone = entry.isMoneyLeaving ? p.warning : p.textTertiary;

    two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(entry.created.hour)}:${two(entry.created.minute)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: Radii.large,
          border: Border.all(
            color: entry.isMoneyLeaving ? p.warning.withValues(alpha: 0.4) : p.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon(entry.action), size: 18, color: tone),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.label,
                      style: AppType.bodyStrong.copyWith(color: p.textPrimary)),
                  Text(
                    '$who · $time',
                    style: AppType.small.copyWith(color: p.textTertiary),
                  ),
                  if (_detail(entry, symbol).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        _detail(entry, symbol),
                        style: AppType.small.copyWith(color: p.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _icon(String action) => switch (action) {
        'discount' => Icons.percent_rounded,
        'void_item' => Icons.remove_circle_outline,
        'void_payment' => Icons.money_off_rounded,
        'cancel_order' => Icons.delete_outline_rounded,
        'move_order' => Icons.swap_horiz_rounded,
        'close_shift' => Icons.lock_outline_rounded,
        'reset_pin' => Icons.password_rounded,
        _ => Icons.local_fire_department_rounded,
      };

  /// Pulls the couple of fields worth reading out of the detail blob, rather
  /// than printing raw JSON at a manager.
  static String _detail(AuditEntry e, String symbol) {
    final d = e.detail;
    money(Object? v) => '$symbol${(double.tryParse('${v ?? 0}') ?? 0).toStringAsFixed(2)}';

    return switch (e.action) {
      'discount' => [
          money(d['amount']),
          if ('${d['reason'] ?? ''}'.isNotEmpty) '“${d['reason']}”',
          if ('${d['number'] ?? ''}'.isNotEmpty) 'on bill #${d['number']}',
        ].join(' · '),
      'cancel_order' => [
          if (d['total'] != null) money(d['total']),
          if ('${d['reason'] ?? ''}'.isNotEmpty) '“${d['reason']}”',
        ].join(' · '),
      'void_payment' => '${d['method'] ?? ''} ${money(d['amount'])}'.trim(),
      'close_shift' => 'expected ${money(d['expected'])}, counted '
          '${money(d['counted'])}, variance ${money(d['variance'])}',
      'reset_pin' => 'for @${d['username'] ?? ''}',
      'move_order' => 'between tables',
      'send_to_kitchen' => '${d['lines'] ?? ''} items',
      _ => '',
    };
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: value ? p.warningSubtle : p.surfaceSunken,
      borderRadius: Radii.medium,
      child: InkWell(
        borderRadius: Radii.medium,
        onTap: () => onChanged(!value),
        child: Container(
          height: Hit.control,
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          decoration: BoxDecoration(
            borderRadius: Radii.medium,
            border: Border.all(color: value ? p.warning : p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(value ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                  size: 16, color: value ? p.warning : p.textSecondary),
              const SizedBox(width: Space.xs),
              Text(label,
                  style: AppType.bodyStrong.copyWith(
                    color: value ? p.warning : p.textPrimary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
