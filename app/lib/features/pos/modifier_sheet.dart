import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_field.dart';
import '../../data/models/menu.dart';
import '../../data/models/service.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/session.dart';

/// What the waiter chose before the line goes on the bill.
class LineChoice {
  const LineChoice({
    required this.qty,
    required this.modifiers,
    required this.note,
  });

  final int qty;
  final List<SelectedModifier> modifiers;
  final String note;
}

/// Asks the item's questions — size, extras, how it is cooked — plus quantity
/// and a note for the kitchen.
Future<LineChoice?> showLineChoiceSheet({
  required BuildContext context,
  required MenuItem item,
  required List<ModifierGroup> groups,
}) {
  return showDialog<LineChoice>(
    context: context,
    builder: (_) => _LineChoiceSheet(item: item, groups: groups),
  );
}

class _LineChoiceSheet extends ConsumerStatefulWidget {
  const _LineChoiceSheet({required this.item, required this.groups});

  final MenuItem item;
  final List<ModifierGroup> groups;

  @override
  ConsumerState<_LineChoiceSheet> createState() => _LineChoiceSheetState();
}

class _LineChoiceSheetState extends ConsumerState<_LineChoiceSheet> {
  final _note = TextEditingController();
  int _qty = 1;

  /// group id -> chosen modifier ids
  final Map<String, Set<String>> _picked = {};

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<Modifier> _optionsFor(String groupId) {
    final all = ref.read(modifiersProvider).value ?? const <Modifier>[];
    return all.where((m) => m.groupId == groupId && m.active).toList();
  }

  void _toggle(ModifierGroup group, Modifier modifier) {
    setState(() {
      final chosen = _picked.putIfAbsent(group.id, () => {});
      if (chosen.contains(modifier.id)) {
        chosen.remove(modifier.id);
        return;
      }
      // A single-select group swaps rather than accumulates; a multi-select one
      // stops accepting once it is full.
      if (group.maxSelect <= 1) {
        chosen
          ..clear()
          ..add(modifier.id);
      } else if (chosen.length < group.maxSelect) {
        chosen.add(modifier.id);
      }
    });
  }

  /// The first required group with nothing chosen, or null when good to go.
  ModifierGroup? get _unanswered {
    for (final g in widget.groups) {
      if (!g.required) continue;
      if ((_picked[g.id] ?? const {}).isEmpty) return g;
    }
    return null;
  }

  List<SelectedModifier> get _selection {
    final all = ref.read(modifiersProvider).value ?? const <Modifier>[];
    final out = <SelectedModifier>[];
    for (final g in widget.groups) {
      for (final id in _picked[g.id] ?? const <String>{}) {
        final m = all.where((x) => x.id == id).firstOrNull;
        if (m != null) {
          out.add(SelectedModifier(name: m.name, priceDelta: m.priceDelta));
        }
      }
    }
    return out;
  }

  double get _unitTotal =>
      widget.item.price + _selection.fold(0.0, (sum, m) => sum + m.priceDelta);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final symbol = ref.watch(currentRestaurantProvider)?.currencySymbol ?? '';

    // Watched so the options actually load; _optionsFor reads it.
    ref.watch(modifiersProvider);
    final blocked = _unanswered;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.item.name,
                            style: AppType.subtitle.copyWith(color: p.textPrimary)),
                        Text(
                          '$symbol${widget.item.price.toStringAsFixed(2)}',
                          style: AppType.small.copyWith(color: p.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, size: 20, color: p.textTertiary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(Space.lg),
                children: [
                  for (final group in widget.groups) ...[
                    Row(
                      children: [
                        Text(group.name,
                            style: AppType.bodyStrong.copyWith(
                              color: group.id == blocked?.id
                                  ? p.warning
                                  : p.textPrimary,
                            )),
                        const SizedBox(width: Space.xs),
                        Text(
                          group.required ? 'Required' : 'Optional',
                          style: AppType.caption.copyWith(
                            color: group.required ? p.brand : p.textTertiary,
                          ),
                        ),
                        if (group.maxSelect > 1) ...[
                          const SizedBox(width: Space.xs),
                          Text('up to ${group.maxSelect}',
                              style: AppType.caption.copyWith(color: p.textTertiary)),
                        ],
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                    Wrap(
                      spacing: Space.xs,
                      runSpacing: Space.xs,
                      children: [
                        for (final m in _optionsFor(group.id))
                          _OptionChip(
                            label: m.name,
                            priceLabel: m.priceDelta == 0
                                ? null
                                : '${m.priceDelta > 0 ? '+' : '−'}$symbol${m.priceDelta.abs().toStringAsFixed(2)}',
                            selected:
                                (_picked[group.id] ?? const {}).contains(m.id),
                            onTap: () => _toggle(group, m),
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.lg),
                  ],
                  AppField(
                    label: 'Note for the kitchen',
                    controller: _note,
                    hint: 'No onions, allergy, well done',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      _QtyStepper(
                        qty: _qty,
                        onChanged: (v) => setState(() => _qty = v),
                      ),
                      const Spacer(),
                      Text(
                        '$symbol${(_unitTotal * _qty).toStringAsFixed(2)}',
                        style: AppType.moneyLarge.copyWith(color: p.textPrimary),
                      ),
                    ],
                  ),
                  if (blocked != null) ...[
                    const SizedBox(height: Space.xs),
                    Row(
                      children: [
                        Icon(Icons.error_outline, size: 15, color: p.warning),
                        const SizedBox(width: Space.xxs + 2),
                        Expanded(
                          child: Text(
                            'Required: ${blocked.name}',
                            style: AppType.small.copyWith(color: p.warning),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: Space.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: blocked != null
                          ? null
                          : () => Navigator.of(context).pop(
                                LineChoice(
                                  qty: _qty,
                                  modifiers: _selection,
                                  note: _note.text,
                                ),
                              ),
                      child: const Text('Add to bill'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.priceLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? priceLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      color: selected ? p.brandSubtle : p.surfaceSunken,
      borderRadius: Radii.medium,
      child: InkWell(
        borderRadius: Radii.medium,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: Hit.control),
          padding: const EdgeInsets.symmetric(
              horizontal: Space.md, vertical: Space.xs),
          decoration: BoxDecoration(
            borderRadius: Radii.medium,
            border: Border.all(
              color: selected ? p.brand : p.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppType.body.copyWith(
                  color: selected ? p.brand : p.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (priceLabel != null) ...[
                const SizedBox(width: Space.xs),
                Text(priceLabel!,
                    style: AppType.small.copyWith(color: p.textTertiary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.qty, required this.onChanged});

  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget button(IconData icon, VoidCallback? onTap) => SizedBox(
          width: Hit.control,
          height: Hit.control,
          child: Material(
            color: p.surfaceSunken,
            borderRadius: Radii.medium,
            child: InkWell(
              borderRadius: Radii.medium,
              onTap: onTap,
              child: Icon(icon,
                  size: 18, color: onTap == null ? p.textTertiary : p.textPrimary),
            ),
          ),
        );

    return Row(
      children: [
        button(Icons.remove_rounded, qty > 1 ? () => onChanged(qty - 1) : null),
        SizedBox(
          width: 52,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: AppType.subtitle.copyWith(color: p.textPrimary),
          ),
        ),
        button(Icons.add_rounded, qty < 99 ? () => onChanged(qty + 1) : null),
      ],
    );
  }
}
