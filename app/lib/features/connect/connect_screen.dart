import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/centered_panel.dart';
import '../../core/widgets/message_banner.dart';
import '../../core/discovery/discovery.dart';
import '../../core/server/server_host.dart';
import 'scan_to_connect.dart';
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

  Future<void> _host() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await ref.read(sessionProvider.notifier).hostHere();

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
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

          if (Discovery.isSupported) ...[
            _FoundServers(
              busy: _busy,
              onPick: (server) {
                _controller.text = server.url;
                _connect();
              },
            ),
            const SizedBox(height: Space.md),
          ],

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
            suffix: canScanToConnect
                ? IconButton(
                    tooltip: 'Scan the code',
                    onPressed: _busy
                        ? null
                        : () async {
                            final scanned = await scanToConnect(context);
                            if (scanned == null || !mounted) return;
                            _controller.text = scanned;
                            _connect();
                          },
                    icon: Icon(Icons.qr_code_scanner_rounded,
                        size: 20, color: p.brand),
                  )
                : null,
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

          // The other half of setup: this machine can be the server. Offered
          // only where it is actually possible, so nobody is shown a button
          // their device cannot honour.
          if (ServerHost.isSupported) ...[
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(child: Divider(color: p.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                  child: Text('or',
                      style: AppType.small.copyWith(color: p.textTertiary)),
                ),
                Expanded(child: Divider(color: p.border)),
              ],
            ),
            const SizedBox(height: Space.lg),
            OutlinedButton.icon(
              onPressed: _busy ? null : _host,
              icon: const Icon(Icons.dns_rounded, size: 18),
              label: const Text('Run the restaurant on this computer'),
            ),
            const SizedBox(height: Space.xs),
            Text(
              'Sets everything up here. Tablets and the kitchen screen then '
              'join this machine over your wi-fi.',
              textAlign: TextAlign.center,
              style: AppType.small.copyWith(color: p.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}


/// Restaurants announcing themselves on this network.
///
/// Shown above the address field rather than replacing it: mDNS is blocked on
/// plenty of networks, and a setup screen that only works when the network
/// cooperates is not a setup screen.
class _FoundServers extends StatefulWidget {
  const _FoundServers({required this.busy, required this.onPick});

  final bool busy;
  final ValueChanged<FoundServer> onPick;

  @override
  State<_FoundServers> createState() => _FoundServersState();
}

class _FoundServersState extends State<_FoundServers> {
  late final Stream<List<FoundServer>> _stream = Discovery.search();

  @override
  void dispose() {
    Discovery.stopSearching();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return StreamBuilder<List<FoundServer>>(
      stream: _stream,
      builder: (context, snapshot) {
        final found = snapshot.data ?? const <FoundServer>[];
        if (found.isEmpty) {
          // Silent while nothing has answered. An empty "looking…" box on a
          // network that blocks multicast is just noise above the field that
          // actually works.
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('On this network',
                style: AppType.label.copyWith(color: p.textSecondary)),
            const SizedBox(height: Space.xs),
            for (final s in found)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: Material(
                  color: p.surfaceSunken,
                  borderRadius: Radii.medium,
                  child: InkWell(
                    borderRadius: Radii.medium,
                    onTap: widget.busy ? null : () => widget.onPick(s),
                    child: Container(
                      padding: const EdgeInsets.all(Space.sm),
                      decoration: BoxDecoration(
                        borderRadius: Radii.medium,
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.dns_rounded, size: 18, color: p.brand),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: AppType.bodyStrong
                                        .copyWith(color: p.textPrimary)),
                                Text('${s.host}:${s.port}',
                                    style: AppType.small
                                        .copyWith(color: p.textTertiary)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 20, color: p.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
