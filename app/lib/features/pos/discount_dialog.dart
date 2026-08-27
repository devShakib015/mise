import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/session.dart';

Future<void> showDiscountDialog(BuildContext context, Order order) =>
    showDialog<void>(
      context: context,
      builder: (_) => _DiscountDialog(order: order),
    );

/// Discounts come off the subtotal before service and tax, and are always
/// recorded against a name — this is one of the two ways money leaves a
/// restaurant without anyone noticing.
class _DiscountDialog extends ConsumerStatefulWidget {
  const _DiscountDialog({required this.order});

  final Order order;

  @override
  ConsumerState<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends ConsumerState<_DiscountDialog> {
  late final _amount = TextEditingController(
    text: widget.order.discountAmount > 0
        ? widget.order.discountAmount.toStringAsFixed(2)
        : '',
  );
  late final _reason =
      TextEditingController(text: widget.order.discountReason);

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text.trim()) ?? 0;

  void _percent(int pct) {
    final v = widget.order.subtotal * pct / 100;
    setState(() => _amount.text = v.toStringAsFixed(2));
  }

  Future<void> _save() async {
    final amount = _value;
    if (amount < 0) {
      setState(() => _error = 'A discount cannot be negative.');
      return;
    }
    if (amount > widget.order.subtotal) {
      setState(() => _error =
          'That is more than the ${widget.order.subtotal.toStringAsFixed(2)} '
          'subtotal.');
      return;
    }
    if (amount > 0 && _reason.text.trim().isEmpty) {
      setState(() => _error = 'Say why — this goes in the audit trail.');
      return;
    }

    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(serviceRepositoryProvider).applyDiscount(
            order: widget.order,
            amount: amount,
            reason: _reason.text,
            staffId: staff.id,
          );
      if (mounted) Navigator.of(context).pop();
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

    return FormDialog(
      title: 'Discount',
      busy: _busy,
      error: _error,
      saveLabel: 'Apply',
      onSave: _save,
      children: [
        Row(
          children: [
            Text('Subtotal', style: AppType.body.copyWith(color: p.textSecondary)),
            const Spacer(),
            Text('$symbol${widget.order.subtotal.toStringAsFixed(2)}',
                style: AppType.money.copyWith(color: p.textPrimary)),
          ],
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final pct in [5, 10, 15, 20, 50])
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                ),
                onPressed: _busy ? null : () => _percent(pct),
                child: Text('$pct%'),
              ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: Space.sm),
              ),
              onPressed: _busy ? null : () => setState(() => _amount.text = ''),
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        AppField(
          label: 'Amount off',
          controller: _amount,
          enabled: !_busy,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: (_) => setState(() {}),
          prefix: Padding(
            padding: const EdgeInsets.only(left: Space.sm, right: Space.xxs),
            child: Center(
              widthFactor: 1,
              child: Text(symbol,
                  style: AppType.body.copyWith(color: p.textTertiary)),
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        AppField(
          label: 'Reason',
          controller: _reason,
          hint: 'Staff meal, complaint, loyalty',
          enabled: !_busy,
          helper: 'Recorded against your name.',
        ),
        if (_value > 0) ...[
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Text('New subtotal',
                  style: AppType.bodyStrong.copyWith(color: p.textPrimary)),
              const Spacer(),
              Text(
                '$symbol${(widget.order.subtotal - _value).clamp(0, double.infinity).toStringAsFixed(2)}',
                style: AppType.moneyLarge.copyWith(color: p.brand),
              ),
            ],
          ),
          Text('Service and tax are worked out from this.',
              style: AppType.small.copyWith(color: p.textTertiary)),
        ],
      ],
    );
  }
}
