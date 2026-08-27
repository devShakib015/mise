import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/image_picking.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/search_picker.dart';
import '../../../data/models/menu.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../data/session.dart';

Future<void> showItemDialog(BuildContext context, MenuItem? existing) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ItemDialog(existing: existing),
  );
}

class _ItemDialog extends ConsumerStatefulWidget {
  const _ItemDialog({this.existing});

  final MenuItem? existing;

  @override
  ConsumerState<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends ConsumerState<_ItemDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _price = TextEditingController(
      text: widget.existing == null ? '' : widget.existing!.price.toStringAsFixed(2));
  late final _prep = TextEditingController(
      text: (widget.existing?.prepMinutes ?? 0).toString());
  late final _sku = TextEditingController(text: widget.existing?.sku ?? '');

  late String? _categoryId = widget.existing?.categoryId;
  late final Set<MenuTag> _tags = {...?widget.existing?.tags};
  late bool _active = widget.existing?.active ?? true;
  late bool _available = widget.existing?.available ?? true;

  ImageUpload? _newImage;
  bool _clearImage = false;
  Set<String> _groupIds = {};
  bool _groupsLoaded = false;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    // A brand new item drops into whichever category is being filtered, or the
    // first one, so the common case needs no extra tap.
    if (_categoryId == null) {
      final cats = ref.read(categoriesProvider).value ?? const <Category>[];
      if (cats.isNotEmpty) _categoryId = cats.first.id;
    }
  }

  Future<void> _loadGroups() async {
    final id = widget.existing?.id;
    if (id == null) {
      setState(() => _groupsLoaded = true);
      return;
    }
    try {
      final ids = await ref.read(itemModifierGroupIdsProvider(id).future);
      if (mounted) {
        setState(() {
          _groupIds = ids.toSet();
          _groupsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _groupsLoaded = true);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _prep, _sku]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await pickImage();
    if (!mounted || result.cancelled) return;

    setState(() {
      if (result.error != null) {
        _error = result.error;
      } else {
        _newImage = result.upload;
        _clearImage = false;
        _error = null;
      }
    });
  }

  Future<void> _pickCategory() async {
    final cats = ref.read(categoriesProvider).value ?? const <Category>[];
    final picked = await showSearchPicker<Category>(
      context: context,
      title: 'Category',
      options: cats,
      selected: cats.where((c) => c.id == _categoryId).firstOrNull,
      labelOf: (c) => c.name,
      searchHint: 'Search categories',
    );
    if (picked != null && mounted) setState(() => _categoryId = picked.id);
  }

  Future<void> _save() async {
    final price = double.tryParse(_price.text.trim());

    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give the item a name.');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Pick a category for this item.');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Enter a price.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final repo = ref.read(menuRepositoryProvider);
      final count = ref.read(menuItemsProvider).value?.length ?? 0;

      await repo.saveMenuItem(
        id: widget.existing?.id,
        categoryId: _categoryId!,
        name: _name.text,
        price: price,
        active: _active,
        available: _available,
        sortOrder: widget.existing?.sortOrder ?? count,
        description: _description.text,
        prepMinutes: int.tryParse(_prep.text.trim()) ?? 0,
        sku: _sku.text,
        tags: _tags.toList(),
        image: _newImage,
        clearImage: _clearImage,
      );

      // Attaching modifier groups needs the item's id, which a new item only
      // has after it is created — so this is a second pass either way.
      if (widget.existing != null) {
        await repo.setItemModifierGroups(widget.existing!.id, _groupIds.toList());
      } else if (_groupIds.isNotEmpty) {
        final fresh = ref.read(menuItemsProvider).value ?? const <MenuItem>[];
        final created = fresh.where((i) => i.name == _name.text.trim()).lastOrNull;
        if (created != null) {
          await repo.setItemModifierGroups(created.id, _groupIds.toList());
        }
      }

      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      setState(() {
        _busy = false;
        _error = '$err';
      });
    }
  }

  Future<void> _delete() async {
    final item = widget.existing;
    if (item == null) return;

    final ok = await confirmDestructive(
      context,
      title: 'Delete ${item.name}?',
      message: 'It will be removed from the menu. Past orders keep their own '
          'copy of the name and price, so your history stays intact.',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(menuRepositoryProvider).deleteMenuItem(item.id);
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
    final restaurant = ref.watch(currentRestaurantProvider);
    final symbol = restaurant?.currencySymbol ?? '';
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final groups = ref.watch(modifierGroupsProvider).value ?? const <ModifierGroup>[];

    final categoryName =
        cats.where((c) => c.id == _categoryId).firstOrNull?.name ?? 'Choose one';

    final existingImage = widget.existing == null || _clearImage
        ? ''
        : ref
            .read(menuRepositoryProvider)
            .fileUrl('menu_items', widget.existing!.id, widget.existing!.image);

    return FormDialog(
      title: widget.existing == null ? 'New item' : 'Edit item',
      width: 520,
      busy: _busy,
      error: _error,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        _ImageField(
          existingUrl: existingImage,
          picked: _newImage,
          enabled: !_busy,
          onPick: _pickImage,
          onClear: () => setState(() {
            _newImage = null;
            _clearImage = true;
          }),
        ),
        const SizedBox(height: Space.lg),

        AppField(
          label: 'Name',
          controller: _name,
          hint: 'Grilled sea bass',
          autofocus: true,
          enabled: !_busy,
        ),
        const SizedBox(height: Space.md),

        AppField(
          label: 'Description',
          controller: _description,
          hint: 'Optional — shown on the till and on receipts',
          enabled: !_busy,
        ),
        const SizedBox(height: Space.md),

        PickerField(
          label: 'Category',
          value: categoryName,
          enabled: !_busy,
          onTap: _pickCategory,
        ),
        const SizedBox(height: Space.md),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppField(
                label: 'Price',
                controller: _price,
                hint: '0.00',
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                prefix: Padding(
                  padding: const EdgeInsets.only(left: Space.sm, right: Space.xxs),
                  child: Center(
                    widthFactor: 1,
                    child: Text(symbol,
                        style: AppType.body.copyWith(color: p.textTertiary)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: AppField(
                label: 'Prep time',
                controller: _prep,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                helper: 'Minutes, for the kitchen display',
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.md),

        AppField(
          label: 'Item code',
          controller: _sku,
          hint: 'Optional',
          enabled: !_busy,
        ),
        const SizedBox(height: Space.lg),

        Text('Tags', style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final tag in MenuTag.values)
              _Toggle(
                label: tag.label,
                selected: _tags.contains(tag),
                onTap: _busy
                    ? null
                    : () => setState(() {
                          _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag);
                        }),
              ),
          ],
        ),
        const SizedBox(height: Space.lg),

        Text('Options', style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        if (groups.isEmpty)
          Text(
            'No modifier groups yet. Create them under Modifiers to offer sizes, '
            'extras or cooking preferences.',
            style: AppType.small.copyWith(color: p.textTertiary),
          )
        else if (!_groupsLoaded)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Space.xs),
            child: SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final g in groups)
                _Toggle(
                  label: g.name,
                  selected: _groupIds.contains(g.id),
                  onTap: _busy
                      ? null
                      : () => setState(() {
                            _groupIds.contains(g.id)
                                ? _groupIds.remove(g.id)
                                : _groupIds.add(g.id);
                          }),
                ),
            ],
          ),
        const SizedBox(height: Space.lg),

        FormSwitch(
          label: 'On the menu',
          description: _active
              ? 'Staff can add this to an order.'
              : 'Hidden from the till entirely.',
          value: _active,
          onChanged: _busy ? null : (v) => setState(() => _active = v),
        ),
        FormSwitch(
          label: 'In stock',
          description: _available
              ? 'Available to order right now.'
              : 'Marked sold out — shows as 86 on the till.',
          value: _available,
          onChanged: _busy ? null : (v) => setState(() => _available = v),
        ),
      ],
    );
  }
}

