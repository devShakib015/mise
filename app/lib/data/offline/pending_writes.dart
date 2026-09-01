import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../models/service.dart';
import '../prefs.dart';
import '../repositories/menu_repository.dart' show pbProvider;
import '../repositories/service_repository.dart' show orderLinesProvider;
import 'connection.dart';

enum PendingKind { addLine, updateLine, removeLine }

/// One write that has not reached the server yet.
class PendingWrite {
  const PendingWrite({
    required this.id,
    required this.kind,
    required this.orderId,
    required this.body,
    required this.at,
    this.lineId = '',
    this.describe = '',
  });

  final String id;
  final PendingKind kind;
  final String orderId;
  final Map<String, dynamic> body;
  final DateTime at;

  /// Empty for a line that does not exist on the server yet.
  final String lineId;

  /// What to show a waiter — "2 × Chicken biryani", not a record id.
  final String describe;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'orderId': orderId,
        'lineId': lineId,
        'body': body,
        'at': at.toIso8601String(),
        'describe': describe,
      };

  factory PendingWrite.fromJson(Map<String, dynamic> j) => PendingWrite(
        id: '${j['id']}',
        kind: PendingKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => PendingKind.addLine,
        ),
        orderId: '${j['orderId']}',
        lineId: '${j['lineId'] ?? ''}',
        body: Map<String, dynamic>.from(j['body'] as Map? ?? {}),
        at: DateTime.tryParse('${j['at']}') ?? DateTime.now(),
        describe: '${j['describe'] ?? ''}',
      );

  /// What the till shows for a line that is only in the queue so far.
  OrderLine asProvisionalLine() {
    final mods = <SelectedModifier>[];
    final raw = body['modifiers'];
    if (raw is List) {
      for (final m in raw) {
        if (m is Map) {
          mods.add(SelectedModifier.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }
    final qty = (body['qty'] as num?)?.toInt() ?? 1;
    final unit = (body['unit_price'] as num?)?.toDouble() ?? 0;
    final extra = mods.fold(0.0, (s, m) => s + m.priceDelta);

    return OrderLine(
      id: id,
      orderId: orderId,
      name: '${body['name_snapshot'] ?? ''}',
      qty: qty,
      unitPrice: unit,
      modifiers: mods,
      modifiersTotal: extra,
      lineTotal: (unit + extra) * qty,
      status: OrderItemStatus.queued,
      note: '${body['note'] ?? ''}',
      course: (body['course'] as num?)?.toInt() ?? Course.mains,
    );
  }
}

/// Writes that could not reach the server, kept on disk until they can.
///
/// Deliberately narrow: only the lines on a bill. Opening a bill needs a
/// number the server assigns, and settling one needs a total only the server
/// computes — neither can be honestly faked on a tablet. What a waiter does
/// most, and what a dropped connection interrupts most, is putting food on a
/// bill, and that is what survives here.
class PendingWrites extends Notifier<List<PendingWrite>> {
  bool _flushing = false;

  @override
  List<PendingWrite> build() {
    final raw = ref.read(prefsProvider).pendingWrites;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          PendingWrite.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<PendingWrite> next) async {
    state = next;
    await ref
        .read(prefsProvider)
        .setPendingWrites(jsonEncode(next.map((w) => w.toJson()).toList()));
  }

  Future<void> add(PendingWrite write) => _persist([...state, write]);

  List<PendingWrite> forOrder(String orderId) =>
      state.where((w) => w.orderId == orderId).toList();

  /// Sends everything waiting, oldest first.
  ///
  /// Stops at the first network failure so ordering is preserved — replaying
  /// out of order could put a quantity change before the line it changes.
  /// A write the server actively *rejects* is dropped rather than retried
  /// forever; it is never going to succeed.
  Future<int> flush() async {
    if (_flushing || state.isEmpty) return 0;
    _flushing = true;

    final PocketBase pb;
    try {
      pb = ref.read(pbProvider);
    } catch (_) {
      _flushing = false;
      return 0;
    }

    final remaining = <PendingWrite>[];
    var sent = 0;
    var stopped = false;

    for (final write in state) {
      if (stopped) {
        remaining.add(write);
        continue;
      }
      try {
        switch (write.kind) {
          case PendingKind.addLine:
            await pb.collection('order_items').create(body: {
              ...write.body,
              'order': write.orderId,
            });
          case PendingKind.updateLine:
            await pb
                .collection('order_items')
                .update(write.lineId, body: write.body);
          case PendingKind.removeLine:
            await pb.collection('order_items').delete(write.lineId);
        }
        sent++;
      } catch (err) {
        if (isNetworkFailure(err)) {
          remaining.add(write);
          stopped = true;
        }
        // Anything else: the server heard it and refused. Drop it.
      }
    }

    await _persist(remaining);
    _flushing = false;

    if (sent > 0) ref.read(connectionProvider.notifier).reportSuccess();
    return sent;
  }

  /// Throws the queue away. Only offered as a last resort, behind a warning.
  Future<void> discard() => _persist(const []);
}

final pendingWritesProvider =
    NotifierProvider<PendingWrites, List<PendingWrite>>(PendingWrites.new);

/// A bill's lines as the till should show them: what the server has, plus
/// anything still queued, marked provisional.
final ticketLinesProvider =
    Provider.family<List<OrderLine>, String>((ref, orderId) {
  final saved = ref.watch(orderLinesProvider(orderId)).value ?? const <OrderLine>[];
  final queued = ref
      .watch(pendingWritesProvider)
      .where((w) => w.orderId == orderId && w.kind == PendingKind.addLine)
      .map((w) => w.asProvisionalLine())
      .toList();
  return [...saved, ...queued];
});

/// True for a line that exists only in the queue.
bool isProvisional(OrderLine line) => line.id.startsWith('pending-');

/// Flushes the queue whenever the server comes back.
///
/// Watched from the shell so it runs wherever a till is open, rather than
/// depending on someone being on a particular screen when the wi-fi returns.
final queueFlusherProvider = Provider<void>((ref) {
  ref.listen<Reachability>(connectionProvider, (was, now) {
    if (now == Reachability.online && was != Reachability.online) {
      ref.read(pendingWritesProvider.notifier).flush();
    }
  });
});
