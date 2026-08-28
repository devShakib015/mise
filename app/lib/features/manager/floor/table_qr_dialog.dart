import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/message_banner.dart';
import '../../../data/models/service.dart';
import '../../../data/repositories/menu_repository.dart';

Future<void> showTableCodes(BuildContext context, List<DiningTable> tables) =>
    showDialog<void>(
      context: context,
      builder: (_) => _TableCodes(tables: tables),
    );

/// The codes that go on the tables.
///
/// Rendered on screen to be photographed or printed from a screenshot. The
/// address baked into each code is the machine's LAN address, so a guest's
/// phone reaches the restaurant's own server and nothing leaves the building.
class _TableCodes extends ConsumerWidget {
  const _TableCodes({required this.tables});

  final List<DiningTable> tables;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final active = tables.where((t) => t.active).toList();

    // Whatever this device is talking to is what a guest's phone must reach.
    // A code built from 127.0.0.1 would work here and nowhere else, so that
    // case is called out rather than silently producing useless codes.
    final base = ref.read(pbProvider).baseURL;
    final isLoopback = base.contains('127.0.0.1') || base.contains('localhost');

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, Space.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Table codes',
                            style: AppType.subtitle.copyWith(color: p.textPrimary)),
                        Text(
                          'Print one for each table. A guest scans it and orders '
                          'from their own phone.',
                          style: AppType.small.copyWith(color: p.textSecondary),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isLoopback)
                      const Padding(
                        padding: EdgeInsets.only(bottom: Space.md),
                        child: MessageBanner(
                          tone: BannerTone.warning,
                          message:
                              'This device is connected over 127.0.0.1, which only '
                              'works on this machine. Reconnect using the address '
                              'other devices use, then print these again.',
                        ),
                      ),
                    if (active.isEmpty)
                      Text('No tables in use yet.',
                          style: AppType.body.copyWith(color: p.textTertiary))
                    else
                      Wrap(
                        spacing: Space.md,
                        runSpacing: Space.md,
                        children: [
                          for (final t in active)
                            _Code(table: t, url: '$base/?t=${t.id}'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: p.border),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Text(
                'Screenshot this and print it, or photograph a single code.',
                textAlign: TextAlign.center,
                style: AppType.small.copyWith(color: p.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Code extends StatelessWidget {
  const _Code({required this.table, required this.url});

  final DiningTable table;
  final String url;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: 168,
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.large,
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          // Always on white: a dark-themed code is unreadable to half of
          // phone cameras, and this is going on paper anyway.
          Container(
            padding: const EdgeInsets.all(Space.xs),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: Radii.small,
            ),
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 128,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0C0A09),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0C0A09),
              ),
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(table.label,
              style: AppType.subtitle.copyWith(color: p.textPrimary)),
          if (table.zone.isNotEmpty)
            Text(table.zone,
                style: AppType.caption.copyWith(color: p.textTertiary)),
        ],
      ),
    );
  }
}