class _ImageField extends StatelessWidget {
  const _ImageField({
    required this.existingUrl,
    required this.picked,
    required this.enabled,
    required this.onPick,
    required this.onClear,
  });

  final String existingUrl;
  final ImageUpload? picked;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasImage = picked != null || existingUrl.isNotEmpty;

    return Row(
      children: [
        Container(
          width: 84,
          height: 84,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.surfaceSunken,
            borderRadius: Radii.large,
            border: Border.all(color: p.border),
          ),
          child: picked != null
              ? Image.memory(Uint8List.fromList(picked!.bytes), fit: BoxFit.cover)
              : existingUrl.isNotEmpty
                  ? Image.network(
                      existingUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          size: 22, color: p.textTertiary),
                    )
                  : Icon(Icons.add_photo_alternate_outlined,
                      size: 24, color: p.textTertiary),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Photo', style: AppType.bodyStrong.copyWith(color: p.textPrimary)),
              const SizedBox(height: 2),
              Text(
                'Optional. Shown on the till grid. Under 3MB.',
                style: AppType.small.copyWith(color: p.textTertiary),
              ),
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                    ),
                    onPressed: enabled ? onPick : null,
                    child: Text(hasImage ? 'Replace' : 'Choose'),
                  ),
                  if (hasImage) ...[
                    const SizedBox(width: Space.xs),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: p.textSecondary,
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: enabled ? onClear : null,
                      child: const Text('Remove'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      color: selected ? p.brandSubtle : p.surfaceSunken,
      borderRadius: Radii.pill,
      child: InkWell(
        borderRadius: Radii.pill,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Space.sm, vertical: Space.xs),
          decoration: BoxDecoration(
            borderRadius: Radii.pill,
            border: Border.all(color: selected ? p.brand : p.border),
          ),
          child: Text(
            label,
            style: AppType.small.copyWith(
              color: selected ? p.brand : p.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
