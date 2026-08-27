import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/session.dart';
import 'pos_shell.dart';

/// The running bill. Every figure below the lines comes back from the server —
/// the app never adds a bill up itself.
class TicketPanel extends ConsumerWidget {
  const TicketPanel({super.key, required this.order, this.onDone});

  final Order order;

  /// Called after the bill is sent from a modal, so it can close itself.
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final lines = ref.watch(orderLinesProvider(order.id));
    final live = lines.value ?? const <OrderLine>[];
    final unsent = live.where((l) => !l.isVoid && !l.isSent).length;

    return Container(
      color: p.surface,
      child: Column(
        children: [
          Expanded(
            child: live.isEmpty
                ? _EmptyTicket(loading: lines.isLoading)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: Space.xs),
                    itemCount: live.length,
                    itemBuilder: (context, i) => _LineRow(
                      line: live[i],
                      onTap: () => _lineActions(context, ref, live[i]),
                    ),
                  ),
          ),
          Divider(height: 1, color: p.border),
          _Totals(order: order),
          Divider(height: 1, color: p.border),
          Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: Hit.button,
                  child: FilledButton.icon(
                    onPressed: unsent == 0
                        ? null
                        : () => _send(context, ref),
                    icon: const Icon(Icons.local_fire_department_rounded, size: 18),
                    label: Text(
                      unsent == 0
                          ? 'Nothing new to send'
                          : 'Send $unsent to the kitchen',
                    ),
                  ),
                ),
                const SizedBox(height: Space.xs),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(activeOrderIdProvider.notifier).set(null);
                          onDone?.call();
                        },
                        child: const Text('Back to floor'),
                      ),
                    ),
                    const SizedBox(width: Space.xs),
                    IconButton(
                      tooltip: 'Cancel this bill',
                      onPressed: () => _cancel(context, ref),
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 20, color: p.danger),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    try {
      final sent = await ref.read(serviceRepositoryProvider).sendToKitchen(
            orderId: order.id,
            staffId: staff.id,
          );
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent == 1
              ? '1 item sent to the kitchen'
              : '$sent items sent to the kitchen'),
        ),
      );
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not send: $err')));
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    final ok = await confirmDestructive(
      context,
      title: 'Cancel bill #${order.number}?',
      message: 'The whole bill is voided and the table freed. This is recorded '
          'against your name.',
      confirmLabel: 'Cancel bill',
    );
    if (!ok || !context.mounted) return;

    try {
      await ref.read(serviceRepositoryProvider).cancelOrder(
            order: order,
            staffId: staff.id,
            reason: 'Cancelled at the till',
          );
      ref.read(activeOrderIdProvider.notifier).set(null);
      onDone?.call();
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not cancel: $err')));
      }
    }
  }

  Future<void> _lineActions(
      BuildContext context, WidgetRef ref, OrderLine line) async {
    if (line.isVoid) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _LineActionsDialog(line: line),
    );
  }
}

