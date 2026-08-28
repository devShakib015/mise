import 'server_host_stub.dart'
    if (dart.library.io) 'server_host_io.dart' as impl;

/// A server this device is running for itself.
class LocalServer {
  const LocalServer({required this.url, required this.lanUrl});

  /// What this device should connect to.
  final String url;

  /// What to read out to whoever is setting up a tablet. Falls back to [url]
  /// when the machine has no usable LAN address.
  final String lanUrl;
}

class ServerStartResult {
  const ServerStartResult.started(this.server) : error = null;
  const ServerStartResult.failed(this.error) : server = null;

  final LocalServer? server;
  final String? error;

  bool get ok => server != null;
}

/// Runs the bundled PocketBase so a restaurant needs one download and no
/// terminal.
///
/// Desktop only: a phone or tablet cannot host, and a browser cannot spawn a
/// process. Those devices connect to whichever machine is hosting.
abstract final class ServerHost {
  static bool get isSupported => impl.isSupported;
  static bool get isRunning => impl.isRunning;

  static Future<ServerStartResult> start({int port = 8090}) =>
      impl.start(port: port);

  static Future<void> stop() => impl.stop();
}
