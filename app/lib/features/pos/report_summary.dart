import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reporting/sales_report.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/money.dart';
import '../../data/session.dart';

/// The numbers for a period, laid out the same whether it is a closed shift or
/// a day the manager is looking back at.
class ReportSummary extends ConsumerWidget {
  const ReportSummary({super.key, required this.report, this.shift});

  final SalesReport report;
  final Shift? shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';
    String m(double v) => '$symbol${v.toStringAsFixed(2)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Headline(
          label: 'Takings',
          value: m(report.netTakings),
          caption: report.billCount == 1
              ? '1 bill · average ${m(report.averageBill)}'
              : '${report.billCount} bills · average ${m(report.averageBill)}',
        ),
        const SizedBox(height: Space.lg),

        _Block(
          title: 'How it adds up',
          rows: [
            ('Gross sales', m(report.grossSales)),
            if (report.discounts > 0) ('Discounts', '-${m(report.discounts)}'),
            if (report.serviceCharge > 0) ('Service charge', m(report.serviceCharge)),
            if (report.tax > 0) ('Tax', m(report.tax)),
            ('Takings', m(report.netTakings)),
          ],
          emphasiseLast: true,
        ),

        const SizedBox(height: Space.md),
        _Block(
          title: 'How it was paid',
          rows: report.byMethod.isEmpty
              ? [('Nothing taken', '—')]
              : [
                  for (final e in report.byMethod.entries)
                    (e.key.label, m(e.value)),
                ],
        ),

        if (shift != null) ...[
          const SizedBox(height: Space.md),
          _Block(
            title: 'The drawer',
            rows: [
              ('Opening float', m(shift!.openingCash)),
              ('Cash taken', m(report.cashTaken)),
              ('Expected', m(shift!.expectedCash)),
              ('Counted', m(shift!.closingCash)),
            ],
          ),
          const SizedBox(height: Space.xs),
          _Variance(variance: shift!.variance, format: m),
        ],

        if (report.cancelledCount > 0) ...[
          const SizedBox(height: Space.md),
          _Block(
            title: 'Cancelled',
            rows: [
              (
                report.cancelledCount == 1 ? '1 bill' : '${report.cancelledCount} bills',
                m(report.cancelledValue),
              ),
            ],
          ),
        ],

        // Only shown when it is not zero: a silent gap is the thing you would
        // most want to know about.
        if (report.unreconciled.abs() >= 0.005) ...[
          const SizedBox(height: Space.md),
          Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: p.warningSubtle,
              borderRadius: Radii.medium,
              border: Border.all(color: p.warning),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: p.warning),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(
                    'Payments recorded differ from bills charged by '
                    '${m(report.unreconciled.abs())}.',
                    style: AppType.small.copyWith(color: p.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: p.brandSubtle,
        borderRadius: Radii.large,
        border: Border.all(color: p.brand.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppType.overline.copyWith(color: p.brand)),
          const SizedBox(height: 2),
          Text(value, style: AppType.display.copyWith(color: p.textPrimary)),
          Text(caption, style: AppType.small.copyWith(color: p.textSecondary)),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.rows,
    this.emphasiseLast = false,
  });

  final String title;
  final List<(String, String)> rows;
  final bool emphasiseLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title.toUpperCase(),
            style: AppType.overline.copyWith(color: p.textTertiary)),
        const SizedBox(height: Space.xs),
        for (var i = 0; i < rows.length; i++) ...[
          if (emphasiseLast && i == rows.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: Space.xxs, bottom: Space.xxs),
              child: Divider(height: 1, color: p.border),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  rows[i].$1,
                  style: emphasiseLast && i == rows.length - 1
                      ? AppType.bodyStrong.copyWith(color: p.textPrimary)
                      : AppType.body.copyWith(color: p.textSecondary),
                ),
                const Spacer(),
                Text(
                  rows[i].$2,
                  style: AppType.money.copyWith(
                    fontSize: emphasiseLast && i == rows.length - 1 ? 16 : 14,
                    color: emphasiseLast && i == rows.length - 1
                        ? p.textPrimary
                        : p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Variance extends StatelessWidget {
  const _Variance({required this.variance, required this.format});

  final double variance;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final balanced = variance.abs() < 0.005;
    final short = variance < 0;

    final tone = balanced ? p.success : (short ? p.danger : p.warning);
    final label = balanced
        ? 'The drawer balances'
        : short
            ? 'Short by ${format(variance.abs())}'
            : 'Over by ${format(variance)}';

    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: Radii.medium,
        border: Border.all(color: tone.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            balanced ? Icons.check_circle_outline : Icons.error_outline,
            size: 17,
            color: tone,
          ),
          const SizedBox(width: Space.xs),
          Text(label, style: AppType.bodyStrong.copyWith(color: tone)),
        ],
      ),
    );
  }
}
