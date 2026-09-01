import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';

/// Where a camera is actually available. Reading a long address off one screen
/// and typing it into a tablet is where setup goes wrong, so this is the
/// shortcut that matters — but only on devices that have a camera to point.
bool get canScanToConnect {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Opens the camera and returns the first server address it reads.
Future<String?> scanToConnect(BuildContext context) => showDialog<String>(
      context: context,
      builder: (_) => const _ScanDialog(),
    );

class _ScanDialog extends StatefulWidget {
  const _ScanDialog();

  @override
  State<_ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends State<_ScanDialog> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final code in capture.barcodes) {
      final raw = code.rawValue?.trim() ?? '';
      if (raw.isEmpty) continue;

      // Accept a bare address as readily as a full URL — someone may well have
      // generated the code elsewhere.
      final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'http://$raw');
      if (uri == null || uri.host.isEmpty) continue;

      _handled = true;
      Navigator.of(context).pop(raw);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, Space.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Point at the code',
                            style: AppType.subtitle.copyWith(color: p.textPrimary)),
                        Text(
                          'On the computer running your restaurant: '
                          'Settings → This device.',
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: ClipRRect(
                  borderRadius: Radii.large,
                  child: _error != null
                      ? Container(
                          color: p.surfaceSunken,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(Space.lg),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppType.small.copyWith(color: p.textSecondary),
                          ),
                        )
                      : MobileScanner(
                          controller: _controller,
                          onDetect: _onDetect,
                          errorBuilder: (context, error) {
                            // A refused camera is a permission problem, not a
                            // fault — say which so it can be fixed.
                            return Container(
                              color: p.surfaceSunken,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(Space.lg),
                              child: Text(
                                'The camera is not available. Allow camera '
                                'access for Mise, or type the address instead.',
                                textAlign: TextAlign.center,
                                style: AppType.small
                                    .copyWith(color: p.textSecondary),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Type it instead'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
