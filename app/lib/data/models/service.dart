import 'package:pocketbase/pocketbase.dart';

/// Where a table is in its cycle. Drives the colour on the floor plan.
enum TableStatus {
  free,
  occupied,
  reserved,
  cleaning;

  static TableStatus parse(String raw) => TableStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => TableStatus.free,
      );

  String get label => switch (this) {
        TableStatus.free => 'Free',
        TableStatus.occupied => 'Occupied',
        TableStatus.reserved => 'Reserved',
        TableStatus.cleaning => 'Needs clearing',
      };
}

class DiningTable {
  const DiningTable({
    required this.id,
    required this.label,
    required this.seats,
    required this.status,
    required this.active,
    this.zone = '',
    this.posX = 0,
    this.posY = 0,
  });

  final String id;
  final String label;
  final int seats;
  final TableStatus status;
  final bool active;
  final String zone;
  final double posX;
  final double posY;

  factory DiningTable.fromRecord(RecordModel r) => DiningTable(
        id: r.id,
        label: r.getStringValue('label'),
        seats: r.getIntValue('seats'),
        status: TableStatus.parse(r.getStringValue('status')),
        active: r.getBoolValue('active'),
        zone: r.getStringValue('zone'),
        posX: r.getDoubleValue('pos_x'),
        posY: r.getDoubleValue('pos_y'),
      );
}

enum OrderType {
  dineIn,
  takeaway,
  delivery;

  String get wire => switch (this) {
        OrderType.dineIn => 'dine_in',
        OrderType.takeaway => 'takeaway',
        OrderType.delivery => 'delivery',
      };

  String get label => switch (this) {
        OrderType.dineIn => 'Dine in',
        OrderType.takeaway => 'Takeaway',
        OrderType.delivery => 'Delivery',
      };

  static OrderType parse(String raw) => OrderType.values.firstWhere(
        (t) => t.wire == raw,
        orElse: () => OrderType.dineIn,
      );
}

enum OrderStatus {
  open,
  sent,
  preparing,
  ready,
  served,
  paid,
  cancelled;

  static OrderStatus parse(String raw) => OrderStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => OrderStatus.open,
      );

  String get label => switch (this) {
        OrderStatus.open => 'Open',
        OrderStatus.sent => 'Sent',
        OrderStatus.preparing => 'In the kitchen',
        OrderStatus.ready => 'Ready',
        OrderStatus.served => 'Served',
        OrderStatus.paid => 'Paid',
        OrderStatus.cancelled => 'Cancelled',
      };

  /// Still being worked on, so it belongs in the open-orders list.
  bool get isLive => this != OrderStatus.paid && this != OrderStatus.cancelled;
}

/// A bill. Every money field here is computed server-side; the app only ever
/// reads them.
class Order {
  const Order({
    required this.id,
    required this.number,
    required this.type,
    required this.status,
    required this.staffId,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.serviceAmount,
    required this.total,
    required this.paidAmount,
    required this.paid,
    required this.created,
    this.tableId = '',
    this.guestCount = 0,
    this.customerName = '',
    this.note = '',
    this.discountReason = '',
    this.closedAt,
  });

  final String id;
  final String number;
  final OrderType type;
  final OrderStatus status;
  final String staffId;

  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double serviceAmount;
  final double total;
  final double paidAmount;
  final bool paid;

  final DateTime created;
  final String tableId;
  final int guestCount;
  final String customerName;
  final String note;

  /// Why the discount was given. Required whenever there is one.
  final String discountReason;

  /// When the bill was settled or cancelled. Null while it is still open.
  final DateTime? closedAt;

  factory Order.fromRecord(RecordModel r) => Order(
        id: r.id,
        number: r.getStringValue('number'),
        type: OrderType.parse(r.getStringValue('type')),
        status: OrderStatus.parse(r.getStringValue('status')),
        staffId: r.getStringValue('staff'),
        subtotal: r.getDoubleValue('subtotal'),
        discountAmount: r.getDoubleValue('discount_amount'),
        taxAmount: r.getDoubleValue('tax_amount'),
        serviceAmount: r.getDoubleValue('service_amount'),
        total: r.getDoubleValue('total'),
        paidAmount: r.getDoubleValue('paid_amount'),
        paid: r.getBoolValue('paid'),
        created: DateTime.tryParse(r.getStringValue('created'))?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        tableId: r.getStringValue('table'),
        guestCount: r.getIntValue('guest_count'),
        customerName: r.getStringValue('customer_name'),
        note: r.getStringValue('note'),
        discountReason: r.getStringValue('discount_reason'),
        closedAt: r.getStringValue('closed_at').isEmpty
            ? null
            : DateTime.tryParse(r.getStringValue('closed_at'))?.toLocal(),
      );
}

