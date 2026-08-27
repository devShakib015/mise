import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reporting/sales_report.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/message_banner.dart';
import '../../data/models/money.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/session.dart';
import 'report_summary.dart';

/// Opens or closes the shift, depending on whether one is running.
///
/// Which of the two is decided once, here, rather than by watching inside the
/// dialog. A watcher would swap the dialog out from under itself the instant
/// the shift is created, unmounting the state before it could close.
Future<void> showShiftDialog(BuildContext context, WidgetRef ref) {
  final shift = ref.read(activeShiftProvider).value;
  return showDialog<void>(
    context: context,
    builder: (_) => shift == null ? const _OpenShift() : _CloseShift(shift: shift),
  );
}

class _OpenShift extends ConsumerStatefulWidget {
  const _OpenShift();

  @override
  ConsumerState<_OpenShift> createState() => _OpenShiftState();
}

class _OpenShiftState extends ConsumerState<_OpenShift> {
  final _float = TextEditingController(text: '0');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    final float = double.tryParse(_float.text.trim());
    if (float == null || float < 0) {
      setState(() => _error = 'Enter how much is in the drawer to start.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    // Held across the await so closing never depends on this state surviving.
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(serviceRepositoryProvider)
          .openShift(staffId: staff.id, openingCash: float);
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

    return FormDialog(
      title: 'Start your shift',
      busy: _busy,
      error: _error,
      saveLabel: 'Start',
      onSave: _open,
      children: [
        Text(
          'Count the drawer before you take any money. Everything you take from '
          'now on is measured against this number.',
          style: AppType.small.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Space.lg),
        AppField(
          label: 'Cash in the drawer',
          controller: _float,
          autofocus: true,
          enabled: !_busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          prefix: Padding(
            padding: const EdgeInsets.only(left: Space.sm, right: Space.xxs),
            child: Center(
              widthFactor: 1,
              child: Text(symbol,
                  style: AppType.body.copyWith(color: p.textTertiary)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CloseShift extends ConsumerStatefulWidget {
  const _CloseShift({required this.shift});

  final Shift shift;

  @override
  ConsumerState<_CloseShift> createState() => _CloseShiftState();
}

class _CloseShiftState extends ConsumerState<_CloseShift> {
  final _counted = TextEditingController();
  final _note = TextEditingController();

  double? _expected;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExpected();
  }

  @override
  void dispose() {
    _counted.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadExpected() async {
    try {
      final v = await ref
          .read(serviceRepositoryProvider)
          .expectedCashFor(widget.shift);
      if (mounted) setState(() => _expected = v);
    } catch (_) {
      if (mounted) setState(() => _expected = widget.shift.openingCash);
    }
  }

  Future<void> _close() async {
    final staff = ref.read(currentStaffProvider);
    if (staff == null) return;

    final counted = double.tryParse(_counted.text.trim());
    if (counted == null || counted < 0) {
      setState(() => _error = 'Count the drawer and enter the total.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    final rootContext = navigator.context;
    try {
      final closed = await ref.read(serviceRepositoryProvider).closeShift(
            shift: widget.shift,
            countedCash: counted,
            staffId: staff.id,
            note: _note.text,
          );
      navigator.pop();
      // The navigator's context outlives this dialog's own state, which is why
      // it is the one held across the await.
      if (!rootContext.mounted) return;
      await showDialog<void>(
        context: rootContext,
        builder: (_) => _ShiftClosed(shift: closed),
      );
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

    final counted = double.tryParse(_counted.text.trim());
    final variance =
        (_expected != null && counted != null) ? counted - _expected! : null;

    return FormDialog(
      title: 'Close your shift',
      busy: _busy || _expected == null,
      error: _error,
      saveLabel: 'Close shift',
      onSave: _close,
      children: [
        // The expected figure is shown, deliberately, before the count is
        // entered. Hiding it would invite guessing rather than counting.
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: p.surfaceSunken,
            borderRadius: Radii.large,
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              _Row(
                label: 'Opening float',
                value: '$symbol${widget.shift.openingCash.toStringAsFixed(2)}',
              ),
              _Row(
                label: 'Cash taken',
                value: _expected == null
                    ? '—'
                    : '$symbol${(_expected! - widget.shift.openingCash).toStringAsFixed(2)}',
              ),
              const SizedBox(height: Space.xs),
              Divider(height: 1, color: p.border),
              const SizedBox(height: Space.xs),
              _Row(
                label: 'Should be in the drawer',
                value: _expected == null
                    ? '—'
                    : '$symbol${_expected!.toStringAsFixed(2)}',
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        AppField(
          label: 'Counted',
          controller: _counted,
          autofocus: true,
          enabled: !_busy,
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
        if (variance != null && variance.abs() >= 0.005) ...[
          const SizedBox(height: Space.md),
          MessageBanner(
            tone: variance < 0 ? BannerTone.danger : BannerTone.warning,
            message: variance < 0
                ? 'The drawer is $symbol${variance.abs().toStringAsFixed(2)} short.'
                : 'The drawer is $symbol${variance.toStringAsFixed(2)} over.',
          ),
        ],
        const SizedBox(height: Space.md),
        AppField(
          label: 'Note',
          controller: _note,
          hint: 'Optional — anything worth explaining',
          enabled: !_busy,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: strong
                  ? AppType.bodyStrong.copyWith(color: p.textPrimary)
                  : AppType.body.copyWith(color: p.textSecondary)),
          const Spacer(),
          Text(value,
              style: strong
                  ? AppType.moneyLarge.copyWith(color: p.textPrimary, fontSize: 22)
                  : AppType.money.copyWith(fontSize: 14, color: p.textSecondary)),
        ],
      ),
    );
  }
}

/// The Z-report: what the shift came to, shown once it is closed.
class _ShiftClosed extends ConsumerWidget {
  const _ShiftClosed({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final range = DateRange(
      shift.openedAt ?? DateTime.now(),
      shift.closedAt ?? DateTime.now().add(const Duration(minutes: 1)),
    );
    final orders = ref.watch(closedOrdersProvider(range)).value ?? const [];
    final payments = ref.watch(rangePaymentsProvider(range)).value ?? const [];
    final report = SalesReport.from(orders: orders, payments: payments);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shift closed',
                      style: AppType.subtitle.copyWith(color: p.textPrimary)),
                  Text('Here is what it came to.',
                      style: AppType.small.copyWith(color: p.textSecondary)),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.lg),
                child: ReportSummary(report: report, shift: shift),
              ),
            ),
            Divider(height: 1, color: p.border),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
