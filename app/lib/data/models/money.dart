import 'package:pocketbase/pocketbase.dart';

enum PaymentMethod {
  cash,
  card,
  mobile,
  voucher,
  other;

  static PaymentMethod parse(String raw) => PaymentMethod.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => PaymentMethod.other,
      );

  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.card => 'Card',
        PaymentMethod.mobile => 'Mobile',
        PaymentMethod.voucher => 'Voucher',
        PaymentMethod.other => 'Other',
      };

  /// Only cash lands in the drawer, so only cash is counted at close.
  bool get isCash => this == PaymentMethod.cash;
}

class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.created,
    this.tendered = 0,
    this.changeDue = 0,
    this.reference = '',
    this.staffId = '',
  });

  final String id;
  final String orderId;
  final PaymentMethod method;

  /// What was applied to the bill — never what was handed over.
  final double amount;
  final DateTime created;

  final double tendered;
  final double changeDue;
  final String reference;
  final String staffId;

  factory Payment.fromRecord(RecordModel r) => Payment(
        id: r.id,
        orderId: r.getStringValue('order'),
        method: PaymentMethod.parse(r.getStringValue('method')),
        amount: r.getDoubleValue('amount'),
        created: DateTime.tryParse(r.getStringValue('created'))?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        tendered: r.getDoubleValue('tendered'),
        changeDue: r.getDoubleValue('change_due'),
        reference: r.getStringValue('reference'),
        staffId: r.getStringValue('staff'),
      );
}

/// A till session. Opening one records what is in the drawer; closing it
/// compares that plus the cash taken against what was actually counted.
class Shift {
  const Shift({
    required this.id,
    required this.staffId,
    required this.openingCash,
    this.openedAt,
    this.closedAt,
    this.closingCash = 0,
    this.expectedCash = 0,
    this.variance = 0,
    this.note = '',
  });

  final String id;
  final String staffId;
  final double openingCash;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final double closingCash;
  final double expectedCash;

  /// Counted minus expected. Negative means the drawer is short.
  final double variance;
  final String note;

  bool get isOpen => closedAt == null;

  factory Shift.fromRecord(RecordModel r) {
    DateTime? parse(String key) {
      final raw = r.getStringValue(key);
      return raw.isEmpty ? null : DateTime.tryParse(raw)?.toLocal();
    }

    return Shift(
      id: r.id,
      staffId: r.getStringValue('staff'),
      openingCash: r.getDoubleValue('opening_cash'),
      openedAt: parse('opened_at'),
      closedAt: parse('closed_at'),
      closingCash: r.getDoubleValue('closing_cash'),
      expectedCash: r.getDoubleValue('expected_cash'),
      variance: r.getDoubleValue('variance'),
      note: r.getStringValue('note'),
    );
  }
}
