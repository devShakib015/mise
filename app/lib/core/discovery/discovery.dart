import 'discovery_stub.dart'
    if (dart.library.io) 'discovery_io.dart' as impl;

/// A Mise server found on the local network.
class FoundServer {
  const FoundServer({
    required this.name,
    required this.host,
    required this.port,
  });

  /// The venue's name, so a waiter picks "The Ember" rather than an IP.
  final String name;
  final String host;
  final int port;

  String get url => 'http://$host:$port';

  @override
  bool operator ==(Object other) =>
      other is FoundServer && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);
}

/// Finding the restaurant without anyone typing an address.
///
/// The host announces itself and the tablets listen. Typing an address is
/// still there underneath — mDNS is blocked on plenty of networks, and a setup
/// that only works when the network cooperates is not a setup.
abstract final class Discovery {
  static bool get isSupported => impl.isSupported;

  /// Announces this machine as the restaurant's server.
  static Future<void> advertise({
    required String venueName,
    required int port,
  }) =>
      impl.advertise(venueName: venueName, port: port);

  static Future<void> stopAdvertising() => impl.stopAdvertising();

  /// Servers seen on this network, added as they answer.
  static Stream<List<FoundServer>> search() => impl.search();

  static Future<void> stopSearching() => impl.stopSearching();
}
