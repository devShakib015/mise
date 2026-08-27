import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../data/models/menu.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../data/session.dart';

/// Modifier groups and their options — sizes, extras, cooking preference.
/// Groups are defined once here and attached to as many items as you like.
class ModifiersPage extends ConsumerWidget {
  const ModifiersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(modifierGroupsProvider);
    final modifiers = ref.watch(modifiersProvider);

    return Column(
      children: [
        PageHeader(
          title: 'Modifiers',
          subtitle: 'Choices you can attach to items. Define once, reuse everywhere.',
          action: FilledButton.icon(
            onPressed: () => _editGroup(context, null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New group'),
          ),
        ),
        Expanded(
          child: AsyncView<List<ModifierGroup>>(
            value: groups,
            onRetry: () => ref.invalidate(modifierGroupsProvider),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.tune_rounded,
                  title: 'No modifier groups yet',
                  message:
                      'A group is a question the till asks — "Choose a size", '
                      '"Any extras?" — and the options that answer it.',
                  action: FilledButton(
                    onPressed: () => _editGroup(context, null),
                    child: const Text('Create your first group'),
                  ),
                );
              }

              final byGroup = <String, List<Modifier>>{};
              for (final m in modifiers.value ?? const <Modifier>[]) {
                byGroup.putIfAbsent(m.groupId, () => []).add(m);
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xxl),
                itemCount: list.length,
                itemBuilder: (context, i) => _GroupCard(
                  key: ValueKey(list[i].id),
                  group: list[i],
                  modifiers: byGroup[list[i].id] ?? const [],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editGroup(BuildContext context, ModifierGroup? existing) =>
      showDialog<void>(
        context: context,
        builder: (_) => _GroupDialog(existing: existing),
      );
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({super.key, required this.group, required this.modifiers});

  final ModifierGroup group;
  final List<Modifier> modifiers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';

    // Spell the rule out in words; min/max numbers alone are easy to misread.
    final rule = group.required
        ? (group.isMultiSelect
            ? 'Required · pick ${group.minSelect} to ${group.maxSelect}'
            : 'Required · pick one')
        : (group.isMultiSelect
            ? 'Optional · up to ${group.maxSelect}'
            : 'Optional · pick one');

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: Radii.large,
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radii.lg),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => _GroupDialog(existing: group),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.name,
                              style: AppType.bodyStrong
                                  .copyWith(color: p.textPrimary)),
                          const SizedBox(height: 1),
                          Text(rule,
                              style: AppType.small.copyWith(color: p.textTertiary)),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined, size: 18, color: p.textTertiary),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: p.border),
            if (modifiers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.sm, vertical: Space.sm),
                child: Text('No options yet.',
                    style: AppType.small.copyWith(color: p.textTertiary)),
              )
            else
              for (final m in modifiers)
                _ModifierRow(modifier: m, symbol: symbol),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        _ModifierDialog(groupId: group.id, existing: null),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add option'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModifierRow extends StatelessWidget {
  const _ModifierRow({required this.modifier, required this.symbol});

  final Modifier modifier;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final delta = modifier.priceDelta;

    // A leading sign makes it obvious this is added to the price, not the price.
    final priceLabel = delta == 0
        ? 'Free'
        : '${delta > 0 ? '+' : '−'}$symbol${delta.abs().toStringAsFixed(2)}';

    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) =>
            _ModifierDialog(groupId: modifier.groupId, existing: modifier),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.sm, vertical: Space.xs + 2),
        child: Row(
          children: [
            Icon(Icons.circle, size: 5,
                color: modifier.active ? p.textTertiary : p.border),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                modifier.name,
                style: AppType.body.copyWith(
                  color: modifier.active ? p.textPrimary : p.textTertiary,
                ),
              ),
            ),
            if (!modifier.active)
              Padding(
                padding: const EdgeInsets.only(right: Space.xs),
                child: Text('Off',
                    style: AppType.caption.copyWith(color: p.textTertiary)),
              ),
            Text(
              priceLabel,
              style: AppType.money.copyWith(
                fontSize: 14,
                color: delta == 0 ? p.textTertiary : p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- dialogs

class _GroupDialog extends ConsumerStatefulWidget {
  const _GroupDialog({this.existing});

  final ModifierGroup? existing;

  @override
  ConsumerState<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends ConsumerState<_GroupDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late bool _required = widget.existing?.required ?? false;
  late bool _multi = (widget.existing?.maxSelect ?? 1) > 1;
  late final _max = TextEditingController(
      text: (widget.existing?.maxSelect ?? 1).toString());

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give the group a name.');
      return;
    }

    final maxSelect = _multi ? (int.tryParse(_max.text.trim()) ?? 1) : 1;
    if (_multi && maxSelect < 2) {
      setState(() => _error = 'A multiple-choice group must allow at least 2.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final count = ref.read(modifierGroupsProvider).value?.length ?? 0;
      await ref.read(menuRepositoryProvider).saveModifierGroup(
            id: widget.existing?.id,
            name: _name.text,
            minSelect: _required ? 1 : 0,
            maxSelect: maxSelect,
            required: _required,
            sortOrder: widget.existing?.sortOrder ?? count,
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
    final group = widget.existing;
    if (group == null) return;

    final ok = await confirmDestructive(
      context,
      title: 'Delete ${group.name}?',
      message: 'Its options go with it, and it is detached from every item '
          'that uses it. Orders already taken are unaffected.',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(menuRepositoryProvider).deleteModifierGroup(group.id);
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
    return FormDialog(
      title: widget.existing == null ? 'New modifier group' : 'Edit group',
      busy: _busy,
      error: _error,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        AppField(
          label: 'Name',
          controller: _name,
          hint: 'Choose a size',
          autofocus: true,
          enabled: !_busy,
        ),
        const SizedBox(height: Space.lg),
        FormSwitch(
          label: 'Must be answered',
          description: _required
              ? 'The till will not let the item through without a choice.'
              : 'Staff can skip this.',
          value: _required,
          onChanged: _busy ? null : (v) => setState(() => _required = v),
        ),
        FormSwitch(
          label: 'Allow more than one',
          description: _multi
              ? 'Several options can be picked at once.'
              : 'Exactly one option.',
          value: _multi,
          onChanged: _busy ? null : (v) => setState(() => _multi = v),
        ),
        if (_multi) ...[
          const SizedBox(height: Space.md),
          AppField(
            label: 'Most that can be picked',
            controller: _max,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ],
    );
  }
}

class _ModifierDialog extends ConsumerStatefulWidget {
  const _ModifierDialog({required this.groupId, this.existing});

  final String groupId;
  final Modifier? existing;

  @override
  ConsumerState<_ModifierDialog> createState() => _ModifierDialogState();
}

class _ModifierDialogState extends ConsumerState<_ModifierDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _price = TextEditingController(
      text: widget.existing == null
          ? '0'
          : widget.existing!.priceDelta.toStringAsFixed(2));
  late bool _active = widget.existing?.active ?? true;

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final delta = double.tryParse(_price.text.trim());
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give the option a name.');
      return;
    }
    if (delta == null) {
      setState(() => _error = 'Enter an amount, or 0 if it is free.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final siblings = (ref.read(modifiersProvider).value ?? const <Modifier>[])
          .where((m) => m.groupId == widget.groupId)
          .length;

      await ref.read(menuRepositoryProvider).saveModifier(
            id: widget.existing?.id,
            groupId: widget.groupId,
            name: _name.text,
            priceDelta: delta,
            sortOrder: widget.existing?.sortOrder ?? siblings,
            active: _active,
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
    final modifier = widget.existing;
    if (modifier == null) return;

    final ok = await confirmDestructive(
      context,
      title: 'Delete ${modifier.name}?',
      message: 'This option will no longer be offered.',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(menuRepositoryProvider).deleteModifier(modifier.id);
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
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';

    return FormDialog(
      title: widget.existing == null ? 'New option' : 'Edit option',
      busy: _busy,
      error: _error,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        AppField(
          label: 'Name',
          controller: _name,
          hint: 'Large',
          autofocus: true,
          enabled: !_busy,
        ),
        const SizedBox(height: Space.md),
        AppField(
          label: 'Price change',
          controller: _price,
          enabled: !_busy,
          helper: 'Added to the item price. Use a minus for a discount, 0 if free.',
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
          prefix: Padding(
            padding: const EdgeInsets.only(left: Space.sm, right: Space.xxs),
            child: Center(
              widthFactor: 1,
              child: Text(symbol,
                  style: AppType.body.copyWith(color: p.textTertiary)),
            ),
          ),
        ),
        const SizedBox(height: Space.lg),
        FormSwitch(
          label: 'Offered',
          description: _active
              ? 'Shown on the till.'
              : 'Hidden, without deleting it.',
          value: _active,
          onChanged: _busy ? null : (v) => setState(() => _active = v),
        ),
      ],
    );
  }
}
