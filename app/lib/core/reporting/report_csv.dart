import '../../data/models/money.dart';
import '../../data/models/restaurant.dart';
import 'sales_breakdown.dart';
import 'sales_report.dart';

/// Renders a day's trading as CSV, for anyone who wants it in a spreadsheet or
/// handed to an accountant.
///
/// One file with labelled sections rather than several: a restaurant emailing
/// this to a bookkeeper should be sending one attachment, not four.
abstract final class ReportCsv {
  static String build({
    required Restaurant restaurant,
    required SalesReport report,
    required SalesBreakdown breakdown,
    required DateTime day,
    Shift? shift,
  }) {
    final out = StringBuffer();

    void row(List<Object?> cells) =>
        out.writeln(cells.map(_escape).join(','));

    void section(String title, List<String> header) {
      out.writeln();
      row([title]);
      row(header);
    }

    row([restaurant.name, 'Sales report']);
    row(['Date', _date(day)]);
    row(['Currency', restaurant.currencyCode]);

    section('Summary', ['Metric', 'Value']);
    row(['Bills', report.billCount]);
    row(['Gross sales', _money(report.grossSales)]);
    row(['Discounts', _money(report.discounts)]);
    row(['Service charge', _money(report.serviceCharge)]);
    row(['Tax', _money(report.tax)]);
    row(['Takings', _money(report.netTakings)]);
    row(['Average bill', _money(report.averageBill)]);
    if (report.cancelledCount > 0) {
      row(['Cancelled bills', report.cancelledCount]);
      row(['Cancelled value', _money(report.cancelledValue)]);
    }
    if (report.unreconciled.abs() >= 0.005) {
      row(['Unreconciled', _money(report.unreconciled)]);
    }

    section('Payments', ['Method', 'Amount']);
    if (report.byMethod.isEmpty) {
      row(['None', _money(0)]);
    } else {
      for (final e in report.byMethod.entries) {
        row([e.key.label, _money(e.value)]);
      }
    }

    section('Items', ['Item', 'Quantity', 'Value']);
    for (final r in breakdown.byItem) {
      row([r.label, r.count, _money(r.value)]);
    }

    section('Staff', ['Name', 'Bills', 'Takings']);
    for (final r in breakdown.byStaff) {
      row([r.label, r.count, _money(r.value)]);
    }

    section('By hour', ['Hour', 'Bills', 'Takings']);
    for (final r in breakdown.byHour) {
      row([r.label, r.count, _money(r.value)]);
    }

    if (shift != null) {
      section('Drawer', ['Metric', 'Value']);
      row(['Opening float', _money(shift.openingCash)]);
      row(['Expected', _money(shift.expectedCash)]);
      row(['Counted', _money(shift.closingCash)]);
      row(['Variance', _money(shift.variance)]);
    }

    return out.toString();
  }

  static String fileName(Restaurant restaurant, DateTime day) {
    final slug = restaurant.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return '${slug.isEmpty ? 'sales' : slug}-${_date(day)}.csv';
  }

  static String _date(DateTime d) {
    two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static String _money(double v) => v.toStringAsFixed(2);

  /// Quotes a cell when it contains anything that would break the row apart.
  /// Embedded quotes are doubled, per RFC 4180.
  static String _escape(Object? cell) {
    final text = cell?.toString() ?? '';
    if (!text.contains(RegExp(r'[",\n\r]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }
}
