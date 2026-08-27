import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../data/models/menu.dart';
import '../../../data/repositories/menu_repository.dart';

/// Preset tile colours. A fixed set rather than a colour wheel — the POS grid
/// only reads well when the categories are visually distinct from each other.
const _swatches = <String>[
  '', '#EA580C', '#DC2626', '#D97706', '#65A30D',
  '#059669', '#0891B2', '#2563EB', '#7C3AED', '#DB2777',
];

Color? _parseSwatch(String hex) {
  if (hex.isEmpty || !hex.startsWith('#') || hex.length != 7) return null;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final items = ref.watch(menuItemsProvider);

    return Column(
      children: [
        PageHeader(
          title: 'Categories',
          subtitle: 'Sections of your menu. Their order is the order on the till.',
          action: FilledButton.icon(
            onPressed: () => _edit(context, ref, null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New category'),
          ),
        ),
        Expanded(
          child: AsyncView<List<Category>>(
            value: categories,
            onRetry: () => ref.invalidate(categoriesProvider),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.category_outlined,
                  title: 'No categories yet',
                  message:
                      'Starters, Mains, Drinks — whatever your menu is divided into. '
                      'Add one and you can start putting items in it.',
                  action: FilledButton(
                    onPressed: () => _edit(context, ref, null),
                    child: const Text('Add your first category'),
                  ),
                );
              }

              final counts = <String, int>{};
              for (final i in items.value ?? const <MenuItem>[]) {
                counts[i.categoryId] = (counts[i.categoryId] ?? 0) + 1;
              }

              return _ReorderableList(
                categories: list,
                counts: counts,
                onEdit: (c) => _edit(context, ref, c),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Category? existing) {
    return showDialog<void>(
      context: context,
      builder: (_) => _CategoryDialog(existing: existing),
    );
  }
}

class _ReorderableList extends ConsumerWidget {
  const _ReorderableList({
    required this.categories,
    required this.counts,
    required this.onEdit,
  });

  final List<Category> categories;
  final Map<String, int> counts;
  final ValueChanged<Category> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xxl),
      itemCount: categories.length,
      buildDefaultDragHandles: false,
      // onReorderItem already accounts for the removed item, so no index fixup.
      onReorderItem: (oldIndex, newIndex) async {
        final reordered = [...categories];
        reordered.insert(newIndex, reordered.removeAt(oldIndex));
        await ref.read(menuRepositoryProvider).reorderCategories(reordered);
      },
      itemBuilder: (context, index) {
        final c = categories[index];
        return _CategoryRow(
          key: ValueKey(c.id),
          index: index,
          category: c,
          itemCount: counts[c.id] ?? 0,
          onEdit: () => onEdit(c),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    super.key,
    required this.index,
    required this.category,
    required this.itemCount,
    required this.onEdit,
  });

  final int index;
  final Category category;
  final int itemCount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final swatch = _parseSwatch(category.color) ?? p.textTertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Material(
        color: p.surface,
        borderRadius: Radii.large,
        child: InkWell(
          borderRadius: Radii.large,
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.sm, vertical: Space.sm),
            decoration: BoxDecoration(
              borderRadius: Radii.large,
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xxs),
                      child: Icon(Icons.drag_indicator_rounded,
                          size: 20, color: p.textTertiary),
                    ),
                  ),
                ),
                const SizedBox(width: Space.xs),
                Container(
                  width: 10,
                  height: 36,
                  decoration: BoxDecoration(
                    color: swatch,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          style: AppType.bodyStrong.copyWith(
                              color: category.active
                                  ? p.textPrimary
                                  : p.textTertiary)),
                      Text(
                        itemCount == 1 ? '1 item' : '$itemCount items',
                        style: AppType.small.copyWith(color: p.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (!category.active)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.xs, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.surfaceSunken,
                      borderRadius: Radii.pill,
                      border: Border.all(color: p.border),
                    ),
                    child: Text('Hidden',
                        style: AppType.caption.copyWith(color: p.textTertiary)),
                  ),
                const SizedBox(width: Space.xs),
                Icon(Icons.chevron_right_rounded, size: 20, color: p.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({this.existing});

  final Category? existing;

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late String _color = widget.existing?.color ?? '';
  late bool _active = widget.existing?.active ?? true;

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give the category a name.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final existingCount = ref.read(categoriesProvider).value?.length ?? 0;
      await ref.read(menuRepositoryProvider).saveCategory(
            id: widget.existing?.id,
            name: _name.text,
            color: _color,
            active: _active,
            sortOrder: widget.existing?.sortOrder ?? existingCount,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      setState(() {
        _busy = false;
        _error = '$err';
      });
    }
  }

  Future<void> _delete() async {
    final category = widget.existing;
    if (category == null) return;

    final items = ref.read(menuItemsProvider).value ?? const <MenuItem>[];
    final used = items.where((i) => i.categoryId == category.id).length;

    final ok = await confirmDestructive(
      context,
      title: 'Delete ${category.name}?',
      message: used == 0
          ? 'This category will be removed. It has no items in it.'
          : 'This category still holds $used ${used == 1 ? 'item' : 'items'}. '
              'Move them somewhere else first, or they will be left without a '
              'category.',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(menuRepositoryProvider).deleteCategory(category.id);
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      setState(() {
        _busy = false;
        _error = '$err';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return FormDialog(
      title: widget.existing == null ? 'New category' : 'Edit category',
      busy: _busy,
      error: _error,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        AppField(
          label: 'Name',
          controller: _name,
          hint: 'Starters',
          autofocus: true,
          enabled: !_busy,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: Space.lg),
        Text('Tile colour', style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        Text('Shown on the till so staff can find this section fast.',
            style: AppType.small.copyWith(color: p.textTertiary)),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final hex in _swatches)
              _Swatch(
                hex: hex,
                selected: _color == hex,
                onTap: _busy ? null : () => setState(() => _color = hex),
              ),
          ],
        ),
        const SizedBox(height: Space.lg),
        FormSwitch(
          label: 'Visible on the till',
          description: _active
              ? 'Staff can see this category and its items.'
              : 'Hidden from the till, but nothing is deleted.',
          value: _active,
          onChanged: _busy ? null : (v) => setState(() => _active = v),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.hex, required this.selected, required this.onTap});

  final String hex;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = _parseSwatch(hex);

    return InkWell(
      borderRadius: Radii.medium,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color ?? p.surfaceSunken,
          borderRadius: Radii.medium,
          border: Border.all(
            color: selected ? p.textPrimary : p.border,
            width: selected ? 2 : 1,
          ),
        ),
        // The empty swatch means "no colour", drawn as a subtle slash.
        child: color == null
            ? Icon(Icons.block_rounded, size: 16, color: p.textTertiary)
            : selected
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : null,
      ),
    );
  }
}
