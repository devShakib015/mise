import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../data/models/service.dart';
import '../../../data/repositories/service_repository.dart';

class TablesPage extends ConsumerWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tablesProvider);

    return Column(
      children: [
        PageHeader(
          title: 'Tables',
          subtitle: 'Your floor. Group them into zones if the room has sections.',
          action: FilledButton.icon(
            onPressed: () => _edit(context, null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New table'),
          ),
        ),
        Expanded(
          child: AsyncView<List<DiningTable>>(
            value: tables,
            onRetry: () => ref.invalidate(tablesProvider),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.table_restaurant_outlined,
                  title: 'No tables yet',
                  message:
                      'Add the tables in your dining room. Takeaway orders work '
                      'without them, but dine-in service needs somewhere to seat '
                      'people.',
                  action: FilledButton(
                    onPressed: () => _edit(context, null),
                    child: const Text('Add your first table'),
                  ),
                );
              }

              // Group by zone, keeping unzoned tables together at the end.
              final zones = <String, List<DiningTable>>{};
              for (final t in list) {
                zones.putIfAbsent(t.zone.trim(), () => []).add(t);
              }
              final keys = zones.keys.toList()
                ..sort((a, b) => a.isEmpty ? 1 : (b.isEmpty ? -1 : a.compareTo(b)));

              return ListView(
                padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xxl),
                children: [
                  for (final zone in keys) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          top: Space.xs, bottom: Space.xs),
                      child: Text(
                        (zone.isEmpty ? 'No zone' : zone).toUpperCase(),
                        style: AppType.overline
                            .copyWith(color: context.palette.textTertiary),
                      ),
                    ),
                    Wrap(
                      spacing: Space.xs,
                      runSpacing: Space.xs,
                      children: [
                        for (final t in zones[zone]!)
                          _TableChip(table: t, onTap: () => _edit(context, t)),
                      ],
                    ),
                    const SizedBox(height: Space.md),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, DiningTable? existing) =>
      showDialog<void>(
        context: context,
        builder: (_) => _TableDialog(existing: existing),
      );
}

class _TableChip extends StatelessWidget {
  const _TableChip({required this.table, required this.onTap});

  final DiningTable table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dimmed = !table.active;

    return SizedBox(
      width: 128,
      child: Material(
        color: p.surface,
        borderRadius: Radii.large,
        child: InkWell(
          borderRadius: Radii.large,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              borderRadius: Radii.large,
              border: Border.all(color: p.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      table.label,
                      style: AppType.subtitle.copyWith(
                        color: dimmed ? p.textTertiary : p.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (dimmed)
                      Icon(Icons.visibility_off_outlined,
                          size: 14, color: p.textTertiary),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  table.seats == 1 ? '1 seat' : '${table.seats} seats',
                  style: AppType.small.copyWith(color: p.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableDialog extends ConsumerStatefulWidget {
  const _TableDialog({this.existing});

  final DiningTable? existing;

  @override
  ConsumerState<_TableDialog> createState() => _TableDialogState();
}

class _TableDialogState extends ConsumerState<_TableDialog> {
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late final _seats =
      TextEditingController(text: (widget.existing?.seats ?? 2).toString());
  late final _zone = TextEditingController(text: widget.existing?.zone ?? '');
  late bool _active = widget.existing?.active ?? true;

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _seats.dispose();
    _zone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty) {
      setState(() => _error = 'Give the table a name or number.');
      return;
    }
    final seats = int.tryParse(_seats.text.trim()) ?? 0;
    if (seats < 1) {
      setState(() => _error = 'A table needs at least one seat.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(serviceRepositoryProvider).saveTable(
            id: widget.existing?.id,
            label: _label.text,
            seats: seats,
            zone: _zone.text,
            active: _active,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      setState(() {
        _busy = false;
        // The label has a unique index, so a clash is the likely cause and
        // worth naming rather than showing a raw validation blob.
        _error = '$err'.contains('unique')
            ? 'There is already a table called "${_label.text.trim()}".'
            : '$err';
      });
    }
  }

  Future<void> _delete() async {
    final table = widget.existing;
    if (table == null) return;

    final open = await ref
        .read(serviceRepositoryProvider)
        .openOrderForTable(table.id);
    if (!mounted) return;

    if (open != null) {
      setState(() => _error =
          'This table has an open bill (#${open.number}). Settle or move it first.');
      return;
    }

    final ok = await confirmDestructive(
      context,
      title: 'Delete ${table.label}?',
      message: 'Past orders keep their record of it, so your history is intact.',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(serviceRepositoryProvider).deleteTable(table.id);
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
      title: widget.existing == null ? 'New table' : 'Edit table',
      busy: _busy,
      error: _error,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        AppField(
          label: 'Name or number',
          controller: _label,
          hint: 'T1',
          autofocus: true,
          enabled: !_busy,
        ),
        const SizedBox(height: Space.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppField(
                label: 'Seats',
                controller: _seats,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: AppField(
                label: 'Zone',
                controller: _zone,
                hint: 'Optional',
                enabled: !_busy,
                helper: 'Terrace, Bar, Upstairs',
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        FormSwitch(
          label: 'In use',
          description: _active
              ? 'Staff can seat guests here.'
              : 'Hidden from the floor, without deleting it.',
          value: _active,
          onChanged: _busy ? null : (v) => setState(() => _active = v),
        ),
      ],
    );
  }
}