/// One modifier as chosen at the time of ordering. Snapshotted onto the line so
/// later price changes cannot rewrite an existing bill.
class SelectedModifier {
  const SelectedModifier({required this.name, required this.priceDelta});

  final String name;
  final double priceDelta;

  Map<String, dynamic> toJson() => {'name': name, 'price_delta': priceDelta};

  factory SelectedModifier.fromJson(Map<String, dynamic> j) => SelectedModifier(
        name: (j['name'] ?? '').toString(),
        priceDelta: double.tryParse('${j['price_delta'] ?? 0}') ?? 0,
      );
}

enum OrderItemStatus {
  queued,
  preparing,
  ready,
  served,
  void_;

  /// `void` is a reserved word in Dart, hence the trailing underscore.
  String get wire => this == OrderItemStatus.void_ ? 'void' : name;

  static OrderItemStatus parse(String raw) => OrderItemStatus.values.firstWhere(
        (s) => s.wire == raw,
        orElse: () => OrderItemStatus.queued,
      );

  String get label => switch (this) {
        OrderItemStatus.queued => 'Queued',
        OrderItemStatus.preparing => 'Cooking',
        OrderItemStatus.ready => 'Ready',
        OrderItemStatus.served => 'Served',
        OrderItemStatus.void_ => 'Voided',
      };
}

/// Which course a line belongs to. A kitchen fires starters, then mains, so a
/// table is not handed everything at once.
abstract final class Course {
  static const starters = 1;
  static const mains = 2;
  static const desserts = 3;

  static const all = [starters, mains, desserts];

  static String label(int c) => switch (c) {
        starters => 'Starters',
        mains => 'Mains',
        desserts => 'Desserts',
        _ => 'Course $c',
      };
}

class OrderLine {
  const OrderLine({
    required this.id,
    required this.orderId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.modifiers,
    required this.modifiersTotal,
    required this.lineTotal,
    required this.status,
    this.menuItemId = '',
    this.note = '',
    this.sentAt,
    this.course = Course.mains,
  });

  final String id;
  final String orderId;
  final String name;
  final int qty;
  final double unitPrice;
  final List<SelectedModifier> modifiers;
  final double modifiersTotal;
  final double lineTotal;
  final OrderItemStatus status;
  final String menuItemId;
  final String note;
  final DateTime? sentAt;

  /// Defaults to mains, so a restaurant that never courses anything never has
  /// to think about it.
  final int course;

  bool get isVoid => status == OrderItemStatus.void_;

  /// True once the kitchen has been told about it, after which removing it is
  /// a void rather than a silent delete.
  bool get isSent => sentAt != null;

  factory OrderLine.fromRecord(RecordModel r) {
    final raw = r.get<dynamic>('modifiers');
    final mods = <SelectedModifier>[];
    if (raw is List) {
      for (final m in raw) {
        if (m is Map) {
          mods.add(SelectedModifier.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }

    final sent = r.getStringValue('sent_at');

    return OrderLine(
      id: r.id,
      orderId: r.getStringValue('order'),
      name: r.getStringValue('name_snapshot'),
      qty: r.getIntValue('qty'),
      unitPrice: r.getDoubleValue('unit_price'),
      modifiers: mods,
      modifiersTotal: r.getDoubleValue('modifiers_total'),
      lineTotal: r.getDoubleValue('line_total'),
      status: OrderItemStatus.parse(r.getStringValue('status')),
      menuItemId: r.getStringValue('menu_item'),
      note: r.getStringValue('note'),
      sentAt: sent.isEmpty ? null : DateTime.tryParse(sent)?.toLocal(),
      course: r.getIntValue('course') == 0 ? Course.mains : r.getIntValue('course'),
    );
  }
}


/// A network thermal printer. Receipt printers go by the till, kitchen ones by
/// the pass, so the same bill can print in two places with different content.
enum PrinterRole {
  receipt,
  kitchen,
  bar;

  static PrinterRole parse(String raw) => PrinterRole.values.firstWhere(
        (r) => r.name == raw,
        orElse: () => PrinterRole.receipt,
      );

  String get label => switch (this) {
        PrinterRole.receipt => 'Receipts',
        PrinterRole.kitchen => 'Kitchen',
        PrinterRole.bar => 'Bar',
      };
}

class Printer {
  const Printer({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.role,
    required this.paperWidth,
    required this.active,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final PrinterRole role;

  /// "58" or "80", matching the paper roll in millimetres.
  final String paperWidth;
  final bool active;

  factory Printer.fromRecord(RecordModel r) => Printer(
        id: r.id,
        name: r.getStringValue('name'),
        host: r.getStringValue('host'),
        port: r.getIntValue('port'),
        role: PrinterRole.parse(r.getStringValue('role')),
        paperWidth: r.getStringValue('paper_width'),
        active: r.getBoolValue('active'),
      );
}
