import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/models/service.dart';
import '../../data/offline/connection.dart';
import '../../data/offline/pending_writes.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/session.dart';
import 'discount_dialog.dart';
import 'move_table_dialog.dart';
import 'docket_printing.dart';
import 'split_bill_dialog.dart';
import 'payment_sheet.dart';
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
    final live = ref.watch(ticketLinesProvider(order.id));
    final queued = ref.watch(pendingWritesProvider)
        .where((w) => w.orderId == order.id).length;
    final online = ref.watch(isOnlineProvider);
    final unsent = live.where((l) => !l.isVoid && !l.isSent).length;
    final waitingCourses = live
        .where((l) => !l.isVoid && !l.isSent)
        .map((l) => l.course)
        .toSet()
        .toList()
      ..sort();

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
          if (!online || queued > 0)
            _OfflineNotice(queued: queued, online: online),
          _Totals(order: order, provisional: queued > 0),
          Divider(height: 1, color: p.border),
          Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: Column(
              children: [
                // Whatever is next gets the big button: fire the food while
                // there is food to fire, then take the money.
                if (unsent > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    height: Hit.button,
                    child: FilledButton.icon(
                      // Firing needs the server: the kitchen screen is the
                      // thing being written to, and there is no point pressing
                      // a button that cannot reach it.
                      onPressed: online ? () => _send(context, ref) : null,
                      icon: Icon(
                        online
                            ? Icons.local_fire_department_rounded
                            : Icons.cloud_off_rounded,
                        size: 18,
                      ),
                      label: Text(online
                          ? 'Send $unsent to the kitchen'
                          : 'Cannot reach the kitchen'),
                    ),
                  ),
                  // Only offered when the waiting items actually span courses —
                  // a table ordering one round should not be asked to choose.
                  if (waitingCourses.length > 1) ...[
                    const SizedBox(height: Space.xs),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: online
                            ? () => _send(context, ref, course: waitingCourses.first)
                            : null,
                        child: Text('Send ${Course.label(waitingCourses.first).toLowerCase()} only'),
                      ),
                    ),
                  ],
                ]
                else
                  SizedBox(
                    width: double.infinity,
                    height: Hit.button,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: order.paid ? p.success : p.brand,
                      ),
                      onPressed: (live.isEmpty && !order.paid) || queued > 0
                          ? null
                          : () => showPaymentSheet(context, order),
                      icon: Icon(
                        order.paid
                            ? Icons.check_circle_outline_rounded
                            : Icons.payments_outlined,
                        size: 18,
                      ),
                      label: Text(order.paid
                          ? 'Settled — receipt'
                          : queued > 0
                              ? 'Waiting to sync'
                              : 'Settle bill'),
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
                    const SizedBox(width: Space.xxs),
                    if (unsent > 0)
                      IconButton(
                        tooltip: 'Settle bill',
                        onPressed: () => showPaymentSheet(context, order),
                        icon: Icon(Icons.payments_outlined,
                            size: 20, color: p.textSecondary),
                      ),
                    IconButton(
                      tooltip: 'Split this bill',
                      onPressed: (order.paid || live.isEmpty)
                          ? null
                          : () => showSplitDialog(context, order),
                      icon: Icon(Icons.call_split_rounded,
                          size: 20, color: p.textSecondary),
                    ),
                    if (order.tableId.isNotEmpty)
                      IconButton(
                        tooltip: 'Move or merge this bill',
                        onPressed: order.paid
                            ? null
                            : () => showMoveTableDialog(context, order),
                        icon: Icon(Icons.swap_horiz_rounded,
                            size: 20, color: p.textSecondary),
                      ),
                    IconButton(
                      tooltip: order.discountAmount > 0
                          ? 'Discount applied'
                          : 'Apply a discount',
                      onPressed: order.paid
                          ? null
                          : () => showDiscountDialog(context, order),
                      icon: Icon(
                        Icons.percent_rounded,
                        size: 20,
                        color: order.discountAmount > 0 ? p.brand : p.textSecondary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cancel this bill',
                      onPressed: order.paid ? null : () => _cancel(context, ref),
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 20, color: order.paid ? p.textTertiary : p.danger),
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

  Future<void> _send(BuildContext context, WidgetRef ref, {int? course}) async {
    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    try {
      final sent = await ref.read(serviceRepositoryProvider).sendToKitchen(
            orderId: order.id,
            staffId: staff.id,
            onlyCourse: course,
          );
      if (!context.mounted) return;

      // The dockets are a side effect of sending, not a second thing to press.
      final printed = await printDockets(ref, order: order, lines: sent);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text([
            sent.length == 1
                ? '1 item sent to the kitchen'
                : '${sent.length} items sent to the kitchen',
            if (printed.isNotEmpty) printed,
          ].join(' · ')),
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
    // Nothing to edit yet — it exists only in the queue.
    if (isProvisional(line)) return;

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
    final waiting = isProvisional(line);
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
                color: line.isSent
                    ? p.statusPreparing.withValues(alpha: 0.16)
                    : waiting
                        ? p.warning.withValues(alpha: 0.16)
                        : null,
                borderRadius: Radii.small,
                border: Border.all(
                  color: line.isSent
                      ? p.statusPreparing
                      : waiting
                          ? p.warning
                          : p.borderStrong,
                ),
              ),
              child: Text(
                '${line.qty}',
                style: AppType.caption.copyWith(
                  color: line.isSent
                      ? p.statusPreparing
                      : waiting
                          ? p.warning
                          : p.textSecondary,
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
                  if (waiting)
                    Text('Saved here — not sent yet',
                        style: AppType.caption.copyWith(color: p.warning)),
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
  const _Totals({required this.order, this.provisional = false});

  final Order order;

  /// True while writes are queued: the figures below are the server's last
  /// word, not the current bill.
  final bool provisional;

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
          if (provisional)
            Text(
              'Not counting what is still to sync.',
              style: AppType.small.copyWith(color: p.warning),
            ),
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
  late int _course = widget.line.course;
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
      if (_course != widget.line.course) {
        await repo.setLineCourse(widget.line.id, _course);
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
        Text('Course', style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        Row(
          children: [
            for (final c in Course.all)
              Padding(
                padding: const EdgeInsets.only(right: Space.xs),
                child: Material(
                  color: c == _course ? p.brandSubtle : p.surfaceSunken,
                  borderRadius: Radii.small,
                  child: InkWell(
                    borderRadius: Radii.small,
                    onTap: _busy ? null : () => setState(() => _course = c),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                      decoration: BoxDecoration(
                        borderRadius: Radii.small,
                        border: Border.all(color: c == _course ? p.brand : p.border),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(Course.label(c),
                            style: AppType.small.copyWith(
                              color: c == _course ? p.brand : p.textPrimary,
                            )),
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


/// Says plainly what is happening and what still works, rather than a bare
/// error. A waiter mid-service needs to know they can keep taking the order.
class _OfflineNotice extends ConsumerWidget {
  const _OfflineNotice({required this.queued, required this.online});

  final int queued;
  final bool online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tone = online ? p.info : p.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: Space.sm, vertical: Space.xs),
      color: tone.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(online ? Icons.sync_rounded : Icons.cloud_off_rounded,
              size: 16, color: tone),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(
              online
                  ? (queued > 0 ? 'Catching up — $queued to send' : 'Back online')
                  : queued > 0
                      ? "Offline. $queued item${queued == 1 ? '' : 's'} saved here "
                          'and will send when the server is back.'
                      : 'Offline. You can keep taking the order.',
              style: AppType.small.copyWith(color: p.textPrimary),
            ),
          ),
          if (queued > 0)
            TextButton(
              onPressed: () => ref.read(pendingWritesProvider.notifier).flush(),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
