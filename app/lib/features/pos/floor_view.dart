import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/session.dart';
import 'pos_shell.dart';

/// The room at a glance. Tap a free table to seat a party, tap a busy one to
/// pick its bill back up.
class FloorView extends ConsumerWidget {
  const FloorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tablesProvider);
    final orders = ref.watch(liveOrdersProvider);

    // Orders not tied to a table — takeaway and delivery.
    final counterOrders = (orders.value ?? const <Order>[])
        .where((o) => o.tableId.isEmpty)
        .toList();

    return Column(
      children: [
        PageHeader(
          title: 'Floor',
          subtitle: 'Tap a table to open or pick up its bill.',
          action: FilledButton.icon(
            onPressed: () => _startTakeaway(context, ref),
            icon: const Icon(Icons.takeout_dining_outlined, size: 18),
            label: const Text('Takeaway'),
          ),
        ),
        Expanded(
          child: AsyncView<List<DiningTable>>(
            value: tables,
            onRetry: () => ref.invalidate(tablesProvider),
            data: (all) {
              final active = all.where((t) => t.active).toList();

              if (active.isEmpty && counterOrders.isEmpty) {
                return const EmptyState(
                  icon: Icons.table_restaurant_outlined,
                  title: 'No tables set up',
                  message:
                      'A manager can add tables under Floor → Tables. You can '
                      'still take takeaway orders in the meantime.',
                );
              }

              final byTable = <String, Order>{};
              for (final o in orders.value ?? const <Order>[]) {
                if (o.tableId.isNotEmpty) byTable[o.tableId] = o;
              }

              final zones = <String, List<DiningTable>>{};
              for (final t in active) {
                zones.putIfAbsent(t.zone.trim(), () => []).add(t);
              }
              final keys = zones.keys.toList()
                ..sort((a, b) => a.isEmpty ? 1 : (b.isEmpty ? -1 : a.compareTo(b)));

              return ListView(
                padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xxl),
                children: [
                  for (final zone in keys) ...[
                    if (keys.length > 1 || zone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.xs),
                        child: Text(
                          (zone.isEmpty ? 'Dining room' : zone).toUpperCase(),
                          style: AppType.overline
                              .copyWith(color: context.palette.textTertiary),
                        ),
                      ),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        for (final t in zones[zone]!)
                          _TableTile(
                            table: t,
                            order: byTable[t.id],
                            onTap: () => _openTable(context, ref, t, byTable[t.id]),
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.lg),
                  ],
                  if (counterOrders.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: Text(
                        'TAKEAWAY',
                        style: AppType.overline
                            .copyWith(color: context.palette.textTertiary),
                      ),
                    ),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        for (final o in counterOrders)
                          _CounterTile(
                            order: o,
                            onTap: () => ref
                                .read(activeOrderIdProvider.notifier)
                                .set(o.id),
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openTable(
    BuildContext context,
    WidgetRef ref,
    DiningTable table,
    Order? existing,
  ) async {
    if (existing != null) {
      ref.read(activeOrderIdProvider.notifier).set(existing.id);
      return;
    }

    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    final guests = await showDialog<int>(
      context: context,
      builder: (_) => _GuestCountDialog(table: table),
    );
    if (guests == null) return;

    try {
      final order = await ref.read(serviceRepositoryProvider).openOrder(
            staffId: staff.id,
            type: OrderType.dineIn,
            tableId: table.id,
            guestCount: guests,
          );
      ref.read(activeOrderIdProvider.notifier).set(order.id);
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open the table: $err')));
      }
    }
  }

  Future<void> _startTakeaway(BuildContext context, WidgetRef ref) async {
    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    try {
      final order = await ref.read(serviceRepositoryProvider).openOrder(
            staffId: staff.id,
            type: OrderType.takeaway,
          );
      ref.read(activeOrderIdProvider.notifier).set(order.id);
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not start the order: $err')));
      }
    }
  }
}

class _TableTile extends ConsumerWidget {
  const _TableTile({required this.table, required this.order, required this.onTap});

  final DiningTable table;
  final Order? order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';
    final busy = order != null;

    // A table needing clearing is called out even with no bill on it, so it
    // does not quietly sit dirty through a service.
    final needsClearing = !busy && table.status == TableStatus.cleaning;

    final (border, tint) = busy
        ? (p.brand, p.brandSubtle)
        : needsClearing
            ? (p.warning, p.warningSubtle)
            : (p.border, p.surface);

    return SizedBox(
      width: 150,
      height: 108,
      child: Material(
        color: tint,
        borderRadius: Radii.large,
        child: InkWell(
          borderRadius: Radii.large,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              borderRadius: Radii.large,
              border: Border.all(color: border, width: busy ? 1.5 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(table.label,
                        style: AppType.subtitle.copyWith(color: p.textPrimary)),
                    const Spacer(),
                    Text('${table.seats}',
                        style: AppType.small.copyWith(color: p.textTertiary)),
                    const SizedBox(width: 2),
                    Icon(Icons.person_outline, size: 13, color: p.textTertiary),
                  ],
                ),
                const Spacer(),
                if (busy) ...[
                  Text(
                    '$symbol${order!.total.toStringAsFixed(2)}',
                    style: AppType.money.copyWith(color: p.textPrimary),
                  ),
                  Text(
                    '#${order!.number} · ${_elapsed(order!.created)}',
                    style: AppType.caption.copyWith(color: p.textSecondary),
                  ),
                ] else
                  Text(
                    needsClearing ? 'Needs clearing' : 'Free',
                    style: AppType.small.copyWith(
                      color: needsClearing ? p.warning : p.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterTile extends ConsumerWidget {
  const _CounterTile({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';

    return SizedBox(
      width: 150,
      height: 108,
      child: Material(
        color: p.brandSubtle,
        borderRadius: Radii.large,
        child: InkWell(
          borderRadius: Radii.large,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              borderRadius: Radii.large,
              border: Border.all(color: p.brand, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('#${order.number}',
                        style: AppType.subtitle.copyWith(color: p.textPrimary)),
                    const Spacer(),
                    Icon(Icons.takeout_dining_outlined,
                        size: 14, color: p.textTertiary),
                  ],
                ),
                const Spacer(),
                Text(
                  '$symbol${order.total.toStringAsFixed(2)}',
                  style: AppType.money.copyWith(color: p.textPrimary),
                ),
                Text(
                  _elapsed(order.created),
                  style: AppType.caption.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How long a bill has been open, in the shorthand a busy floor reads at a
/// glance.
String _elapsed(DateTime from) {
  final minutes = DateTime.now().difference(from).inMinutes;
  if (minutes < 1) return 'just now';
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  return '${hours}h ${minutes % 60}m';
}

class _GuestCountDialog extends StatefulWidget {
  const _GuestCountDialog({required this.table});

  final DiningTable table;

  @override
  State<_GuestCountDialog> createState() => _GuestCountDialogState();
}

class _GuestCountDialogState extends State<_GuestCountDialog> {
  late int _guests = widget.table.seats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AlertDialog(
      title: Text('Seat ${widget.table.label}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How many guests?',
              style: AppType.small.copyWith(color: p.textSecondary)),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (var n = 1; n <= 12; n++)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    color: n == _guests ? p.brand : p.surfaceSunken,
                    borderRadius: Radii.medium,
                    child: InkWell(
                      borderRadius: Radii.medium,
                      onTap: () => setState(() => _guests = n),
                      child: Center(
                        child: Text(
                          '$n',
                          style: AppType.bodyStrong.copyWith(
                            color: n == _guests ? p.onBrand : p.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_guests),
          child: const Text('Open bill'),
        ),
      ],
    );
  }
}
