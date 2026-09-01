import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mise/data/offline/connection.dart';
import 'package:mise/data/offline/pending_writes.dart';
import 'package:mise/data/models/service.dart';
import 'package:pocketbase/pocketbase.dart';

PendingWrite write({
  int qty = 2,
  double price = 850,
  List<Map<String, dynamic>> mods = const [],
  String note = '',
  int course = Course.mains,
}) =>
    PendingWrite(
      id: 'pending-1',
      kind: PendingKind.addLine,
      orderId: 'o1',
      at: DateTime(2026, 9, 1, 20, 30),
      describe: '$qty × Sea bass',
      body: {
        'menu_item': 'm1',
        'name_snapshot': 'Sea bass',
        'qty': qty,
        'unit_price': price,
        'modifiers': mods,
        'note': note,
        'course': course,
        'status': 'queued',
      },
    );

void main() {
  group('surviving a restart', () {
    test('round-trips through JSON unchanged', () {
      final original = write(
        mods: [
          {'name': 'Large', 'price_delta': 150},
        ],
        note: 'no chilli',
        course: Course.starters,
      );
      final copy = PendingWrite.fromJson(original.toJson());

      expect(copy.id, original.id);
      expect(copy.kind, original.kind);
      expect(copy.orderId, original.orderId);
      expect(copy.describe, original.describe);
      expect(copy.at, original.at);
      expect(copy.body['name_snapshot'], 'Sea bass');
      expect(copy.body['note'], 'no chilli');
    });

    test('a corrupted entry does not take the queue down with it', () {
      // Missing everything: the app has to come up regardless, because the
      // alternative is a till that will not open mid-service.
      final salvaged = PendingWrite.fromJson(<String, dynamic>{});
      expect(salvaged.kind, PendingKind.addLine);
      expect(salvaged.body, isEmpty);
      expect(() => salvaged.asProvisionalLine(), returnsNormally);
    });
  });

  group('what the till shows before it syncs', () {
    test('prices the line the same way the server will', () {
      final line = write(qty: 2, price: 850, mods: [
        {'name': 'Large', 'price_delta': 150},
        {'name': 'Side salad', 'price_delta': 120},
      ]).asProvisionalLine();

      expect(line.modifiersTotal, 270);
      expect(line.lineTotal, (850 + 270) * 2);
      expect(line.qty, 2);
      expect(line.name, 'Sea bass');
    });

    test('carries the note and the course through', () {
      final line = write(note: 'allergy', course: Course.starters).asProvisionalLine();
      expect(line.note, 'allergy');
      expect(line.course, Course.starters);
    });

    test('is identifiable as not yet real', () {
      expect(isProvisional(write().asProvisionalLine()), isTrue);
    });

    test('a saved line is not mistaken for a queued one', () {
      final saved = OrderLine(
        id: 'abc123xyz', orderId: 'o1', name: 'Steak', qty: 1, unitPrice: 100,
        modifiers: const [], modifiersTotal: 0, lineTotal: 100,
        status: OrderItemStatus.queued,
      );
      expect(isProvisional(saved), isFalse);
    });
  });

  group('deciding what is worth keeping', () {
    test('a connection that never landed is worth retrying', () {
      expect(isNetworkFailure(TimeoutException('slow')), isTrue);
      expect(isNetworkFailure(ClientException(statusCode: 0)), isTrue);
    });

    test('a refusal is not — replaying it would loop forever', () {
      expect(isNetworkFailure(ClientException(statusCode: 400)), isFalse,
          reason: 'the server heard us and said no');
      expect(isNetworkFailure(ClientException(statusCode: 403)), isFalse);
      expect(isNetworkFailure(ClientException(statusCode: 404)), isFalse);
      expect(isNetworkFailure(StateError('something else')), isFalse);
    });
  });
}
