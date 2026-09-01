import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

import 'discovery.dart';

/// The service type restaurants announce themselves under.
const _type = '_mise._tcp';

/// Linux desktop has no Bonsoir backend on this version, and a browser cannot
/// do multicast at all. Both fall back to typing the address.
bool get isSupported =>
    Platform.isMacOS || Platform.isWindows || Platform.isIOS || Platform.isAndroid;

BonsoirBroadcast? _broadcast;
BonsoirDiscovery? _discovery;

Future<void> advertise({required String venueName, required int port}) async {
  if (!isSupported) return;
  await stopAdvertising();

  try {
    final service = BonsoirService(
      name: venueName.isEmpty ? 'Mise' : venueName,
      type: _type,
      port: port,
      // The venue name travels in the record so a tablet can show "The Ember"
      // rather than an address nobody recognises.
      attributes: {'venue': venueName},
    );
    final broadcast = BonsoirBroadcast(service: service);
    await broadcast.initialize();
    await broadcast.start();
    _broadcast = broadcast;
  } catch (_) {
    // Announcing is a convenience. A network that blocks multicast must not
    // stop the server from running.
    _broadcast = null;
  }
}

Future<void> stopAdvertising() async {
  final b = _broadcast;
  _broadcast = null;
  try {
    await b?.stop();
  } catch (_) {/* already gone */}
}

Stream<List<FoundServer>> search() {
  if (!isSupported) return const Stream.empty();

  late final StreamController<List<FoundServer>> controller;
  final found = <FoundServer>[];
  StreamSubscription<BonsoirDiscoveryEvent>? sub;

  Future<void> begin() async {
    try {
      final discovery = BonsoirDiscovery(type: _type);
      await discovery.initialize();
      _discovery = discovery;

      sub = discovery.eventStream?.listen((event) {
        // Only resolved services carry an address worth connecting to; a
        // "found" event is just a name so far.
        if (event is BonsoirDiscoveryServiceResolvedEvent) {
          final s = event.service;
          final host = s.hostAddresses.isNotEmpty
              ? s.hostAddresses.first
              : (s.hostname ?? '');
          if (host.isEmpty) return;

          final server = FoundServer(
            name: s.attributes['venue']?.isNotEmpty == true
                ? s.attributes['venue']!
                : s.name,
            host: host,
            port: s.port,
          );
          if (!found.contains(server)) {
            found.add(server);
            controller.add(List.unmodifiable(found));
          }
        } else if (event is BonsoirDiscoveryServiceLostEvent) {
          found.removeWhere((f) => f.port == event.service.port &&
              event.service.hostAddresses.contains(f.host));
          controller.add(List.unmodifiable(found));
        }
      });

      await discovery.start();
    } catch (_) {
      // Nothing found is a perfectly ordinary outcome; the address can be
      // typed. Surfacing a plugin error here would only confuse.
      controller.add(const []);
    }
  }

  controller = StreamController<List<FoundServer>>(
    onListen: begin,
    onCancel: () async {
      await sub?.cancel();
      await stopSearching();
    },
  );

  return controller.stream;
}

Future<void> stopSearching() async {
  final d = _discovery;
  _discovery = null;
  try {
    await d?.stop();
  } catch (_) {/* already gone */}
}
