import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';
import '../theme/tokens.dart';
import 'app_field.dart';

/// A searchable list in a dialog, used wherever a plain dropdown would be worse:
/// long option lists, and anywhere a finger rather than a mouse is doing the
/// choosing. Flutter's DropdownButton anchors its menu to the selected item,
/// which on a long list drops it off the top of the screen entirely.
Future<T?> showSearchPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  String Function(T)? trailingOf,
  String Function(T)? searchTextOf,
  T? selected,
  String searchHint = 'Search',
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => _SearchPickerDialog<T>(
      title: title,
      options: options,
      labelOf: labelOf,
      trailingOf: trailingOf,
      searchTextOf: searchTextOf ?? labelOf,
      selected: selected,
      searchHint: searchHint,
    ),
  );
}

class _SearchPickerDialog<T> extends StatefulWidget {
  const _SearchPickerDialog({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.trailingOf,
    required this.searchTextOf,
    required this.selected,
    required this.searchHint,
  });

  final String title;
  final List<T> options;
  final String Function(T) labelOf;
  final String Function(T)? trailingOf;
  final String Function(T) searchTextOf;
  final T? selected;
  final String searchHint;

  @override
  State<_SearchPickerDialog<T>> createState() => _SearchPickerDialogState<T>();
}

class _SearchPickerDialogState<T> extends State<_SearchPickerDialog<T>> {
  final _query = TextEditingController();
  late List<T> _visible = widget.options;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _filter(String raw) {
    final q = raw.trim().toLowerCase();
    setState(() {
      _visible = q.isEmpty
          ? widget.options
          : widget.options
              .where((o) => widget.searchTextOf(o).toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.title,
                      style: AppType.subtitle.copyWith(color: p.textPrimary)),
                  const SizedBox(height: Space.md),
                  AppField(
                    label: '',
                    controller: _query,
                    hint: widget.searchHint,
                    autofocus: true,
                    onChanged: _filter,
                    prefix: Icon(Icons.search_rounded, size: 18, color: p.textTertiary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Flexible(
              child: _visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(Space.xxl),
                      child: Text(
                        'Nothing matches that.',
                        textAlign: TextAlign.center,
                        style: AppType.small.copyWith(color: p.textTertiary),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: Space.xs),
                      itemCount: _visible.length,
                      itemBuilder: (context, i) {
                        final option = _visible[i];
                        final isSelected = option == widget.selected;
                        final trailing = widget.trailingOf?.call(option);

                        return InkWell(
                          onTap: () => Navigator.of(context).pop(option),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.lg,
                              vertical: Space.sm,
                            ),
                            color: isSelected ? p.brandSubtle : null,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.labelOf(option),
                                    style: AppType.body.copyWith(
                                      color: isSelected ? p.brand : p.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (trailing != null)
                                  Text(
                                    trailing,
                                    style: AppType.small.copyWith(
                                      color: isSelected ? p.brand : p.textTertiary,
                                    ),
                                  ),
                                if (isSelected) ...[
                                  const SizedBox(width: Space.xs),
                                  Icon(Icons.check_rounded, size: 18, color: p.brand),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: p.border),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A field-shaped button that opens a picker. Looks like [AppField] so forms
/// stay visually consistent whether a value is typed or chosen.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
    this.enabled = true,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? helper;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        Material(
          color: p.surfaceSunken,
          borderRadius: Radii.medium,
          child: InkWell(
            borderRadius: Radii.medium,
            onTap: enabled ? onTap : null,
            child: Container(
              height: Hit.field,
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              decoration: BoxDecoration(
                borderRadius: Radii.medium,
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: AppType.body.copyWith(
                        color: enabled ? p.textPrimary : p.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.unfold_more_rounded, size: 18, color: p.textTertiary),
                ],
              ),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: Space.xxs + 2),
          Text(helper!, style: AppType.small.copyWith(color: p.textTertiary)),
        ],
      ],
    );
  }
}
