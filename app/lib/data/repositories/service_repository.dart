import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../live.dart';
import '../models/audit.dart';
import '../offline/connection.dart';
import '../offline/pending_writes.dart';
import '../models/menu.dart';
import '../models/money.dart';
import '../models/service.dart';
import '../session.dart';
import 'menu_repository.dart' show pbProvider;

final tablesProvider = StreamProvider<List<DiningTable>>(
  (ref) => liveCollection(ref, 'tables', DiningTable.fromRecord,
      sort: 'zone,label'),
);

/// Orders that are still being worked on. Closed bills fall out of this list,
/// which keeps it short even in a busy service.
final liveOrdersProvider = StreamProvider<List<Order>>(
  (ref) => liveCollection(
    ref,
    'orders',
    Order.fromRecord,
    sort: '-created',
    filter: "status != 'paid' && status != 'cancelled'",
  ),
);

/// Lines on one order.
final orderLinesProvider = StreamProvider.family<List<OrderLine>, String>(
  (ref, orderId) => liveCollection(
    ref,
    'order_items',
    OrderLine.fromRecord,
    sort: 'created',
    filter: 'order = {:oid}',
    params: {'oid': orderId},
  ),
);

/// A single order, live, so the ticket total updates as the server recomputes it.
final orderProvider = StreamProvider.family<Order?, String>((ref, orderId) {
  return liveCollection(
    ref,
    'orders',
    Order.fromRecord,
    filter: 'id = {:oid}',
    params: {'oid': orderId},
  ).map((list) => list.isEmpty ? null : list.first);
});

/// Everything the kitchen still has to make: sent, not yet served, not voided.
final kitchenLinesProvider = StreamProvider<List<OrderLine>>(
  (ref) => liveCollection(
    ref,
    'order_items',
    OrderLine.fromRecord,
    sort: 'sent_at,created',
    filter: "sent_at != null && status != 'served' && status != 'void'",
  ),
);

/// Ticks once a second so kitchen timers count up on their own.
final clockProvider = StreamProvider<DateTime>(
  (ref) => Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  ),
);

/// Payments taken against one bill.
final paymentsProvider = StreamProvider.family<List<Payment>, String>(
  (ref, orderId) => liveCollection(
    ref,
    'payments',
    Payment.fromRecord,
    sort: 'created',
    filter: 'order = {:oid}',
    params: {'oid': orderId},
  ),
);

/// The signed-in staff member's open till session, if they have one.
final activeShiftProvider = StreamProvider<Shift?>((ref) {
  final staff = ref.watch(currentStaffProvider);
  if (staff == null) return Stream.value(null);

  return liveCollection(
    ref,
    'shifts',
    Shift.fromRecord,
    sort: '-opened_at',
    filter: 'staff = {:sid} && closed_at = null',
    params: {'sid': staff.id},
  ).map((list) => list.isEmpty ? null : list.first);
});

/// What staff did, newest first. Manager-only by collection rule.
final auditProvider = StreamProvider.family<List<AuditEntry>, DateRange>(
  (ref, range) => liveCollection(
    ref,
    'audit_log',
    AuditEntry.fromRecord,
    sort: '-created',
    filter: 'created >= {:from} && created < {:to}',
    params: {'from': range.from.toUtc(), 'to': range.to.toUtc()},
  ),
);

final printersProvider = StreamProvider<List<Printer>>(
  (ref) => liveCollection(ref, 'printers', Printer.fromRecord, sort: 'role,name'),
);

/// A closed-open window of trading, used as a provider key.
class DateRange {
  const DateRange(this.from, this.to);

