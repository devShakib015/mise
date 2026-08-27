import 'package:pocketbase/pocketbase.dart';

/// A section of the menu. Categories drive the top-level tabs on the POS grid,
/// so their order matters more than it looks.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.active,
    this.color = '',
    this.image = '',
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool active;
  final String color;
  final String image;

  factory Category.fromRecord(RecordModel r) => Category(
        id: r.id,
        name: r.getStringValue('name'),
        sortOrder: r.getIntValue('sort_order'),
        active: r.getBoolValue('active'),
        color: r.getStringValue('color'),
        image: r.getStringValue('image'),
      );
}

/// Tags shown on an item. Kept to the set the schema allows so the two cannot
/// drift apart.
enum MenuTag {
  vegetarian,
  vegan,
  spicy,
  halal,
  glutenFree,
  isNew,
  popular,
  chefSpecial;

  /// The stored value. Dart cannot name a member `new`, and `gluten_free` is
  /// not a valid identifier, so the mapping is explicit.
  String get wire => switch (this) {
        MenuTag.glutenFree => 'gluten_free',
        MenuTag.isNew => 'new',
        MenuTag.chefSpecial => 'chef_special',
        _ => name,
      };

  String get label => switch (this) {
        MenuTag.vegetarian => 'Vegetarian',
        MenuTag.vegan => 'Vegan',
        MenuTag.spicy => 'Spicy',
        MenuTag.halal => 'Halal',
        MenuTag.glutenFree => 'Gluten free',
        MenuTag.isNew => 'New',
        MenuTag.popular => 'Popular',
        MenuTag.chefSpecial => "Chef's special",
      };

  static MenuTag? parse(String raw) {
    for (final t in MenuTag.values) {
      if (t.wire == raw) return t;
    }
    return null;
  }
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.active,
    required this.available,
    required this.sortOrder,
    this.description = '',
    this.image = '',
    this.prepMinutes = 0,
    this.sku = '',
    this.tags = const [],
  });

  final String id;
  final String categoryId;
  final String name;
  final double price;

  /// On the menu at all.
  final bool active;

  /// In stock right now. Cleared when the kitchen runs out mid-service.
  final bool available;

  final int sortOrder;
  final String description;
  final String image;
  final int prepMinutes;
  final String sku;
  final List<MenuTag> tags;

  factory MenuItem.fromRecord(RecordModel r) => MenuItem(
        id: r.id,
        categoryId: r.getStringValue('category'),
        name: r.getStringValue('name'),
        price: r.getDoubleValue('price'),
        active: r.getBoolValue('active'),
        available: r.getBoolValue('available'),
        sortOrder: r.getIntValue('sort_order'),
        description: r.getStringValue('description'),
        image: r.getStringValue('image'),
        prepMinutes: r.getIntValue('prep_minutes'),
        sku: r.getStringValue('sku'),
        tags: r
            .getListValue<dynamic>('tags')
            .map((t) => MenuTag.parse(t.toString()))
            .whereType<MenuTag>()
            .toList(),
      );
}

/// A choice attached to an item — "Choose a size", "Add extras".
class ModifierGroup {
  const ModifierGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.required,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final bool required;
  final int sortOrder;

  /// True when the guest may tick more than one option.
  bool get isMultiSelect => maxSelect > 1;

  factory ModifierGroup.fromRecord(RecordModel r) => ModifierGroup(
        id: r.id,
        name: r.getStringValue('name'),
        minSelect: r.getIntValue('min_select'),
        maxSelect: r.getIntValue('max_select'),
        required: r.getBoolValue('required'),
        sortOrder: r.getIntValue('sort_order'),
      );
}

class Modifier {
  const Modifier({
    required this.id,
    required this.groupId,
    required this.name,
    required this.priceDelta,
    required this.sortOrder,
    required this.active,
  });

  final String id;
  final String groupId;
  final String name;

  /// Added to the line price. May be negative.
  final double priceDelta;
  final int sortOrder;
  final bool active;

  factory Modifier.fromRecord(RecordModel r) => Modifier(
        id: r.id,
        groupId: r.getStringValue('group'),
        name: r.getStringValue('name'),
        priceDelta: r.getDoubleValue('price_delta'),
        sortOrder: r.getIntValue('sort_order'),
        active: r.getBoolValue('active'),
      );
}
