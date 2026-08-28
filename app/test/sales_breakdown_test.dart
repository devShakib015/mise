import 'package:flutter_test/flutter_test.dart';
import 'package:mise/core/reporting/sales_breakdown.dart';
import 'package:mise/data/models/service.dart';
import 'package:mise/data/models/staff.dart';

Order order({
  required String id,
  required String staffId,
  OrderStatus status = OrderStatus.paid,
  double total = 100,
  int hour = 19,
}) =>
    Order(
      id: id,
      number: id,
      type: OrderType.dineIn,
      status: status,
      staffId: staffId,
      subtotal: total,
      discountAmount: 0,
      taxAmount: 0,
      serviceAmount: 0,
      total: total,
      paidAmount: status == OrderStatus.paid ? total : 0,
      paid: status == OrderStatus.paid,
      created: DateTime(2026, 8, 28, hour),
      closedAt: DateTime(2026, 8, 28, hour, 30),
    );

OrderLine line({
  required String orderId,
  required String name,
  int qty = 1,
  double lineTotal = 100,
  OrderItemStatus status = OrderItemStatus.served,
}) =>
    OrderLine(
      id: '$orderId-$name',
      orderId: orderId,
      name: name,
      qty: qty,
      unitPrice: lineTotal / qty,
      modifiers: const [],
      modifiersTotal: 0,
      lineTotal: lineTotal,
      status: status,
    );

Staff person(String id, String name) => Staff(
      id: id,
      name: name,
      username: name.toLowerCase(),
      role: StaffRole.waiter,
      active: true,
    );

void main() {
  test('ranks items by what they earned, not how many sold', () {
    final b = SalesBreakdown.from(
      orders: [order(id: 'a', staffId: 's1', total: 1000)],
      lines: [
        line(orderId: 'a', name: 'Chai', qty: 10, lineTotal: 100),
        line(orderId: 'a', name: 'Steak', qty: 1, lineTotal: 900),
      ],
      staff: [person('s1', 'Rahim')],
    );

    expect(b.byItem.first.label, 'Steak');
    expect(b.byItem.first.value, 900);
    expect(b.byItem.last.label, 'Chai');
    expect(b.byItem.last.count, 10);
  });

  test('adds the same item up across bills', () {
    final b = SalesBreakdown.from(
      orders: [
        order(id: 'a', staffId: 's1'),
        order(id: 'b', staffId: 's1'),
      ],
      lines: [
        line(orderId: 'a', name: 'Chai', qty: 2, lineTotal: 180),
        line(orderId: 'b', name: 'Chai', qty: 3, lineTotal: 270),
      ],
      staff: [person('s1', 'Rahim')],
    );

    expect(b.byItem.length, 1);
    expect(b.byItem.single.count, 5);
    expect(b.byItem.single.value, 450);
  });

  test('leaves out unsettled bills and voided lines', () {
    final b = SalesBreakdown.from(
      orders: [
        order(id: 'a', staffId: 's1'),
        order(id: 'open', staffId: 's1', status: OrderStatus.served),
      ],
      lines: [
        line(orderId: 'a', name: 'Counted'),
        line(orderId: 'a', name: 'Scratched', status: OrderItemStatus.void_),
        line(orderId: 'open', name: 'NotYet'),
      ],
      staff: [person('s1', 'Rahim')],
    );

    expect(b.byItem.map((r) => r.label), ['Counted']);
    expect(b.byStaff.single.count, 1, reason: 'only the settled bill counts');
  });

  test('attributes bills to whoever took them', () {
    final b = SalesBreakdown.from(
      orders: [
        order(id: 'a', staffId: 's1', total: 300),
        order(id: 'b', staffId: 's2', total: 100),
        order(id: 'c', staffId: 's1', total: 200),
      ],
      lines: const [],
      staff: [person('s1', 'Rahim'), person('s2', 'Karim')],
    );

    expect(b.byStaff.first.label, 'Rahim');
    expect(b.byStaff.first.count, 2);
    expect(b.byStaff.first.value, 500);
    expect(b.byStaff.last.label, 'Karim');
  });

  test('still shows the sales of someone who has since been removed', () {
    final b = SalesBreakdown.from(
      orders: [order(id: 'a', staffId: 'gone')],
      lines: const [],
      staff: const [],
    );
    expect(b.byStaff.single.label, 'Removed');
    expect(b.byStaff.single.value, 100);
  });

  test('buckets by the hour the bill closed, and finds the busiest', () {
    final b = SalesBreakdown.from(
      orders: [
        order(id: 'a', staffId: 's1', total: 100, hour: 12),
        order(id: 'b', staffId: 's1', total: 900, hour: 20),
        order(id: 'c', staffId: 's1', total: 50, hour: 20),
      ],
      lines: const [],
      staff: [person('s1', 'Rahim')],
    );

    expect(b.byHour.map((r) => r.label), ['12:00–13:00', '20:00–21:00']);
    expect(b.byHour.last.value, 950);
    expect(b.byHour.last.count, 2);
    expect(b.busiestHour, 20);
  });

  test('an empty day breaks down to nothing, not a crash', () {
    final b = SalesBreakdown.from(orders: const [], lines: const [], staff: const []);
    expect(b.byItem, isEmpty);
    expect(b.byStaff, isEmpty);
    expect(b.byHour, isEmpty);
    expect(b.busiestHour, isNull);
  });
}
