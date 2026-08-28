import 'package:flutter_test/flutter_test.dart';
import 'package:mise/core/reporting/report_csv.dart';
import 'package:mise/core/reporting/sales_breakdown.dart';
import 'package:mise/core/reporting/sales_report.dart';
import 'package:mise/data/models/money.dart';
import 'package:mise/data/models/restaurant.dart';

const venue = Restaurant(
  id: 'r1',
  name: 'The Ember',
  currencyCode: 'BDT',
  currencySymbol: '৳',
  taxRate: 5,
  taxInclusive: false,
  serviceChargeRate: 10,
  setupComplete: true,
);

SalesReport report({int bills = 2, double takings = 500}) => SalesReport(
      billCount: bills,
      grossSales: 400,
      discounts: 20,
      serviceCharge: 40,
      tax: 25,
      netTakings: takings,
      byMethod: const {PaymentMethod.cash: 300, PaymentMethod.card: 200},
      cancelledCount: 0,
      cancelledValue: 0,
    );

String build({SalesBreakdown? breakdown}) => ReportCsv.build(
      restaurant: venue,
      report: report(),
      breakdown: breakdown ?? SalesBreakdown.empty,
      day: DateTime(2026, 8, 28),
    );

void main() {
  test('names the venue, the day and the currency up top', () {
    final csv = build();
    expect(csv, startsWith('The Ember,Sales report'));
    expect(csv, contains('Date,2026-08-28'));
    expect(csv, contains('Currency,BDT'));
  });

  test('carries the summary figures', () {
    final csv = build();
    expect(csv, contains('Bills,2'));
    expect(csv, contains('Takings,500.00'));
    expect(csv, contains('Average bill,250.00'));
  });

  test('splits payments by method', () {
    final csv = build();
    expect(csv, contains('Cash,300.00'));
    expect(csv, contains('Card,200.00'));
  });

  test('quotes anything that would break a row apart', () {
    final breakdown = SalesBreakdown(
      byItem: const [
        BreakdownRow(label: 'Fish, chips and peas', count: 1, value: 12.5),
        BreakdownRow(label: 'The "Special"', count: 2, value: 30),
      ],
      byStaff: const [],
      byHour: const [],
      busiestHour: null,
    );
    final csv = build(breakdown: breakdown);

    expect(csv, contains('"Fish, chips and peas",1,12.50'));
    // A quote inside a cell is doubled, per RFC 4180.
    expect(csv, contains('"The ""Special""",2,30.00'));
  });

  test('every row has the same number of columns as its section header', () {
    final breakdown = SalesBreakdown(
      byItem: const [BreakdownRow(label: 'Chai, hot', count: 3, value: 30)],
      byStaff: const [BreakdownRow(label: 'Rahim', count: 2, value: 500)],
      byHour: const [BreakdownRow(label: '20:00–21:00', count: 2, value: 500)],
      busiestHour: 20,
    );
    final csv = build(breakdown: breakdown);

    var expected = 0;
    for (final line in csv.split('\n')) {
      if (line.trim().isEmpty) continue;
      final cols = _countColumns(line);
      // A lone cell starts a new section; the next line is its header.
      if (cols == 1) {
        expected = 0;
        continue;
      }
      if (expected == 0) {
        expected = cols;
      } else {
        expect(cols, expected, reason: 'row "$line" does not match its header');
      }
    }
  });

  test('builds a filename from the venue and the date', () {
    expect(ReportCsv.fileName(venue, DateTime(2026, 8, 28)),
        'the-ember-2026-08-28.csv');
  });
}

/// Counts columns respecting RFC 4180 quoting.
int _countColumns(String line) {
  var count = 1;
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (c == ',' && !inQuotes) {
      count++;
    }
  }
  return count;
}
