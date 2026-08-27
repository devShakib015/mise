import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../live.dart';
import '../models/menu.dart';
import '../models/service.dart';
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

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ServiceRepository(ref.watch(pbProvider)),
);

class ServiceRepository {
  const ServiceRepository(this._pb);

  final PocketBase _pb;

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
  }) async {
    final record = await _pb.collection('orders').create(body: {
      'type': type.wire,
      'status': OrderStatus.open.name,
      'staff': staffId,
      'table': ?tableId,
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
  }) async {
    await _pb.collection('order_items').create(body: {
      'order': orderId,
      'menu_item': item.id,
      'name_snapshot': item.name,
      'qty': qty,
      'unit_price': item.price,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
      'note': note.trim(),
      'status': OrderItemStatus.queued.wire,
    });
  }

  Future<void> setLineQty(String lineId, int qty) =>
      _pb.collection('order_items').update(lineId, body: {'qty': qty});

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
  /// Returns how many lines went. Zero means there was nothing new to send.
  Future<int> sendToKitchen({
    required String orderId,
    required String staffId,
  }) async {
    final pending = await _pb.collection('order_items').getFullList(
          filter: _pb.filter(
            "order = {:oid} && status != 'void' && sent_at = null",
            {'oid': orderId},
          ),
        );

    if (pending.isEmpty) return 0;

    final now = DateTime.now().toUtc().toIso8601String();
    for (final line in pending) {
      await _pb.collection('order_items').update(line.id, body: {'sent_at': now});
    }

    await _pb.collection('orders').update(orderId, body: {
      'status': OrderStatus.sent.name,
    });

    await _audit(staffId, 'send_to_kitchen', 'orders', orderId, {
      'lines': pending.length,
    });

    return pending.length;
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

  /// Moves a bill to a different table, freeing the one it came from.
  Future<void> moveOrder({
    required Order order,
    required String toTableId,
    required String staffId,
  }) async {
    await _pb.collection('orders').update(order.id, body: {'table': toTableId});
    await setTableStatus(toTableId, TableStatus.occupied);

    if (order.tableId.isNotEmpty && order.tableId != toTableId) {
      final stillBusy = await openOrderForTable(order.tableId);
      if (stillBusy == null) {
        await setTableStatus(order.tableId, TableStatus.free);
      }
    }

    await _audit(staffId, 'move_order', 'orders', order.id, {
      'from': order.tableId,
      'to': toTableId,
    });
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
