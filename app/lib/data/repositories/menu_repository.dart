import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

import '../models/menu.dart';
import '../session.dart';

/// The PocketBase client for the signed-in session.
///
/// Only valid inside a signed-in shell; screens outside one never reach it.
final pbProvider = Provider<PocketBase>((ref) {
  ref.watch(sessionProvider);
  return ref.read(sessionProvider.notifier).pb;
});

/// Loads a collection and re-emits the whole list whenever anything in it
/// changes.
///
/// Refetching rather than patching in place is deliberate: menu data is tens of
/// rows, and a full reload cannot drift out of sync with the server the way
/// incremental patching quietly can. Orders and the kitchen display will need
/// the incremental treatment; the menu does not.
Stream<List<T>> _liveCollection<T>(
  Ref ref,
  String collection,
  T Function(RecordModel) mapper, {
  String sort = '',
}) {
  final pb = ref.watch(pbProvider);
  final controller = StreamController<List<T>>();
  UnsubscribeFunc? unsubscribe;
  var closed = false;

  Future<void> refresh() async {
    if (closed) return;
    try {
      final records = await pb.collection(collection).getFullList(sort: sort);
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

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => _liveCollection(ref, 'categories', Category.fromRecord,
      sort: 'sort_order,name'),
);

final menuItemsProvider = StreamProvider<List<MenuItem>>(
  (ref) => _liveCollection(ref, 'menu_items', MenuItem.fromRecord,
      sort: 'sort_order,name'),
);

final modifierGroupsProvider = StreamProvider<List<ModifierGroup>>(
  (ref) => _liveCollection(ref, 'modifier_groups', ModifierGroup.fromRecord,
      sort: 'sort_order,name'),
);

final modifiersProvider = StreamProvider<List<Modifier>>(
  (ref) => _liveCollection(ref, 'modifiers', Modifier.fromRecord,
      sort: 'sort_order,name'),
);

/// Modifier groups attached to a given item, in display order.
final itemModifierGroupIdsProvider =
    FutureProvider.family<List<String>, String>((ref, itemId) async {
  final pb = ref.watch(pbProvider);
  final records = await pb.collection('menu_item_modifiers').getFullList(
        filter: 'menu_item = {:id}',
        query: {'id': itemId},
        sort: 'sort_order',
      );
  return records.map((r) => r.getStringValue('modifier_group')).toList();
});

final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => MenuRepository(ref.watch(pbProvider)),
);

/// Writes. Reads go through the live providers above.
class MenuRepository {
  const MenuRepository(this._pb);

  final PocketBase _pb;

  /// Public URL for a record's uploaded file.
  String fileUrl(String collection, String recordId, String filename) {
    if (filename.isEmpty) return '';
    return '${_pb.baseURL}/api/files/$collection/$recordId/$filename';
  }

  // ---------------------------------------------------------------- categories

  Future<void> saveCategory({
    String? id,
    required String name,
    required int sortOrder,
    required bool active,
    String color = '',
    ImageUpload? image,
    bool clearImage = false,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'sort_order': sortOrder,
      'active': active,
      'color': color,
      if (clearImage) 'image': null,
    };
    final files = image == null ? <http.MultipartFile>[] : [image.toMultipart('image')];

    if (id == null) {
      await _pb.collection('categories').create(body: body, files: files);
    } else {
      await _pb.collection('categories').update(id, body: body, files: files);
    }
  }

  Future<void> deleteCategory(String id) =>
      _pb.collection('categories').delete(id);

  /// Persists a drag-reordered list in one pass.
  Future<void> reorderCategories(List<Category> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].sortOrder == i) continue;
      await _pb.collection('categories').update(ordered[i].id, body: {'sort_order': i});
    }
  }

  // ---------------------------------------------------------------- menu items

  Future<void> saveMenuItem({
    String? id,
    required String categoryId,
    required String name,
    required double price,
    required bool active,
    required bool available,
    required int sortOrder,
    String description = '',
    int prepMinutes = 0,
    String sku = '',
    List<MenuTag> tags = const [],
    ImageUpload? image,
    bool clearImage = false,
  }) async {
    final body = <String, dynamic>{
      'category': categoryId,
      'name': name.trim(),
      'price': price,
      'active': active,
      'available': available,
      'sort_order': sortOrder,
      'description': description.trim(),
      'prep_minutes': prepMinutes,
      'sku': sku.trim(),
      'tags': tags.map((t) => t.wire).toList(),
      if (clearImage) 'image': null,
    };
    final files = image == null ? <http.MultipartFile>[] : [image.toMultipart('image')];

    if (id == null) {
      await _pb.collection('menu_items').create(body: body, files: files);
    } else {
      await _pb.collection('menu_items').update(id, body: body, files: files);
    }
  }

  Future<void> deleteMenuItem(String id) =>
      _pb.collection('menu_items').delete(id);

  /// The 86 toggle — out of stock, without taking it off the menu.
  Future<void> setItemAvailable(String id, bool available) =>
      _pb.collection('menu_items').update(id, body: {'available': available});

  // ------------------------------------------------------------------ modifiers

  Future<String> saveModifierGroup({
    String? id,
    required String name,
    required int minSelect,
    required int maxSelect,
    required bool required,
    required int sortOrder,
  }) async {
    final body = {
      'name': name.trim(),
      'min_select': minSelect,
      'max_select': maxSelect,
      'required': required,
      'sort_order': sortOrder,
    };
    final record = id == null
        ? await _pb.collection('modifier_groups').create(body: body)
        : await _pb.collection('modifier_groups').update(id, body: body);
    return record.id;
  }

  Future<void> deleteModifierGroup(String id) =>
      _pb.collection('modifier_groups').delete(id);

  Future<void> saveModifier({
    String? id,
    required String groupId,
    required String name,
    required double priceDelta,
    required int sortOrder,
    required bool active,
  }) async {
    final body = {
      'group': groupId,
      'name': name.trim(),
      'price_delta': priceDelta,
      'sort_order': sortOrder,
      'active': active,
    };
    if (id == null) {
      await _pb.collection('modifiers').create(body: body);
    } else {
      await _pb.collection('modifiers').update(id, body: body);
    }
  }

  Future<void> deleteModifier(String id) =>
      _pb.collection('modifiers').delete(id);

  /// Replaces the set of modifier groups attached to an item.
  Future<void> setItemModifierGroups(String itemId, List<String> groupIds) async {
    final existing = await _pb.collection('menu_item_modifiers').getFullList(
          filter: 'menu_item = {:id}',
          query: {'id': itemId},
        );

    for (final record in existing) {
      await _pb.collection('menu_item_modifiers').delete(record.id);
    }
    for (var i = 0; i < groupIds.length; i++) {
      await _pb.collection('menu_item_modifiers').create(body: {
        'menu_item': itemId,
        'modifier_group': groupIds[i],
        'sort_order': i,
      });
    }
  }
}

/// An image chosen on any platform, held in memory until it is uploaded.
class ImageUpload {
  const ImageUpload({required this.filename, required this.bytes});

  final String filename;
  final List<int> bytes;

  http.MultipartFile toMultipart(String field) =>
      http.MultipartFile.fromBytes(field, bytes, filename: filename);
}
