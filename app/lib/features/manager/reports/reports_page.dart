import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reporting/report_csv.dart';
import '../../../core/reporting/sales_breakdown.dart';
import '../../../core/reporting/sales_report.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/ui_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../data/models/service.dart';
import '../../../data/repositories/service_repository.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../data/session.dart';
import '../../pos/report_summary.dart';

/// How many days back the report is looking. Zero is today.
final _dayOffsetProvider = uiValue<int>(0);

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final offset = ref.watch(_dayOffsetProvider);
    final day = DateTime.now().subtract(Duration(days: offset));
    final range = DateRange.day(day);

    final orders = ref.watch(closedOrdersProvider(range));
    final payments = ref.watch(rangePaymentsProvider(range));
    final lines = ref.watch(closedOrderLinesProvider(range));
    final staff = ref.watch(staffListProvider).value ?? const [];
    final restaurant = ref.watch(currentRestaurantProvider);

    return Column(
      children: [
        PageHeader(
          title: 'Reports',
          subtitle: 'What each day came to.',
          action: OutlinedButton.icon(
            onPressed: (orders.value ?? const <Order>[]).isEmpty || restaurant == null
                ? null
                : () => _export(
                      context,
                      restaurant: restaurant,
                      report: SalesReport.from(
                        orders: orders.value ?? const [],
                        payments: payments.value ?? const [],
                      ),
                      breakdown: SalesBreakdown.from(
                        orders: orders.value ?? const [],
                        lines: lines.value ?? const [],
                        staff: staff,
                      ),
                      day: day,
                    ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Export CSV'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.md),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Earlier',
                onPressed: () =>
                    ref.read(_dayOffsetProvider.notifier).set(offset + 1),
                icon: Icon(Icons.chevron_left_rounded,
                    size: 22, color: p.textSecondary),
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
                    size: 22,
                    color: offset == 0 ? p.textTertiary : p.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<Order>>(
            value: orders,
            onRetry: () => ref.invalidate(closedOrdersProvider(range)),
            data: (list) {
              final report = SalesReport.from(
                orders: list,
                payments: payments.value ?? const [],
              );
              final breakdown = SalesBreakdown.from(
                orders: list,
                lines: lines.value ?? const [],
                staff: staff,
              );

              if (report.billCount == 0 && report.cancelledCount == 0) {
                return EmptyState(
                  icon: Icons.insights_rounded,
                  title: offset == 0 ? 'Nothing yet today' : 'Nothing that day',
                  message: 'Settled bills show up here as they are paid.',
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    Space.xl, 0, Space.xl, Space.xxl),
                children: [
                  // Align first: a ListView hands its children a *tight* width,
                  // so a bare ConstrainedBox cannot narrow them and the figures
                  // end up a screen away from their labels.
                  Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ReportSummary(report: report),
                          if (breakdown.byItem.isNotEmpty) ...[
                            const SizedBox(height: Space.lg),
                            _Breakdown(
                              title: 'What sold',
                              countHeading: 'Qty',
                              rows: breakdown.byItem,
                            ),
                          ],
                          if (breakdown.byStaff.isNotEmpty) ...[
                            const SizedBox(height: Space.lg),
                            _Breakdown(
                              title: 'Who served it',
                              countHeading: 'Bills',
                              rows: breakdown.byStaff,
                            ),
                          ],
                          if (breakdown.byHour.isNotEmpty) ...[
                            const SizedBox(height: Space.lg),
                            _ByHour(breakdown: breakdown),
                          ],
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

  Future<void> _export(
    BuildContext context, {
    required restaurant,
    required SalesReport report,
    required SalesBreakdown breakdown,
    required DateTime day,
  }) async {
    final csv = ReportCsv.build(
      restaurant: restaurant,
      report: report,
      breakdown: breakdown,
      day: day,
    );

    try {
      // A BOM so spreadsheets open UTF-8 correctly rather than mangling any
      // non-ASCII item names.
      final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
      final saved = await FilePicker.saveFile(
        fileName: ReportCsv.fileName(restaurant, day),
        bytes: bytes,
        mimeType: 'text/csv',
        dialogTitle: 'Save sales report',
      );

      if (!context.mounted) return;
      if (saved != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Report saved.')));
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $err')));
      }
    }
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

class _Breakdown extends ConsumerWidget {
  const _Breakdown({
    required this.title,
    required this.countHeading,
    required this.rows,
  });

  final String title;
  final String countHeading;
  final List<BreakdownRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(title.toUpperCase(),
                style: AppType.overline.copyWith(color: p.textTertiary)),
            const Spacer(),
            Text(countHeading.toUpperCase(),
                style: AppType.overline.copyWith(color: p.textTertiary)),
            const SizedBox(width: Space.xl),
          ],
        ),
        const SizedBox(height: Space.xs),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(r.label,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body.copyWith(color: p.textPrimary)),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${r.count}',
                    textAlign: TextAlign.right,
                    style: AppType.money.copyWith(fontSize: 14, color: p.textTertiary),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    '$symbol${r.value.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: AppType.money.copyWith(fontSize: 14, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Takings per hour as bars, so the shape of a service is visible at a glance
/// rather than having to be read off a column of numbers.
class _ByHour extends ConsumerWidget {
  const _ByHour({required this.breakdown});

  final SalesBreakdown breakdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';

    final peak = breakdown.byHour
        .map((r) => r.value)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('BY HOUR',
                style: AppType.overline.copyWith(color: p.textTertiary)),
            const Spacer(),
            if (breakdown.busiestHour != null)
              Text(
                'busiest ${breakdown.busiestHour.toString().padLeft(2, '0')}:00',
                style: AppType.caption.copyWith(color: p.textTertiary),
              ),
          ],
        ),
        const SizedBox(height: Space.xs),
        for (final r in breakdown.byHour)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(r.label,
                      style: AppType.small.copyWith(color: p.textSecondary)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: peak == 0 ? 0 : r.value / peak,
                      minHeight: 8,
                      backgroundColor: p.surfaceSunken,
                      valueColor: AlwaysStoppedAnimation(p.brand),
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    '$symbol${r.value.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: AppType.money.copyWith(fontSize: 14, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