  /// Midnight to midnight for the day containing [d], in local time.
  factory DateRange.day(DateTime d) {
    final start = DateTime(d.year, d.month, d.day);
    return DateRange(start, start.add(const Duration(days: 1)));
  }

  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Bills *closed* in a window — settled or cancelled.
///
/// Deliberately keyed on when the bill closed rather than when it was opened.
/// A table seated before a shift began and settled during it is that shift's
/// takings; filtering on creation would credit the money to the wrong session
/// and leave the drawer looking short.
final closedOrdersProvider = StreamProvider.family<List<Order>, DateRange>(
  (ref, range) => liveCollection(
    ref,
    'orders',
    Order.fromRecord,
    sort: 'closed_at',
    filter: 'closed_at >= {:from} && closed_at < {:to}',
    params: {'from': range.from.toUtc(), 'to': range.to.toUtc()},
  ),
);

final rangePaymentsProvider = StreamProvider.family<List<Payment>, DateRange>(
  (ref, range) => liveCollection(
    ref,
    'payments',
    Payment.fromRecord,
    sort: 'created',
    filter: 'created >= {:from} && created < {:to}',
    params: {'from': range.from.toUtc(), 'to': range.to.toUtc()},
  ),
);

/// Lines belonging to bills closed in a window.
///
/// Filtered through the relation (`order.closed_at`) so it stays in step with
/// [closedOrdersProvider] — the parts of a report must add up to its whole.
final closedOrderLinesProvider = StreamProvider.family<List<OrderLine>, DateRange>(
  (ref, range) => liveCollection(
    ref,
    'order_items',
    OrderLine.fromRecord,
    sort: 'created',
    filter: "order.closed_at >= {:from} && order.closed_at < {:to} && status != 'void'",
    params: {'from': range.from.toUtc(), 'to': range.to.toUtc()},
  ),
);

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ServiceRepository(ref.watch(pbProvider), ref),
);

class ServiceRepository {
  const ServiceRepository(this._pb, this._ref);

  final PocketBase _pb;
  final Ref _ref;

  // ---------------------------------------------------------------- tables

  Future<void> saveTable({
    String? id,
    required String label,
    required int seats,
    required String zone,
    required bool active,
  }) async {
    final body = {
      'label': label.trim(),
      'seats': seats,
      'zone': zone.trim(),
      'active': active,
      if (id == null) 'status': TableStatus.free.name,
    };
    if (id == null) {
      await _pb.collection('tables').create(body: body);
    } else {
      await _pb.collection('tables').update(id, body: body);
    }
  }

  Future<void> deleteTable(String id) => _pb.collection('tables').delete(id);

  Future<void> setTableStatus(String id, TableStatus status) =>
      _pb.collection('tables').update(id, body: {'status': status.name});

  // ---------------------------------------------------------------- orders

  /// Opens a bill. Created server-side immediately rather than held locally, so
  /// a second waiter picking up the same table sees it straight away.
  Future<Order> openOrder({
    required String staffId,
    required OrderType type,
    String? tableId,
    int guestCount = 0,
    String customerName = '',
    String? shiftId,
  }) async {
    final record = await _pb.collection('orders').create(body: {
      'type': type.wire,
      'status': OrderStatus.open.name,
      'staff': staffId,
      'table': ?tableId,
      'shift': ?shiftId,
      'guest_count': guestCount,
      'customer_name': customerName.trim(),
    });

    if (tableId != null) {
      await setTableStatus(tableId, TableStatus.occupied);
    }
    return Order.fromRecord(record);
  }

