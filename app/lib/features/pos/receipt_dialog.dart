import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/printing/printer_client.dart';
import '../../core/printing/receipt.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/message_banner.dart';
import '../../data/models/money.dart';
import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';
import '../../data/session.dart';

Future<void> showReceiptDialog(BuildContext context, String orderId) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ReceiptDialog(orderId: orderId),
    );

class _ReceiptDialog extends ConsumerStatefulWidget {
  const _ReceiptDialog({required this.orderId});

  final String orderId;

  @override
  ConsumerState<_ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<_ReceiptDialog> {
  bool _busy = false;
  String? _error;
  String? _sent;

  Future<void> _print(ReceiptBuilder receipt, Printer printer) async {
    setState(() {
      _busy = true;
      _error = null;
      _sent = null;
    });

    final result = await PrinterClient.send(
      host: printer.host,
      port: printer.port,
      bytes: receipt.escPos(),
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.success ? null : result.message;
      _sent = result.success ? 'Sent to ${printer.name}.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final restaurant = ref.watch(currentRestaurantProvider);
    final order = ref.watch(orderProvider(widget.orderId)).value;
    final lines = ref.watch(orderLinesProvider(widget.orderId)).value ?? const <OrderLine>[];
    final payments = ref.watch(paymentsProvider(widget.orderId)).value ?? const <Payment>[];
    final tables = ref.watch(tablesProvider).value ?? const <DiningTable>[];
    final staff = ref.watch(currentStaffProvider);

    final receiptPrinters = (ref.watch(printersProvider).value ?? const <Printer>[])
        .where((x) => x.active && x.role == PrinterRole.receipt)
        .toList();

    if (restaurant == null || order == null) {
      return const Dialog(
        child: SizedBox(
          height: 160,
          child: Center(
            child: SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        ),
      );
    }

    final width = receiptPrinters.isEmpty
        ? PaperWidth.mm80
        : PaperWidth.parse(receiptPrinters.first.paperWidth);

    final receipt = ReceiptBuilder(
      restaurant: restaurant,
      order: order,
      lines: lines,
      payments: payments,
      width: width,
      staffName: staff?.name ?? '',
      tableLabel: tables.where((t) => t.id == order.tableId).firstOrNull?.label ?? '',
    );

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, Space.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Receipt',
                        style: AppType.subtitle.copyWith(color: p.textPrimary)),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Monospaced so the preview lines up exactly as the paper
                    // will. What you see here is what the printer receives.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Space.md),
                      decoration: BoxDecoration(
                        color: p.isDark ? p.surfaceSunken : const Color(0xFFFFFFFF),
                        borderRadius: Radii.medium,
                        border: Border.all(color: p.border),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          receipt.text(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
                            fontSize: 11.5,
                            height: 1.45,
                            color: p.isDark ? p.textPrimary : const Color(0xFF1C1917),
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: Space.md),
                      MessageBanner(message: _error!),
                    ],
                    if (_sent != null) ...[
                      const SizedBox(height: Space.md),
                      MessageBanner(tone: BannerTone.success, message: _sent!),
                    ],
                    if (!PrinterClient.isSupported) ...[
                      const SizedBox(height: Space.md),
                      const MessageBanner(
                        tone: BannerTone.info,
                        message:
                            'This is the browser version, which cannot reach a '
                            'thermal printer. Use the desktop or tablet app to '
                            'print.',
                      ),
                    ] else if (receiptPrinters.isEmpty) ...[
                      const SizedBox(height: Space.md),
                      const MessageBanner(
                        tone: BannerTone.info,
                        message:
                            'No receipt printer set up yet. A manager can add '
                            'one under Settings.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: p.border),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  if (PrinterClient.isSupported && receiptPrinters.isNotEmpty) ...[
                    const SizedBox(width: Space.xs),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _print(receipt, receiptPrinters.first),
                        icon: _busy
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.print_outlined, size: 18),
                        label: Text('Print to ${receiptPrinters.first.name}'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
