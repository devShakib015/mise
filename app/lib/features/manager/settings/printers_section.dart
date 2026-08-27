import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/printing/printer_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/message_banner.dart';
import '../../../data/models/service.dart';
import '../../../data/repositories/service_repository.dart';

/// Network thermal printers. Nearly all of them listen on TCP 9100 and take a
/// raw byte stream, so there is no driver to install — just an address.
class PrintersSection extends ConsumerWidget {
  const PrintersSection({super.key, required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final printers = ref.watch(printersProvider).value ?? const <Printer>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!PrinterClient.isSupported)
          const Padding(
            padding: EdgeInsets.only(bottom: Space.md),
            child: MessageBanner(
              tone: BannerTone.info,
              message:
                  'Printers can be set up here, but the browser version cannot '
                  'print to them. Use the desktop or tablet app for that.',
            ),
          ),
        if (printers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Text(
              'No printers yet. Add the address shown on your printer\'s '
              'self-test page.',
              style: AppType.small.copyWith(color: p.textTertiary),
            ),
          )
        else
          for (final printer in printers)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: _PrinterRow(printer: printer, canEdit: canEdit),
            ),
        const SizedBox(height: Space.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: canEdit ? () => _edit(context, null) : null,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add a printer'),
          ),
        ),
      ],
    );
  }

  static Future<void> _edit(BuildContext context, Printer? existing) =>
      showDialog<void>(
        context: context,
        builder: (_) => _PrinterDialog(existing: existing),
      );
}

class _PrinterRow extends ConsumerStatefulWidget {
  const _PrinterRow({required this.printer, required this.canEdit});

  final Printer printer;
  final bool canEdit;

  @override
  ConsumerState<_PrinterRow> createState() => _PrinterRowState();
}

class _PrinterRowState extends ConsumerState<_PrinterRow> {
  bool _testing = false;
  String? _result;
  bool _ok = false;

  /// Sends a short self-test so whoever is standing at the printer knows it is
  /// reachable before service starts, rather than finding out at the first bill.
  Future<void> _test() async {
    setState(() {
      _testing = true;
      _result = null;
    });

    final bytes = <int>[
      0x1B, 0x40, // initialise
      ...'Mise test print\n'.codeUnits,
      ...'${widget.printer.name}\n'.codeUnits,
      ...'${widget.printer.host}:${widget.printer.port}\n'.codeUnits,
      0x0A, 0x0A, 0x0A,
      0x1D, 0x56, 0x42, 0x00, // partial cut
    ];

    final r = await PrinterClient.send(
      host: widget.printer.host,
      port: widget.printer.port,
      bytes: bytes,
    );

    if (!mounted) return;
    setState(() {
      _testing = false;
      _ok = r.success;
      _result = r.success ? 'Test sent — check the paper.' : r.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final printer = widget.printer;

    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: Radii.medium,
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.print_outlined, size: 18, color: p.textTertiary),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(printer.name,
                            style: AppType.bodyStrong.copyWith(
                              color: printer.active ? p.textPrimary : p.textTertiary,
                            )),
                        const SizedBox(width: Space.xs),
                        Text(printer.role.label,
                            style: AppType.caption.copyWith(color: p.brand)),
                      ],
                    ),
                    Text(
                      '${printer.host}:${printer.port} · ${printer.paperWidth}mm'
                      '${printer.active ? '' : ' · off'}',
                      style: AppType.small.copyWith(color: p.textTertiary),
                    ),
                  ],
                ),
              ),
              if (PrinterClient.isSupported)
                TextButton(
                  onPressed: _testing ? null : _test,
                  child: _testing
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Test'),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: widget.canEdit
                    ? () => PrintersSection._edit(context, printer)
                    : null,
                icon: Icon(Icons.edit_outlined, size: 17, color: p.textTertiary),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: Space.xs),
            MessageBanner(
              tone: _ok ? BannerTone.success : BannerTone.danger,
              message: _result!,
            ),
          ],
        ],
      ),
    );
  }
}

class _PrinterDialog extends ConsumerStatefulWidget {
  const _PrinterDialog({this.existing});

  final Printer? existing;

  @override
  ConsumerState<_PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends ConsumerState<_PrinterDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _host = TextEditingController(text: widget.existing?.host ?? '');
  late final _port = TextEditingController(
      text: (widget.existing?.port ?? 9100).toString());
  late PrinterRole _role = widget.existing?.role ?? PrinterRole.receipt;
  late String _paper = widget.existing?.paperWidth ?? '80';
  late bool _active = widget.existing?.active ?? true;

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final port = int.tryParse(_port.text.trim()) ?? 0;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give the printer a name.');
      return;
    }
    if (_host.text.trim().isEmpty) {
      setState(() => _error = 'Enter the printer\'s address.');
      return;
    }
    if (port < 1 || port > 65535) {
      setState(() => _error = 'Port must be between 1 and 65535.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(serviceRepositoryProvider).savePrinter(
            id: widget.existing?.id,
            name: _name.text,
            host: _host.text,
            port: port,
            role: _role,
            paperWidth: _paper,
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
    final printer = widget.existing;
    if (printer == null) return;

    final ok = await confirmDestructive(
      context,
      title: 'Remove ${printer.name}?',
      message: 'The printer itself is untouched; it just stops being offered.',
      confirmLabel: 'Remove',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(serviceRepositoryProvider).deletePrinter(printer.id);
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
      title: widget.existing == null ? 'Add a printer' : 'Edit printer',
      busy: _busy,
      error: _error,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        AppField(
          label: 'Name',
          controller: _name,
          hint: 'Front counter',
          autofocus: true,
          enabled: !_busy,
        ),
        const SizedBox(height: Space.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: AppField(
                label: 'Address',
                controller: _host,
                hint: '192.168.1.50',
                enabled: !_busy,
                helper: 'Printed on the self-test page.',
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: AppField(
                label: 'Port',
                controller: _port,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                helper: 'Usually 9100.',
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        Text('What it prints',
            style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final r in PrinterRole.values)
              _Chip(
                label: r.label,
                selected: _role == r,
                onTap: _busy ? null : () => setState(() => _role = r),
              ),
          ],
        ),
        const SizedBox(height: Space.md),
        Text('Paper width',
            style: AppType.label.copyWith(color: p.textSecondary)),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final w in ['58', '80'])
              _Chip(
                label: '${w}mm',
                selected: _paper == w,
                onTap: _busy ? null : () => setState(() => _paper = w),
              ),
          ],
        ),
        const SizedBox(height: Space.lg),
        FormSwitch(
          label: 'In use',
          description: _active
              ? 'Offered when printing.'
              : 'Kept, but not offered.',
          value: _active,
          onChanged: _busy ? null : (v) => setState(() => _active = v),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

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
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          decoration: BoxDecoration(
            borderRadius: Radii.medium,
            border: Border.all(color: selected ? p.brand : p.border),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppType.body.copyWith(
                color: selected ? p.brand : p.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
