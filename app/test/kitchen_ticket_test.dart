import 'package:flutter_test/flutter_test.dart';
import 'package:mise/core/printing/kitchen_ticket.dart';
import 'package:mise/core/printing/receipt.dart';
import 'package:mise/data/models/service.dart';

final order = Order(
  id: 'o1', number: '042', type: OrderType.dineIn, status: OrderStatus.sent,
  staffId: 's1', subtotal: 1000, discountAmount: 0, taxAmount: 0,
  serviceAmount: 0, total: 1000, paidAmount: 0, paid: false,
  created: DateTime(2026, 9, 1, 20, 15), guestCount: 4,
);

OrderLine line({
  String name = 'Grilled sea bass',
  int qty = 2,
  List<SelectedModifier> mods = const [],
  String note = '',
  OrderItemStatus status = OrderItemStatus.queued,
}) =>
    OrderLine(
      id: 'l-$name', orderId: 'o1', name: name, qty: qty, unitPrice: 850,
      modifiers: mods, modifiersTotal: 0, lineTotal: 1700, status: status,
      note: note,
    );

KitchenTicket build({List<OrderLine>? lines, String station = 'Kitchen'}) =>
    KitchenTicket(
      order: order,
      lines: lines ?? [line()],
      width: PaperWidth.mm80,
      tableLabel: 'T7',
      staffName: 'Rahim',
      station: station,
      printedAt: DateTime(2026, 9, 1, 20, 31),
    );

void main() {
  test('leads with the station and the table', () {
    final out = build().text().split('\n');
    expect(out[0].trim(), 'KITCHEN');
    expect(out[1].trim(), 'TABLE T7');
  });

  test('carries no prices — none of it helps anyone cook', () {
    final out = build().text();
    expect(out, isNot(contains('1700')));
    expect(out, isNot(contains('850')));
    expect(out, isNot(contains(r'$')));
    expect(out.toLowerCase(), isNot(contains('total')));
  });

  test('shows what to make and how many', () {
    final out = build().text();
    expect(out, contains('GRILLED SEA BASS'));
    expect(out, contains('2 X'));
    expect(out, contains('#042'));
    expect(out, contains('Rahim'));
  });

  test('gives a note the loudest treatment on the paper', () {
    final out = build(lines: [line(note: 'no chilli, allergy')]).text();
    expect(out, contains('** NO CHILLI'));
    expect(out, contains('ALLERGY **'));
  });

  test('lists modifiers under their item', () {
    final out = build(lines: [
      line(mods: const [
        SelectedModifier(name: 'Large', priceDelta: 150),
        SelectedModifier(name: 'Extra lemon', priceDelta: 0),
      ])
    ]).text();
    expect(out, contains('Large, Extra lemon'));
  });

  test('leaves voided lines off entirely', () {
    final out = build(lines: [
      line(name: 'Kept'),
      line(name: 'Scratched', status: OrderItemStatus.void_),
    ]).text();
    expect(out, contains('KEPT'));
    expect(out, isNot(contains('SCRATCHED')));
  });

  test('never exceeds the paper width', () {
    for (final w in PaperWidth.values) {
      final t = KitchenTicket(
        order: order,
        lines: [line(name: 'Something with a truly excessive name on it', note: 'and a very long note about it too')],
        width: w, tableLabel: 'T7', station: 'Kitchen',
      );
      for (final l in t.text().split('\n')) {
        expect(l.length, lessThanOrEqualTo(w.columns), reason: 'overflow: "$l"');
      }
    }
  });

  test('initialises, enlarges the header and cuts', () {
    final bytes = build().escPos();
    expect(bytes.take(2), [0x1B, 0x40]);
    expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x42, 0x00]);
    expect(_has(bytes, [0x1D, 0x21, 0x11]), isTrue, reason: 'double-size header');
  });

  test('emits only bytes a code-page printer can render', () {
    final out = build(lines: [line(name: 'Café ৳ special', note: 'naïve')]).escPos();
    expect(out.where((b) => b >= 0x20).every((b) => b < 0x80), isTrue);
  });
}

bool _has(List<int> hay, List<int> needle) {
  for (var i = 0; i + needle.length <= hay.length; i++) {
    if (List.generate(needle.length, (j) => hay[i + j] == needle[j]).every((x) => x)) {
      return true;
    }
  }
  return false;
}
