import 'package:flutter_test/flutter_test.dart';
import 'package:mise/core/reporting/sales_report.dart';
import 'package:mise/data/models/money.dart';
import 'package:mise/data/models/service.dart';

Order order({
  required String id,
  required OrderStatus status,
  double subtotal = 100,
  double discount = 0,
  double service = 10,
  double tax = 5,
  double total = 115,
}) =>
    Order(
      id: id,
      number: id,
      type: OrderType.dineIn,
      status: status,
      staffId: 's1',
      subtotal: subtotal,
      discountAmount: discount,
      taxAmount: tax,
      serviceAmount: service,
      total: total,
      paidAmount: status == OrderStatus.paid ? total : 0,
      paid: status == OrderStatus.paid,
      created: DateTime(2026, 8, 27),
    );

Payment pay(String orderId, PaymentMethod method, double amount) => Payment(
      id: '$orderId-$method',
      orderId: orderId,
      method: method,
      amount: amount,
      created: DateTime(2026, 8, 27),
    );

void main() {
  test('counts only settled bills', () {
    final r = SalesReport.from(
      orders: [
        order(id: 'a', status: OrderStatus.paid),
        order(id: 'b', status: OrderStatus.paid),
        order(id: 'c', status: OrderStatus.served), // still open
      ],
      payments: [
        pay('a', PaymentMethod.cash, 115),
        pay('b', PaymentMethod.card, 115),
      ],
    );

    expect(r.billCount, 2);
    expect(r.netTakings, 230);
    expect(r.grossSales, 200);
  });

  test('ignores money against bills outside the period', () {
    final r = SalesReport.from(
      orders: [order(id: 'a', status: OrderStatus.paid)],
      payments: [
        pay('a', PaymentMethod.cash, 115),
        pay('ghost', PaymentMethod.cash, 999), // belongs to another day
      ],
    );

    expect(r.cashTaken, 115);
    expect(r.unreconciled, 0);
  });

  test('splits takings by method and totals only cash for the drawer', () {
    final r = SalesReport.from(
      orders: [order(id: 'a', status: OrderStatus.paid, total: 300)],
      payments: [
        pay('a', PaymentMethod.cash, 100),
        pay('a', PaymentMethod.card, 150),
        pay('a', PaymentMethod.mobile, 50),
      ],
    );

    expect(r.byMethod[PaymentMethod.cash], 100);
    expect(r.byMethod[PaymentMethod.card], 150);
    expect(r.byMethod[PaymentMethod.mobile], 50);
    expect(r.cashTaken, 100);
    expect(r.collected, 300);
  });

  test('surfaces a gap between what was charged and what was collected', () {
    // A bill marked paid but only part-collected: worth showing, not hiding.
    final r = SalesReport.from(
      orders: [order(id: 'a', status: OrderStatus.paid, total: 115)],
      payments: [pay('a', PaymentMethod.cash, 100)],
    );
    expect(r.unreconciled, -15);
  });

  test('reports cancellations separately from sales', () {
    final r = SalesReport.from(
      orders: [
        order(id: 'a', status: OrderStatus.paid),
        order(id: 'b', status: OrderStatus.cancelled, subtotal: 400),
      ],
      payments: [pay('a', PaymentMethod.cash, 115)],
    );

    expect(r.billCount, 1);
    expect(r.cancelledCount, 1);
    expect(r.cancelledValue, 400);
    expect(r.grossSales, 100, reason: 'a cancelled bill is not a sale');
  });

  test('averages across the bills it counted', () {
    final r = SalesReport.from(
      orders: [
        order(id: 'a', status: OrderStatus.paid, total: 100),
        order(id: 'b', status: OrderStatus.paid, total: 300),
      ],
      payments: const [],
    );
    expect(r.averageBill, 200);
  });

  test('an empty day reports zeroes, not a crash', () {
    final r = SalesReport.from(orders: const [], payments: const []);
    expect(r.billCount, 0);
    expect(r.netTakings, 0);
    expect(r.averageBill, 0);
    expect(r.byMethod, isEmpty);
  });
}
