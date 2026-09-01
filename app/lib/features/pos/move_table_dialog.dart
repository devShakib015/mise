import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/message_banner.dart';
import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/session.dart';
import 'pos_shell.dart';

/// Moves a bill to another table — or merges it into the bill already there,
/// which is what happens when a party gets up and joins another.
Future<void> showMoveTableDialog(BuildContext context, Order order) =>
    showDialog<void>(
      context: context,
      builder: (_) => _MoveDialog(order: order),
    );

class _MoveDialog extends ConsumerStatefulWidget {
  const _MoveDialog({required this.order});

  final Order order;

  @override
  ConsumerState<_MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends ConsumerState<_MoveDialog> {
  String? _target;
  bool _busy = false;
  String? _error;

  Future<void> _move() async {
    final target = _target;
    final staff = ref.read(currentStaffProvider);
    if (target == null || staff == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    try {
      final surviving = await ref.read(serviceRepositoryProvider).moveOrder(
            order: widget.order,
            toTableId: target,
            staffId: staff.id,
          );
      // A merge closes this bill and keeps the other, so follow whichever
      // survived rather than leaving the till on a cancelled one.
      ref.read(activeOrderIdProvider.notifier).set(surviving);
      navigator.pop();
      return;
    } catch (err) {
      setState(() {
        _busy = false;
        _error = '$err';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';
    final tables = (ref.watch(tablesProvider).value ?? const <DiningTable>[])
        .where((t) => t.active && t.id != widget.order.tableId)
        .toList();

    final open = <String, Order>{};
    for (final o in ref.watch(liveOrdersProvider).value ?? const <Order>[]) {
      if (o.tableId.isNotEmpty && o.id != widget.order.id) open[o.tableId] = o;
    }

    final chosen = _target;
    final mergingInto = chosen == null ? null : open[chosen];

    return FormDialog(
      title: 'Move bill #${widget.order.number}',
      busy: _busy,
      error: _error,
      saveLabel: mergingInto == null ? 'Move' : 'Merge',
      onSave: chosen == null ? () {} : _move,
      children: [
        if (tables.isEmpty)
          Text('There is nowhere else to move it to.',
              style: AppType.body.copyWith(color: p.textTertiary))
        else ...[
          Text('Where to?', style: AppType.label.copyWith(color: p.textSecondary)),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final t in tables)
                _TableChoice(
                  table: t,
                  occupiedBy: open[t.id],
                  symbol: symbol,
                  selected: chosen == t.id,
                  onTap: _busy ? null : () => setState(() => _target = t.id),
                ),
            ],
          ),
          if (mergingInto != null) ...[
            const SizedBox(height: Space.md),
            MessageBanner(
              tone: BannerTone.warning,
              message: 'That table already has bill #${mergingInto.number} open. '
                  'The two will be merged into one, and this bill closed.',
            ),
          ],
        ],
      ],
    );
  }
}

class _TableChoice extends StatelessWidget {
  const _TableChoice({
    required this.table,
    required this.occupiedBy,
    required this.symbol,
    required this.selected,
    required this.onTap,
  });

  final DiningTable table;
  final Order? occupiedBy;
  final String symbol;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final busy = occupiedBy != null;

    return SizedBox(
      width: 116,
      child: Material(
        color: selected ? p.brandSubtle : p.surfaceSunken,
        borderRadius: Radii.medium,
        child: InkWell(
          borderRadius: Radii.medium,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              borderRadius: Radii.medium,
              border: Border.all(
                color: selected ? p.brand : (busy ? p.warning : p.border),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(table.label,
                    style: AppType.bodyStrong.copyWith(
                      color: selected ? p.brand : p.textPrimary,
                    )),
                Text(
                  busy
                      ? '$symbol${occupiedBy!.total.toStringAsFixed(0)} open'
                      : '${table.seats} seats',
                  style: AppType.caption.copyWith(
                    color: busy ? p.warning : p.textTertiary,
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
