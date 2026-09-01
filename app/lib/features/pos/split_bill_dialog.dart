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

/// Splitting a table's bill.
///
/// Two things get called "splitting" and they are not the same. Paying a share
/// of one bill is a payment; each party having their own bill and their own
/// receipt is a second bill. Both are offered here, because a table asking to
/// "split" could mean either.
Future<void> showSplitDialog(BuildContext context, Order order) =>
    showDialog<void>(
      context: context,
      builder: (_) => _SplitDialog(order: order),
    );

class _SplitDialog extends ConsumerStatefulWidget {
  const _SplitDialog({required this.order});

  final Order order;

  @override
  ConsumerState<_SplitDialog> createState() => _SplitDialogState();
}

class _SplitDialogState extends ConsumerState<_SplitDialog> {
  final _chosen = <String>{};
  bool _busy = false;
  String? _error;

  Future<void> _split() async {
    final staff = ref.read(currentStaffProvider);
    if (staff == null || _chosen.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    try {
      final fresh = await ref.read(serviceRepositoryProvider).splitOrder(
            order: widget.order,
            lineIds: _chosen.toList(),
            staffId: staff.id,
          );
      // Follow the new bill: whoever asked to split is standing there waiting
      // to pay it.
      ref.read(activeOrderIdProvider.notifier).set(fresh);
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
    final lines = (ref.watch(orderLinesProvider(widget.order.id)).value ??
            const <OrderLine>[])
        .where((l) => !l.isVoid)
        .toList();

    final moving = lines
        .where((l) => _chosen.contains(l.id))
        .fold(0.0, (sum, l) => sum + l.lineTotal);

    // Everything cannot leave, or the original bill is left as an empty shell.
    final wouldEmpty = _chosen.length == lines.length && lines.isNotEmpty;

    return FormDialog(
      title: 'Split bill #${widget.order.number}',
      width: 500,
      busy: _busy,
      error: _error,
      saveLabel: 'Move to a new bill',
      onSave: (_chosen.isEmpty || wouldEmpty) ? () {} : _split,
      children: [
        _EvenShare(order: widget.order, symbol: symbol),
        const SizedBox(height: Space.lg),
        Divider(color: p.border),
        const SizedBox(height: Space.md),
        Text('Or give someone their own bill',
            style: AppType.bodyStrong.copyWith(color: p.textPrimary)),
        const SizedBox(height: 2),
        Text(
          'Pick what they had. It moves to a separate bill on the same table, '
          'with its own total and receipt.',
          style: AppType.small.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Space.md),
        for (final l in lines)
          _LineChoice(
            line: l,
            symbol: symbol,
            selected: _chosen.contains(l.id),
            onTap: _busy
                ? null
                : () => setState(() {
                      _chosen.contains(l.id)
                          ? _chosen.remove(l.id)
                          : _chosen.add(l.id);
                    }),
          ),
        if (wouldEmpty) ...[
          const SizedBox(height: Space.md),
          const MessageBanner(
            tone: BannerTone.warning,
            message: 'That is everything. Leave at least one item on the '
                'original bill, or there is nothing to split.',
          ),
        ] else if (_chosen.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Row(
            children: [
              Text('Moving', style: AppType.bodyStrong.copyWith(color: p.textPrimary)),
              const Spacer(),
              Text('$symbol${moving.toStringAsFixed(2)}',
                  style: AppType.moneyLarge.copyWith(color: p.brand)),
            ],
          ),
          Text('Service and tax are worked out on each bill separately.',
              style: AppType.small.copyWith(color: p.textTertiary)),
        ],
      ],
    );
  }
}

/// The common case: one bill, several people, each paying a share. No second
/// bill needed — just the arithmetic nobody wants to do at the table.
class _EvenShare extends StatefulWidget {
  const _EvenShare({required this.order, required this.symbol});

  final Order order;
  final String symbol;

  @override
  State<_EvenShare> createState() => _EvenShareState();
}

class _EvenShareState extends State<_EvenShare> {
  int _ways = 2;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final owing = (widget.order.total - widget.order.paidAmount)
        .clamp(0.0, double.infinity);
    final each = owing / _ways;

    // Rounded to the currency, with any remainder put on the first payer
    // rather than quietly lost.
    final rounded = (each * 100).floor() / 100;
    final remainder = ((owing - rounded * _ways) * 100).round() / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Everyone pays a share',
            style: AppType.bodyStrong.copyWith(color: p.textPrimary)),
        const SizedBox(height: 2),
        Text('One bill, split evenly. Take each share as its own payment.',
            style: AppType.small.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final n in [2, 3, 4, 5, 6])
              Material(
                color: n == _ways ? p.brandSubtle : p.surfaceSunken,
                borderRadius: Radii.medium,
                child: InkWell(
                  borderRadius: Radii.medium,
                  onTap: () => setState(() => _ways = n),
                  child: Container(
                    width: 52,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: Radii.medium,
                      border: Border.all(color: n == _ways ? p.brand : p.border),
                    ),
                    child: Center(
                      child: Text('$n',
                          style: AppType.bodyStrong.copyWith(
                            color: n == _ways ? p.brand : p.textPrimary,
                          )),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Container(
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: p.surfaceSunken,
            borderRadius: Radii.medium,
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              Text('$_ways ways', style: AppType.body.copyWith(color: p.textSecondary)),
              const Spacer(),
              Text('${widget.symbol}${rounded.toStringAsFixed(2)} each',
                  style: AppType.money.copyWith(color: p.textPrimary)),
            ],
          ),
        ),
        if (remainder.abs() >= 0.005)
          Padding(
            padding: const EdgeInsets.only(top: Space.xxs),
            child: Text(
              'The first payer covers the odd ${widget.symbol}'
              '${remainder.abs().toStringAsFixed(2)}.',
              style: AppType.small.copyWith(color: p.textTertiary),
            ),
          ),
      ],
    );
  }
}

class _LineChoice extends StatelessWidget {
  const _LineChoice({
    required this.line,
    required this.symbol,
    required this.selected,
    required this.onTap,
  });

  final OrderLine line;
  final String symbol;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xxs),
      child: Material(
        color: selected ? p.brandSubtle : Colors.transparent,
        borderRadius: Radii.medium,
        child: InkWell(
          borderRadius: Radii.medium,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.xs),
            decoration: BoxDecoration(
              borderRadius: Radii.medium,
              border: Border.all(color: selected ? p.brand : p.border),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 20,
                  color: selected ? p.brand : p.textTertiary,
                ),
                const SizedBox(width: Space.xs),
                Text('${line.qty}×',
                    style: AppType.small.copyWith(color: p.textTertiary)),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.name,
                          style: AppType.body.copyWith(color: p.textPrimary)),
                      if (line.modifiers.isNotEmpty)
                        Text(line.modifiers.map((m) => m.name).join(', '),
                            style: AppType.small.copyWith(color: p.textTertiary)),
                    ],
                  ),
                ),
                Text('$symbol${line.lineTotal.toStringAsFixed(2)}',
                    style: AppType.money.copyWith(fontSize: 14, color: p.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