  /// The open bill on a table, if there is one.
  Future<Order?> openOrderForTable(String tableId) async {
    try {
      final record = await _pb.collection('orders').getFirstListItem(
            _pb.filter(
              "table = {:t} && status != 'paid' && status != 'cancelled'",
              {'t': tableId},
            ),
          );
      return Order.fromRecord(record);
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------- order lines

  /// Adds a line, snapshotting the name, price and chosen modifiers so a later
  /// menu edit cannot rewrite this bill.
  Future<void> addLine({
    required String orderId,
    required MenuItem item,
    required int qty,
    List<SelectedModifier> modifiers = const [],
    String note = '',
    int course = Course.mains,
  }) async {
    final body = <String, dynamic>{
      'course': course,
      'menu_item': item.id,
      'name_snapshot': item.name,
      'qty': qty,
      'unit_price': item.price,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
      'note': note.trim(),
      'status': OrderItemStatus.queued.wire,
    };

    try {
      await _pb.collection('order_items').create(body: {...body, 'order': orderId});
      _ref.read(connectionProvider.notifier).reportSuccess();
    } catch (err) {
      // Only a write that never reached the server is worth keeping. One the
      // server refused would replay its rejection forever.
      if (!isNetworkFailure(err)) rethrow;

      _ref.read(connectionProvider.notifier).reportFailure();
      await _ref.read(pendingWritesProvider.notifier).add(PendingWrite(
            id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
            kind: PendingKind.addLine,
            orderId: orderId,
            body: body,
            at: DateTime.now(),
            describe: '$qty × ${item.name}',
          ));
    }
  }

  Future<void> setLineQty(String lineId, int qty) =>
      _pb.collection('order_items').update(lineId, body: {'qty': qty});

  Future<void> setLineCourse(String lineId, int course) =>
      _pb.collection('order_items').update(lineId, body: {'course': course});

  Future<void> setLineNote(String lineId, String note) =>
      _pb.collection('order_items').update(lineId, body: {'note': note.trim()});

  /// Removing a line the kitchen has never seen is a plain delete. Once it has
  /// been sent, it becomes a void with a reason, so the money is accounted for.
  ///
  /// Voids are written to the audit log. Along with discounts, this is where
  /// money quietly leaves a restaurant, so it is recorded against a name.
  Future<void> removeLine(
    OrderLine line, {
    required String staffId,
    String reason = '',
  }) async {
    if (!line.isSent) {
      await _pb.collection('order_items').delete(line.id);
      return;
    }

    await _pb.collection('order_items').update(line.id, body: {
      'status': OrderItemStatus.void_.wire,
      'void_reason': reason.trim(),
    });

    await _audit(staffId, 'void_item', 'order_items', line.id, {
      'order': line.orderId,
      'name': line.name,
      'qty': line.qty,
      'value': line.lineTotal,
      'reason': reason.trim(),
    });
  }

  /// Sends everything not yet sent to the kitchen, and moves the bill on.
  ///
  /// Returns the lines that went, so the caller can put them on a docket.
  /// Empty means there was nothing new to send.
  Future<List<OrderLine>> sendToKitchen({
    required String orderId,
    required String staffId,
    int? onlyCourse,
  }) async {
    final pending = await _pb.collection('order_items').getFullList(
          filter: onlyCourse == null
              ? _pb.filter(
                  "order = {:oid} && status != 'void' && sent_at = null",
                  {'oid': orderId},
                )
              : _pb.filter(
                  "order = {:oid} && status != 'void' && sent_at = null && course = {:c}",
                  {'oid': orderId, 'c': onlyCourse},
                ),
        );

    if (pending.isEmpty) return const [];

    final now = DateTime.now().toUtc().toIso8601String();
    for (final line in pending) {
      await _pb.collection('order_items').update(line.id, body: {'sent_at': now});
    }

    await _pb.collection('orders').update(orderId, body: {
      'status': OrderStatus.sent.name,
    });

    await _audit(staffId, 'send_to_kitchen', 'orders', orderId, {
      'lines': pending.length,
      'course': ?onlyCourse,
    });

    // Re-read so the returned lines carry the sent_at that was just written.
    return _pb
        .collection('order_items')
        .getFullList(filter: _pb.filter('order = {:oid}', {'oid': orderId}))
        .then((all) => all
            .where((r) => pending.any((p) => p.id == r.id))
            .map(OrderLine.fromRecord)
            .toList());
  }

  // -------------------------------------------------------------- kitchen

  Future<void> setLineStatus(String lineId, OrderItemStatus status) =>
      _pb.collection('order_items').update(lineId, body: {'status': status.wire});

  /// Moves every outstanding line on a ticket to [status] in one go.
  ///
  /// Returns how many lines moved, so the caller can say nothing happened
  /// rather than silently doing nothing.
  Future<int> setTicketStatus(String orderId, OrderItemStatus status) async {
    final lines = await _pb.collection('order_items').getFullList(
          filter: _pb.filter(
            "order = {:oid} && sent_at != null && status != 'void'",
            {'oid': orderId},
          ),
        );

    var moved = 0;
    for (final line in lines) {
      if (line.getStringValue('status') == status.wire) continue;
      await _pb.collection('order_items').update(
            line.id,
            body: {'status': status.wire},
          );
      moved++;
    }
    return moved;
  }

  Future<void> cancelOrder({
    required Order order,
    required String staffId,
    required String reason,
  }) async {
    await _pb.collection('orders').update(order.id, body: {
      'status': OrderStatus.cancelled.name,
      'note': reason.trim(),
    });
    await _audit(staffId, 'cancel_order', 'orders', order.id, {
      'reason': reason.trim(),
      'total': order.total,
    });
  }

  /// Moves a bill to another table.
  ///
  /// If that table already has a bill open, the two are merged rather than
  /// left as two bills on one table — which is what actually happens when a
  /// party gets up and joins another. Returns the id of the bill that survives.
  Future<String> moveOrder({
    required Order order,
    required String toTableId,
    required String staffId,
  }) async {
    final existing = await openOrderForTable(toTableId);
    final merging = existing != null && existing.id != order.id;

    if (merging) {
      // Carry the lines across, then close the emptied bill. Lines keep their
      // own snapshotted names and prices, so nothing is repriced by the move.
      final lines = await _pb.collection('order_items').getFullList(
            filter: _pb.filter('order = {:oid}', {'oid': order.id}),
          );
      for (final line in lines) {
        await _pb.collection('order_items').update(line.id, body: {'order': existing.id});
      }

      final payments = await _pb.collection('payments').getFullList(
            filter: _pb.filter('order = {:oid}', {'oid': order.id}),
          );
      for (final payment in payments) {
        await _pb.collection('payments').update(payment.id, body: {'order': existing.id});
      }

      await _pb.collection('orders').update(order.id, body: {
        'status': OrderStatus.cancelled.name,
        'note': 'Merged into bill #${existing.number}',
      });
    } else {
      await _pb.collection('orders').update(order.id, body: {'table': toTableId});
    }

    await setTableStatus(toTableId, TableStatus.occupied);

    // Free the table it left, unless someone else is still sitting there.
    if (order.tableId.isNotEmpty && order.tableId != toTableId) {
      final stillBusy = await openOrderForTable(order.tableId);
      if (stillBusy == null) {
        await setTableStatus(order.tableId, TableStatus.free);
      }
    }

    await _audit(staffId, merging ? 'merge_order' : 'move_order', 'orders',
        order.id, {
      'from': order.tableId,
      'to': toTableId,
      'number': order.number,
      if (merging) 'into': existing.number,
    });

    return merging ? existing.id : order.id;
  }


  /// Peels chosen lines off onto a second bill on the same table.
  ///
  /// For a table paying separately: each party ends up with their own bill,
  /// its own total and its own receipt, rather than one person guessing at a
  /// share. Lines carry their snapshotted prices, so nothing is repriced.
  Future<String> splitOrder({
    required Order order,
    required List<String> lineIds,
    required String staffId,
  }) async {
    if (lineIds.isEmpty) {
      throw ArgumentError('Choose at least one item to move.');
    }

    final fresh = await _pb.collection('orders').create(body: {
      'type': order.type.wire,
      'status': OrderStatus.open.name,
      'staff': staffId,
      if (order.tableId.isNotEmpty) 'table': order.tableId,
      'guest_count': 0,
      'note': 'Split from bill #${order.number}',
    });

    for (final id in lineIds) {
      await _pb.collection('order_items').update(id, body: {'order': fresh.id});
    }

    await _audit(staffId, 'split_order', 'orders', order.id, {
      'number': order.number,
      'into': fresh.getStringValue('number'),
      'lines': lineIds.length,
    });

    return fresh.id;
  }

  // -------------------------------------------------------------- payments

  /// Records money against a bill. The server decides whether that settles it.
  ///
  /// [amount] is what comes off the bill; [tendered] is what the guest actually
  /// handed over. Keeping them separate is what makes the drawer reconcile.
  Future<void> takePayment({
    required String orderId,
    required PaymentMethod method,
    required double amount,
    required String staffId,
    double tendered = 0,
    double changeDue = 0,
    String reference = '',
  }) async {
    await _pb.collection('payments').create(body: {
      'order': orderId,
      'method': method.name,
      'amount': amount,
      'tendered': tendered,
      'change_due': changeDue,
      'reference': reference.trim(),
      'staff': staffId,
    });
  }

  Future<void> voidPayment({
    required Payment payment,
    required String staffId,
  }) async {
    await _pb.collection('payments').delete(payment.id);
    await _audit(staffId, 'void_payment', 'payments', payment.id, {
      'order': payment.orderId,
      'method': payment.method.name,
      'amount': payment.amount,
    });
  }

  /// Discounts, like voids, are money leaving the building. Always audited.
  Future<void> applyDiscount({
    required Order order,
    required double amount,
    required String reason,
    required String staffId,
  }) async {
    await _pb.collection('orders').update(order.id, body: {
      'discount_amount': amount,
      'discount_reason': reason.trim(),
    });
    await _audit(staffId, 'discount', 'orders', order.id, {
      'number': order.number,
      'amount': amount,
      'reason': reason.trim(),
      'subtotal': order.subtotal,
    });
  }

  // -------------------------------------------------------------- printers

  Future<void> savePrinter({
    String? id,
    required String name,
    required String host,
    required int port,
    required PrinterRole role,
    required String paperWidth,
    required bool active,
  }) async {
    final body = {
      'name': name.trim(),
      'host': host.trim(),
      'port': port,
      'role': role.name,
      'paper_width': paperWidth,
      'active': active,
    };
    if (id == null) {
      await _pb.collection('printers').create(body: body);
    } else {
      await _pb.collection('printers').update(id, body: body);
    }
  }

  Future<void> deletePrinter(String id) => _pb.collection('printers').delete(id);

  // ---------------------------------------------------------------- shifts

  Future<Shift> openShift({
    required String staffId,
    required double openingCash,
  }) async {
    final record = await _pb.collection('shifts').create(body: {
      'staff': staffId,
      'opened_at': DateTime.now().toUtc().toIso8601String(),
      'opening_cash': openingCash,
    });
    return Shift.fromRecord(record);
  }

  /// What should be in the drawer: what it started with, plus every cash
  /// payment taken since. Card and mobile never touch it.
  Future<double> expectedCashFor(Shift shift) async {
    final since = (shift.openedAt ?? DateTime.now()).toUtc();
    final payments = await _pb.collection('payments').getFullList(
          filter: _pb.filter(
            "method = 'cash' && created >= {:since}",
            {'since': since},
          ),
        );

    var taken = 0.0;
    for (final p in payments) {
      taken += p.getDoubleValue('amount');
    }
    return _money(shift.openingCash + taken);
  }

  static double _money(double v) => (v * 100).round() / 100;

  Future<Shift> closeShift({
    required Shift shift,
    required double countedCash,
    required String staffId,
    String note = '',
  }) async {
    // Rounded before storing: floating point leaves artefacts like
    // -35.3400000000001, and money in the database should read as money.
    final expected = _money(await expectedCashFor(shift));
    final variance = _money(countedCash - expected);

    final record = await _pb.collection('shifts').update(shift.id, body: {
      'closed_at': DateTime.now().toUtc().toIso8601String(),
      'closing_cash': countedCash,
      'expected_cash': expected,
      'variance': variance,
      'note': note.trim(),
    });

    await _audit(staffId, 'close_shift', 'shifts', shift.id, {
      'expected': expected,
      'counted': countedCash,
      'variance': variance,
    });

    return Shift.fromRecord(record);
  }

  /// Voids and discounts are where money walks out of a restaurant, so they
  /// are written down. Best effort: an audit failure must not block service.
  Future<void> _audit(
    String staffId,
    String action,
    String entity,
    String entityId,
    Map<String, dynamic> detail,
  ) async {
    try {
      await _pb.collection('audit_log').create(body: {
        'staff': staffId,
        'action': action,
        'entity': entity,
        'entity_id': entityId,
        'detail': detail,
      });
    } catch (_) {
      // Deliberately swallowed.
    }
  }
}
