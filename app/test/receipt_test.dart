import 'package:flutter_test/flutter_test.dart';
import 'package:mise/core/printing/receipt.dart';
import 'package:mise/data/models/money.dart';
import 'package:mise/data/models/restaurant.dart';
import 'package:mise/data/models/service.dart';

Restaurant venue({
  String symbol = r'$',
  String code = 'USD',
  double tax = 5,
  double service = 10,
  bool inclusive = false,
  String footer = '',
}) =>
    Restaurant(
      id: 'r1',
      name: 'The Ember',
      currencyCode: code,
      currencySymbol: symbol,
      taxRate: tax,
      taxInclusive: inclusive,
      serviceChargeRate: service,
      setupComplete: true,
      address: '14 Gulshan Ave, Dhaka',
      phone: '+880 1700 000000',
      receiptFooter: footer,
    );

Order bill({
  double subtotal = 1000,
  double discount = 0,
  double service = 100,
  double tax = 55,
  double total = 1155,
  double paid = 0,
}) =>
    Order(
      id: 'o1',
      number: '007',
      type: OrderType.dineIn,
      status: OrderStatus.served,
      staffId: 's1',
      subtotal: subtotal,
      discountAmount: discount,
      taxAmount: tax,
      serviceAmount: service,
      total: total,
      paidAmount: paid,
      paid: paid >= total,
      created: DateTime(2026, 8, 27, 21, 5),
      guestCount: 2,
    );

OrderLine line({
  String name = 'Grilled sea bass',
  int qty = 1,
  double lineTotal = 850,
  List<SelectedModifier> mods = const [],
  String note = '',
  OrderItemStatus status = OrderItemStatus.served,
}) =>
    OrderLine(
      id: 'l1',
      orderId: 'o1',
      name: name,
      qty: qty,
      unitPrice: 850,
      modifiers: mods,
      modifiersTotal: 0,
      lineTotal: lineTotal,
      status: status,
      note: note,
    );

ReceiptBuilder build({
  Restaurant? r,
  Order? o,
  List<OrderLine>? lines,
  List<Payment> payments = const [],
  PaperWidth width = PaperWidth.mm80,
}) =>
    ReceiptBuilder(
      restaurant: r ?? venue(),
      order: o ?? bill(),
      lines: lines ?? [line()],
      payments: payments,
      width: width,
      staffName: 'Shakib',
      tableLabel: 'T1',
      printedAt: DateTime(2026, 8, 27, 21, 30),
    );

void main() {
  group('layout', () {
    test('never exceeds the paper width', () {
      for (final w in PaperWidth.values) {
        final out = build(
          width: w,
          lines: [
            line(name: 'Something with an extremely long name indeed here', qty: 12),
          ],
        ).text();

        for (final l in out.split('\n')) {
          expect(l.length, lessThanOrEqualTo(w.columns),
              reason: 'line "$l" overflows ${w.columns} columns');
        }
      }
    });

    test('amounts sit hard against the right edge', () {
      final out = build().text().split('\n');
      final total = out.firstWhere((l) => l.startsWith('TOTAL'));
      expect(total.length, PaperWidth.mm80.columns);
      expect(total.trimRight(), endsWith(r'$1155.00'));
    });

    test('carries the venue, the bill number and who served it', () {
      final out = build().text();
      expect(out, contains('The Ember'));
      expect(out, contains('Bill #007'));
      expect(out, contains('Table T1'));
      expect(out, contains('Shakib'));
      expect(out, contains('Guests: 2'));
      expect(out, contains('2026-08-27'));
    });

    test('prints modifiers and kitchen notes under their line', () {
      final out = build(lines: [
        line(
          mods: const [SelectedModifier(name: 'Large', priceDelta: 150)],
          note: 'NO CHILLI - allergy',
        )
      ]).text();
      expect(out, contains('Large'));
      expect(out, contains('NO CHILLI - allergy'));
    });

    test('leaves voided lines off the bill entirely', () {
      final out = build(lines: [
        line(name: 'Kept'),
        line(name: 'Scratched', status: OrderItemStatus.void_),
      ]).text();
      expect(out, contains('Kept'));
      expect(out, isNot(contains('Scratched')));
    });

    test('shows a discount only when there is one', () {
      expect(build().text(), isNot(contains('Discount')));
      final out = build(o: bill(discount: 200, total: 955)).text();
      expect(out, contains('Discount'));
      expect(out, contains(r'-$200.00'));
    });

    test('labels tax as included when prices already contain it', () {
      final out = build(r: venue(inclusive: true)).text();
      expect(out, contains('(incl)'));
    });
  });

  group('payments', () {
    test('shows tendered and change for cash', () {
      final out = build(
        o: bill(paid: 1155),
        payments: [
          Payment(
            id: 'p1', orderId: 'o1', method: PaymentMethod.cash,
            amount: 1155, tendered: 2000, changeDue: 845,
            created: DateTime(2026, 8, 27),
          )
        ],
      ).text();
      expect(out, contains('Tendered'));
      expect(out, contains(r'$2000.00'));
      expect(out, contains('Change'));
      expect(out, contains(r'$845.00'));
    });

    test('calls out a part-paid bill', () {
      final out = build(
        o: bill(paid: 500),
        payments: [
          Payment(
            id: 'p1', orderId: 'o1', method: PaymentMethod.card, amount: 500,
            created: DateTime(2026, 8, 27),
          )
        ],
      ).text();
      expect(out, contains('STILL OWING'));
      expect(out, contains(r'$655.00'));
    });
  });

  group('currency', () {
    test('falls back to the code when the symbol is not printable', () {
      // A thermal printer would render the taka sign as noise, so the receipt
      // uses BDT instead.
      final out = build(r: venue(symbol: '৳', code: 'BDT')).text();
      expect(out, contains('1155.00 BDT'));
      expect(out, isNot(contains('৳')));
    });
  });

  group('esc/pos', () {
    test('initialises, emboldens the total and cuts the paper', () {
      final bytes = build().escPos();
      expect(bytes.take(2), [0x1B, 0x40], reason: 'must start with ESC @');
      expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x42, 0x00],
          reason: 'must end with a partial cut');
      expect(_contains(bytes, [0x1B, 0x45, 0x01]), isTrue, reason: 'bold on');
      expect(_contains(bytes, [0x1D, 0x21, 0x01]), isTrue,
          reason: 'double height for the venue name');
    });

    test('emits no byte a code-page printer would misread', () {
      final out = build(r: venue(symbol: '৳', code: 'BDT')).escPos();
      // Control codes aside, every printable byte must be plain ASCII.
      final printable = out.where((b) => b >= 0x20);
      expect(printable.every((b) => b < 0x80), isTrue);
    });
  });
}

bool _contains(List<int> haystack, List<int> needle) {
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var hit = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        hit = false;
        break;
      }
    }
    if (hit) return true;
  }
  return false;
}
