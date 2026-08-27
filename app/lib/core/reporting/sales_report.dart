import '../../data/models/money.dart';
import '../../data/models/service.dart';

/// What a period of trading came to.
///
/// Computed from settled bills only. An open bill is not takings — counting it
/// would overstate the day and the numbers would move as tables settle.
class SalesReport {
  const SalesReport({
    required this.billCount,
    required this.grossSales,
    required this.discounts,
    required this.serviceCharge,
    required this.tax,
    required this.netTakings,
    required this.byMethod,
    required this.cancelledCount,
    required this.cancelledValue,
  });

  /// Bills settled in the period.
  final int billCount;

  /// Sum of subtotals, before anything is taken off or added on.
  final double grossSales;
  final double discounts;
  final double serviceCharge;
  final double tax;

  /// What was actually charged — the sum of bill totals.
  final double netTakings;

  final Map<PaymentMethod, double> byMethod;

  final int cancelledCount;
  final double cancelledValue;

  double get cashTaken => byMethod[PaymentMethod.cash] ?? 0;

  double get averageBill => billCount == 0 ? 0 : netTakings / billCount;

  /// Money recorded against bills, which should equal [netTakings]. A gap means
  /// a part-paid bill was closed or a payment was removed after settling, and
  /// is worth surfacing rather than hiding.
  double get collected =>
      byMethod.values.fold(0.0, (sum, v) => sum + v);

  double get unreconciled => _round(collected - netTakings);

  factory SalesReport.from({
    required List<Order> orders,
    required List<Payment> payments,
  }) {
    var count = 0;
    var gross = 0.0;
    var discount = 0.0;
    var service = 0.0;
    var tax = 0.0;
    var net = 0.0;
    var cancelled = 0;
    var cancelledValue = 0.0;

    final settledIds = <String>{};

    for (final o in orders) {
      if (o.status == OrderStatus.cancelled) {
        cancelled++;
        cancelledValue += o.subtotal;
        continue;
      }
      if (o.status != OrderStatus.paid) continue;

      settledIds.add(o.id);
      count++;
      gross += o.subtotal;
      discount += o.discountAmount;
      service += o.serviceAmount;
      tax += o.taxAmount;
      net += o.total;
    }

    final byMethod = <PaymentMethod, double>{};
    for (final p in payments) {
      // Only money against bills in this report, so the two halves agree.
      if (!settledIds.contains(p.orderId)) continue;
      byMethod[p.method] = (byMethod[p.method] ?? 0) + p.amount;
    }

    return SalesReport(
      billCount: count,
      grossSales: _round(gross),
      discounts: _round(discount),
      serviceCharge: _round(service),
      tax: _round(tax),
      netTakings: _round(net),
      byMethod: {
        for (final e in byMethod.entries) e.key: _round(e.value),
      },
      cancelledCount: cancelled,
      cancelledValue: _round(cancelledValue),
    );
  }

  static double _round(double v) => (v * 100).round() / 100;
}
