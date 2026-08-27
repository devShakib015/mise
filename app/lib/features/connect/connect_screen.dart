import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/centered_panel.dart';
import '../../core/widgets/message_banner.dart';
import '../../data/session.dart';

/// Points this device at the machine running the server.
///
/// On the back-office computer that is this machine. On a waiter's tablet or the
/// kitchen screen it is another box on the same wi-fi.
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key, this.initialError, this.initialUrl});

  final String? initialError;
  final String? initialUrl;

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  late final _controller = TextEditingController(
    text: widget.initialUrl ?? '127.0.0.1:8090',
  );
  late String? _error = widget.initialError;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await ref.read(sessionProvider.notifier).connect(_controller.text);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return CenteredPanel(
      subtitle: 'Restaurant management',
      footer: Text(
        'Free forever. Your data stays on your own machine.',
        style: AppType.small.copyWith(color: p.textTertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Connect to your server',
              style: AppType.title.copyWith(color: p.textPrimary)),
          const SizedBox(height: Space.xxs),
          Text(
            'Point this device at the computer running your restaurant.',
            style: AppType.body.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Space.xl),

          AppField(
            label: 'Server address',
            controller: _controller,
            hint: '127.0.0.1:8090',
            autofocus: true,
            enabled: !_busy,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _connect(),
            helper: 'Running the server on this computer? Leave this as it is.',
            prefix: Icon(Icons.dns_outlined, size: 18, color: p.textTertiary),
          ),

          if (_error != null) ...[
            const SizedBox(height: Space.md),
            MessageBanner(message: _error!),
          ],

          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: _busy ? null : _connect,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