class _EmptyTicket extends StatelessWidget {
  const _EmptyTicket({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (loading) {
      return const Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 30, color: p.textTertiary),
            const SizedBox(height: Space.sm),
            Text('Nothing on this bill yet',
                style: AppType.bodyStrong.copyWith(color: p.textSecondary)),
            const SizedBox(height: 2),
            Text(
              'Tap items on the left to add them.',
              textAlign: TextAlign.center,
              style: AppType.small.copyWith(color: p.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineRow extends ConsumerWidget {
  const _LineRow({required this.line, required this.onTap});

  final OrderLine line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';

    final dimmed = line.isVoid;
    final nameColor = dimmed ? p.textTertiary : p.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.sm, vertical: Space.xs + 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quantity badge. Filled once the kitchen has it, so a waiter can
            // see at a glance what is already cooking.
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: line.isSent ? p.statusPreparing.withValues(alpha: 0.16) : null,
                borderRadius: Radii.small,
                border: Border.all(
                  color: line.isSent ? p.statusPreparing : p.borderStrong,
                ),
              ),
              child: Text(
                '${line.qty}',
                style: AppType.caption.copyWith(
                  color: line.isSent ? p.statusPreparing : p.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.name,
                    style: AppType.body.copyWith(
                      color: nameColor,
                      decoration: dimmed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (line.modifiers.isNotEmpty)
                    Text(
                      line.modifiers.map((m) => m.name).join(', '),
                      style: AppType.small.copyWith(color: p.textTertiary),
                    ),
                  if (line.note.isNotEmpty)
                    Text(
                      line.note,
                      style: AppType.small.copyWith(
                        color: p.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (dimmed)
                    Text('Voided',
                        style: AppType.caption.copyWith(color: p.danger)),
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            Text(
              '$symbol${line.lineTotal.toStringAsFixed(2)}',
              style: AppType.money.copyWith(
                fontSize: 14,
                color: dimmed ? p.textTertiary : p.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Totals extends ConsumerWidget {
  const _Totals({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final restaurant = ref.watch(currentRestaurantProvider);
    final symbol = restaurant?.currencySymbol ?? '';

    Widget row(String label, double value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                label,
                style: strong
                    ? AppType.bodyStrong.copyWith(color: p.textPrimary)
                    : AppType.small.copyWith(color: p.textSecondary),
              ),
              const Spacer(),
              Text(
                '$symbol${value.toStringAsFixed(2)}',
                style: strong
                    ? AppType.moneyLarge.copyWith(color: p.textPrimary, fontSize: 22)
                    : AppType.money.copyWith(fontSize: 14, color: p.textSecondary),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.sm, Space.sm, Space.sm, Space.sm),
      child: Column(
        children: [
          row('Subtotal', order.subtotal),
          if (order.discountAmount > 0) row('Discount', -order.discountAmount),
          if (order.serviceAmount > 0) row('Service charge', order.serviceAmount),
          if (order.taxAmount > 0)
            row(
              restaurant?.taxInclusive == true ? 'Tax (included)' : 'Tax',
              order.taxAmount,
            ),
          const SizedBox(height: Space.xxs),
          Divider(height: Space.sm, color: p.border),
          row('Total', order.total, strong: true),
        ],
      ),
    );
  }
}

class _LineActionsDialog extends ConsumerStatefulWidget {
  const _LineActionsDialog({required this.line});

  final OrderLine line;

  @override
  ConsumerState<_LineActionsDialog> createState() => _LineActionsDialogState();
}

class _LineActionsDialogState extends ConsumerState<_LineActionsDialog> {
  late int _qty = widget.line.qty;
  late final _note = TextEditingController(text: widget.line.note);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(serviceRepositoryProvider);
      if (_qty != widget.line.qty) {
        await repo.setLineQty(widget.line.id, _qty);
      }
      if (_note.text.trim() != widget.line.note) {
        await repo.setLineNote(widget.line.id, _note.text);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      setState(() {
        _busy = false;
        _error = '$err';
      });
    }
  }

  Future<void> _remove() async {
    final line = widget.line;

    // Never sent means nobody has started cooking it, so it can just go.
    // Once sent, removing it is a void that has to be accounted for.
    final ok = await confirmDestructive(
      context,
      title: line.isSent ? 'Void ${line.name}?' : 'Remove ${line.name}?',
      message: line.isSent
          ? 'The kitchen is already making this. Voiding it is recorded against '
              'your name.'
          : 'It has not been sent to the kitchen, so it comes straight off.',
      confirmLabel: line.isSent ? 'Void' : 'Remove',
    );
    if (!ok || !mounted) return;

    final staff = ref.read(currentStaffProvider);
    setState(() => _busy = true);
    try {
      await ref.read(serviceRepositoryProvider).removeLine(
            line,
            staffId: staff?.id ?? '',
            reason: line.isSent ? 'Voided at the till' : '',
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

    return FormDialog(
      title: widget.line.name,
      busy: _busy,
      error: _error,
      onSave: _save,
      onDelete: _remove,
      saveLabel: 'Update',
      children: [
        if (widget.line.isSent)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Text(
              'Already with the kitchen.',
              style: AppType.small.copyWith(color: p.statusPreparing),
            ),
          ),
        Text('Quantity', style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        Row(
          children: [
            for (var n = 1; n <= 10; n++)
              Padding(
                padding: const EdgeInsets.only(right: Space.xxs),
                child: SizedBox(
                  width: 38,
                  height: 40,
                  child: Material(
                    color: n == _qty ? p.brand : p.surfaceSunken,
                    borderRadius: Radii.small,
                    child: InkWell(
                      borderRadius: Radii.small,
                      onTap: _busy ? null : () => setState(() => _qty = n),
                      child: Center(
                        child: Text(
                          '$n',
                          style: AppType.body.copyWith(
                            color: n == _qty ? p.onBrand : p.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.lg),
        AppField(
          label: 'Note for the kitchen',
          controller: _note,
          hint: 'No onions, allergy, well done',
          enabled: !_busy,
        ),
      ],
    );
  }
}
