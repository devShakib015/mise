import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/reporting/sales_report.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/ui_state.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../data/repositories/service_repository.dart';
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

    return Column(
      children: [
        PageHeader(
          title: 'Reports',
          subtitle: 'What each day came to.',
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
          child: AsyncView(
            value: orders,
            onRetry: () => ref.invalidate(closedOrdersProvider(range)),
            data: (list) {
              final report = SalesReport.from(
                orders: list,
                payments: payments.value ?? const [],
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
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: ReportSummary(report: report),
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
