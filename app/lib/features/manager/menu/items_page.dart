import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/ui_state.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../data/models/menu.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../data/session.dart';
import 'item_dialog.dart';

final _searchProvider = uiValue<String>('');
final _categoryFilterProvider = uiValue<String?>(null);

class ItemsPage extends ConsumerWidget {
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(menuItemsProvider);
    final categories = ref.watch(categoriesProvider);

    return Column(
      children: [
        PageHeader(
          title: 'Items',
          subtitle: 'Everything you sell, and what it costs.',
          action: FilledButton.icon(
            onPressed: (categories.value ?? const []).isEmpty
                ? null
                : () => showItemDialog(context, null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New item'),
          ),
        ),
        Expanded(
          child: AsyncView<List<MenuItem>>(
            value: items,
            onRetry: () => ref.invalidate(menuItemsProvider),
            data: (all) {
              final cats = categories.value ?? const <Category>[];

              // An item needs somewhere to live, so this comes first.
              if (cats.isEmpty) {
                return const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'Add a category first',
                  message:
                      'Items live inside categories. Create one under Categories '
                      'and then come back here.',
                );
              }

              if (all.isEmpty) {
                return EmptyState(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'No items yet',
                  message:
                      'Add your dishes and drinks. Each one needs a name, a price '
                      'and a category — everything else is optional.',
                  action: FilledButton(
                    onPressed: () => showItemDialog(context, null),
                    child: const Text('Add your first item'),
                  ),
                );
              }

              return _ItemsBody(items: all, categories: cats);
            },
          ),
        ),
      ],
    );
  }
}

class _ItemsBody extends ConsumerWidget {
  const _ItemsBody({required this.items, required this.categories});

  final List<MenuItem> items;
  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_searchProvider).trim().toLowerCase();
    final categoryId = ref.watch(_categoryFilterProvider);

    final visible = items.where((i) {
      if (categoryId != null && i.categoryId != categoryId) return false;
      if (query.isEmpty) return true;
      return i.name.toLowerCase().contains(query) ||
          i.description.toLowerCase().contains(query) ||
          i.sku.toLowerCase().contains(query);
    }).toList();

    final byId = {for (final c in categories) c.id: c};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.sm),
          child: _Filters(categories: categories),
        ),
        Expanded(
          child: visible.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Nothing matches',
                  message: 'Try a different search, or clear the category filter.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xxl),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final item = visible[i];
                    return _ItemRow(
                      key: ValueKey(item.id),
                      item: item,
                      categoryName: byId[item.categoryId]?.name ?? 'Uncategorised',
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Filters extends ConsumerStatefulWidget {
  const _Filters({required this.categories});

  final List<Category> categories;

  @override
  ConsumerState<_Filters> createState() => _FiltersState();
}

class _FiltersState extends ConsumerState<_Filters> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = ref.watch(_categoryFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppField(
          label: '',
          controller: _search,
          hint: 'Search items',
          onChanged: (v) => ref.read(_searchProvider.notifier).set(v),
          prefix: Icon(Icons.search_rounded, size: 18, color: p.textTertiary),
        ),
        const SizedBox(height: Space.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: selected == null,
                onTap: () => ref.read(_categoryFilterProvider.notifier).set(null),
              ),
              for (final c in widget.categories)
                _FilterChip(
                  label: c.name,
                  selected: selected == c.id,
                  onTap: () =>
                      ref.read(_categoryFilterProvider.notifier).set(c.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(right: Space.xs),
      child: Material(
        color: selected ? p.brand : p.surfaceSunken,
        borderRadius: Radii.pill,
        child: InkWell(
          borderRadius: Radii.pill,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.md, vertical: Space.xs),
            decoration: BoxDecoration(
              borderRadius: Radii.pill,
              border: Border.all(color: selected ? p.brand : p.border),
            ),
            child: Text(
              label,
              style: AppType.small.copyWith(
                color: selected ? p.onBrand : p.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({super.key, required this.item, required this.categoryName});

  final MenuItem item;
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final restaurant = ref.watch(currentRestaurantProvider);
    final symbol = restaurant?.currencySymbol ?? '';
    final repo = ref.watch(menuRepositoryProvider);
    final imageUrl = repo.fileUrl('menu_items', item.id, item.image);

    final dimmed = !item.active;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Material(
        color: p.surface,
        borderRadius: Radii.large,
        child: InkWell(
          borderRadius: Radii.large,
          onTap: () => showItemDialog(context, item),
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              borderRadius: Radii.large,
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                _Thumb(url: imageUrl, dimmed: dimmed),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.bodyStrong.copyWith(
                                color: dimmed ? p.textTertiary : p.textPrimary,
                              ),
                            ),
                          ),
                          if (!item.available) ...[
                            const SizedBox(width: Space.xs),
                            _Pill(text: '86', tone: p.danger),
                          ],
                          if (dimmed) ...[
                            const SizedBox(width: Space.xs),
                            _Pill(text: 'Hidden', tone: p.textTertiary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        categoryName,
                        style: AppType.small.copyWith(color: p.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                Text(
                  '$symbol${item.price.toStringAsFixed(2)}',
                  style: AppType.money.copyWith(
                    color: dimmed ? p.textTertiary : p.textPrimary,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Tooltip(
                  message: item.available
                      ? 'In stock — tap to mark as sold out'
                      : 'Sold out — tap to put back on',
                  child: Switch(
                    value: item.available,
                    onChanged: (v) => repo.setItemAvailable(item.id, v),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.dimmed});

  final String url;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: Container(
        width: 48,
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.surfaceSunken,
          borderRadius: Radii.medium,
          border: Border.all(color: p.border),
        ),
        child: url.isEmpty
            ? Icon(Icons.restaurant_rounded, size: 20, color: p.textTertiary)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.broken_image_outlined, size: 18, color: p.textTertiary),
              ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: Radii.pill,
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: AppType.caption.copyWith(color: tone)),
    );
  }
}
