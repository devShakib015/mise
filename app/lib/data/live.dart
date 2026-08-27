import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import 'repositories/menu_repository.dart' show pbProvider;

/// Loads a collection and re-emits the whole list whenever anything in it
/// changes.
///
/// [params] binds `{:name}` placeholders in [filter]. This has to go through
/// `pb.filter()`, which substitutes and escapes them client-side — passing them
/// as query parameters leaves the placeholder in the filter and the server
/// rejects the request.
///
/// Refetching rather than patching in place is deliberate for the collection
/// sizes here — a full reload cannot drift out of sync with the server the way
/// incremental patching quietly can.
Stream<List<T>> liveCollection<T>(
  Ref ref,
  String collection,
  T Function(RecordModel) mapper, {
  String sort = '',
  String filter = '',
  Map<String, dynamic> params = const {},
}) {
  final pb = ref.watch(pbProvider);
  final controller = StreamController<List<T>>();
  UnsubscribeFunc? unsubscribe;
  var closed = false;

  final boundFilter = params.isEmpty ? filter : pb.filter(filter, params);

  Future<void> refresh() async {
    if (closed) return;
    try {
      final records = await pb.collection(collection).getFullList(
            sort: sort,
            filter: boundFilter,
          );
      if (!closed) controller.add(records.map(mapper).toList());
    } catch (err, stack) {
      if (!closed) controller.addError(err, stack);
    }
  }

  Future<void> start() async {
    await refresh();
    if (closed) return;
    try {
      unsubscribe = await pb.collection(collection).subscribe('*', (_) => refresh());
    } catch (_) {
      // Realtime unavailable — the list still loaded, it just will not
      // live-update. Better than failing the screen outright.
    }
  }

  unawaited(start());

  ref.onDispose(() {
    closed = true;
    unsubscribe?.call();
    controller.close();
  });

  return controller.stream;
}
