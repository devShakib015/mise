import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/message_banner.dart';
import '../../data/models/money.dart';
import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/session.dart';
import 'receipt_dialog.dart';

Future<void> showPaymentSheet(BuildContext context, Order order) =>
    showDialog<void>(
      context: context,
      builder: (_) => _PaymentSheet(orderId: order.id),
    );

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.orderId});

  final String orderId;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  PaymentMethod _method = PaymentMethod.cash;
  final _amount = TextEditingController();
  final _tendered = TextEditingController();
  final _reference = TextEditingController();

  bool _busy = false;
  String? _error;
  bool _amountTouched = false;

  @override
  void dispose() {
    _amount.dispose();
    _tendered.dispose();
    _reference.dispose();
    super.dispose();
  }

  double get _amountValue => double.tryParse(_amount.text.trim()) ?? 0;
  double get _tenderedValue => double.tryParse(_tendered.text.trim()) ?? 0;

  Future<void> _take(Order order, double owing) async {
    final amount = _amountValue;

    if (amount <= 0) {
      setState(() => _error = 'Enter how much is being paid.');
      return;
    }
    // Taking more than is owed would overstate the day's takings. Change is
    // handled through the tendered field instead.
    if (amount > owing + 0.004) {
      setState(() => _error =
          'That is more than the ${_fmt(owing)} still owing. Put the extra in '
          'Cash received and the change is worked out for you.');
      return;
    }

    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final tendered = _method.isCash && _tenderedValue > amount ? _tenderedValue : 0.0;

    try {
      await ref.read(serviceRepositoryProvider).takePayment(
            orderId: order.id,
            method: _method,
            amount: amount,
            staffId: staff.id,
            tendered: tendered,
            changeDue: tendered > 0 ? tendered - amount : 0,
            reference: _reference.text,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _amountTouched = false;
        _amount.clear();
        _tendered.clear();
        _reference.clear();
      });
    } catch (err) {
      setState(() {
        _busy = false;
        _error = '$err';
      });
    }
  }

  String _fmt(double v) {
    final symbol = ref.read(currentRestaurantProvider)?.currencySymbol ?? '';
    return '$symbol${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final orderAsync = ref.watch(orderProvider(widget.orderId));
    final payments = ref.watch(paymentsProvider(widget.orderId)).value ?? const <Payment>[];
    final order = orderAsync.value;

    if (order == null) {
      return const Dialog(
        child: SizedBox(
          height: 160,
          child: Center(
            child: SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        ),
      );
    }

    final owing = (order.total - order.paidAmount).clamp(0.0, double.infinity);
    final settled = order.paid;

    // Default the amount to whatever is left, until the cashier types.
    if (!_amountTouched && !settled && _amount.text.isEmpty && owing > 0) {
      _amount.text = owing.toStringAsFixed(2);
    }

    final change = _method.isCash && _tenderedValue > _amountValue
        ? _tenderedValue - _amountValue
        : 0.0;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(order: order, onClose: () => Navigator.of(context).pop()),
            Divider(height: 1, color: p.border),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(Space.lg),
                children: [
                  _Summary(order: order, owing: owing),
                  if (payments.isNotEmpty) ...[
                    const SizedBox(height: Space.md),
                    _TakenSoFar(payments: payments, orderId: order.id),
                  ],
                  if (!settled) ...[
                    const SizedBox(height: Space.lg),
                    _MethodPicker(
                      selected: _method,
                      enabled: !_busy,
                      onChanged: (m) => setState(() {
                        _method = m;
                        _tendered.clear();
                        _error = null;
                      }),
                    ),
                    const SizedBox(height: Space.md),
                    AppField(
                      label: 'Amount',
                      controller: _amount,
                      enabled: !_busy,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onChanged: (_) => setState(() => _amountTouched = true),
                      helper: 'Leave as it is to settle the bill in full.',
                    ),
                    if (_method.isCash) ...[
                      const SizedBox(height: Space.md),
                      AppField(
                        label: 'Cash received',
                        controller: _tendered,
                        enabled: !_busy,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: Space.xs),
                      _QuickTender(
                        owing: _amountValue > 0 ? _amountValue : owing,
                        onPick: (v) => setState(() =>
                            _tendered.text = v.toStringAsFixed(2)),
                      ),
                      if (change > 0) ...[
                        const SizedBox(height: Space.md),
                        _ChangeDue(amount: change, format: _fmt),
                      ],
                    ] else ...[
                      const SizedBox(height: Space.md),
                      AppField(
                        label: 'Reference',
                        controller: _reference,
                        hint: 'Optional — last 4 digits, transaction id',
                        enabled: !_busy,
                      ),
                    ],
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: Space.md),
                    MessageBanner(message: _error!),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: settled
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showReceiptDialog(context, order.id),
                            icon: const Icon(Icons.receipt_long_outlined, size: 18),
                            label: const Text('Receipt'),
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        IconButton(
                          tooltip: 'Receipt',
                          onPressed: () => showReceiptDialog(context, order.id),
                          icon: Icon(Icons.receipt_long_outlined,
                              size: 20, color: p.textSecondary),
                        ),
                        const SizedBox(width: Space.xxs),
                        Expanded(
                          child: SizedBox(
                            height: Hit.button,
                            child: FilledButton(
                              onPressed:
                                  _busy ? null : () => _take(order, owing),
                              child: _busy
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.2),
                                    )
                                  : Text('Take ${_fmt(_amountValue)}'),
                            ),
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
}

class _Header extends StatelessWidget {
  const _Header({required this.order, required this.onClose});

  final Order order;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, Space.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              order.paid ? 'Bill #${order.number} settled' : 'Settle bill #${order.number}',
              style: AppType.subtitle.copyWith(color: p.textPrimary),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 20, color: p.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.order, required this.owing});

  final Order order;
  final double owing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';
    final settled = order.paid;

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: settled ? p.successSubtle : p.surfaceSunken,
        borderRadius: Radii.large,
        border: Border.all(color: settled ? p.success : p.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Total', style: AppType.body.copyWith(color: p.textSecondary)),
              const Spacer(),
              Text('$symbol${order.total.toStringAsFixed(2)}',
                  style: AppType.money.copyWith(color: p.textSecondary)),
            ],
          ),
          if (order.paidAmount > 0) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Text('Paid', style: AppType.body.copyWith(color: p.textSecondary)),
                const Spacer(),
                Text('$symbol${order.paidAmount.toStringAsFixed(2)}',
                    style: AppType.money.copyWith(color: p.textSecondary)),
              ],
            ),
          ],
          const SizedBox(height: Space.xs),
          Divider(height: 1, color: p.border),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Text(
                settled ? 'Settled' : 'Still owing',
                style: AppType.bodyStrong.copyWith(
                  color: settled ? p.success : p.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                settled ? '—' : '$symbol${owing.toStringAsFixed(2)}',
                style: AppType.moneyLarge.copyWith(
                  color: settled ? p.success : p.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TakenSoFar extends ConsumerWidget {
  const _TakenSoFar({required this.payments, required this.orderId});

  final List<Payment> payments;
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Taken so far',
            style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        for (final pay in payments)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(_icon(pay.method), size: 15, color: p.textTertiary),
                const SizedBox(width: Space.xs),
                Text(pay.method.label,
                    style: AppType.body.copyWith(color: p.textPrimary)),
                if (pay.reference.isNotEmpty) ...[
                  const SizedBox(width: Space.xs),
                  Text(pay.reference,
                      style: AppType.small.copyWith(color: p.textTertiary)),
                ],
                const Spacer(),
                Text('$symbol${pay.amount.toStringAsFixed(2)}',
                    style: AppType.money.copyWith(fontSize: 14, color: p.textPrimary)),
                IconButton(
                  tooltip: 'Remove this payment',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    final staff = ref.read(currentStaffProvider);
                    if (staff == null) return;
                    await ref.read(serviceRepositoryProvider).voidPayment(
                          payment: pay,
                          staffId: staff.id,
                        );
                  },
                  icon: Icon(Icons.close_rounded, size: 15, color: p.textTertiary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static IconData _icon(PaymentMethod m) => switch (m) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.mobile => Icons.smartphone_rounded,
        PaymentMethod.voucher => Icons.confirmation_number_outlined,
        PaymentMethod.other => Icons.more_horiz_rounded,
      };
}

class _MethodPicker extends StatelessWidget {
  const _MethodPicker({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final bool enabled;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How are they paying?',
            style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final m in PaymentMethod.values)
              Material(
                color: m == selected ? p.brandSubtle : p.surfaceSunken,
                borderRadius: Radii.medium,
                child: InkWell(
                  borderRadius: Radii.medium,
                  onTap: enabled ? () => onChanged(m) : null,
                  child: Container(
                    height: Hit.control,
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    decoration: BoxDecoration(
                      borderRadius: Radii.medium,
                      border: Border.all(
                        color: m == selected ? p.brand : p.border,
                        width: m == selected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        m.label,
                        style: AppType.bodyStrong.copyWith(
                          color: m == selected ? p.brand : p.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The notes a cashier is most likely to be handed, so the common case is one
/// tap instead of typing.
class _QuickTender extends ConsumerWidget {
  const _QuickTender({required this.owing, required this.onPick});

  final double owing;
  final ValueChanged<double> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';

    final options = <double>{owing};
    for (final step in [50, 100, 500, 1000, 2000]) {
      final rounded = (owing / step).ceil() * step.toDouble();
      if (rounded > owing) options.add(rounded);
      if (options.length >= 5) break;
    }
    final sorted = options.toList()..sort();

    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final v in sorted)
          Material(
            color: p.surfaceSunken,
            borderRadius: Radii.medium,
            child: InkWell(
              borderRadius: Radii.medium,
              onTap: () => onPick(v),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                decoration: BoxDecoration(
                  borderRadius: Radii.medium,
                  border: Border.all(color: p.border),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    v == owing ? 'Exact' : '$symbol${v.toStringAsFixed(0)}',
                    style: AppType.body.copyWith(color: p.textPrimary),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChangeDue extends StatelessWidget {
  const _ChangeDue({required this.amount, required this.format});

  final double amount;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: p.warningSubtle,
        borderRadius: Radii.large,
        border: Border.all(color: p.warning),
      ),
      child: Row(
        children: [
          Text('Change due',
              style: AppType.bodyStrong.copyWith(color: p.textPrimary)),
          const Spacer(),
          Text(format(amount),
              style: AppType.moneyLarge.copyWith(color: p.warning)),
        ],
      ),
    );
  }
}
