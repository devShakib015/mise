import 'server_host.dart';

/// Web and mobile: nothing to host here. These devices join a server that some
/// desktop machine in the restaurant is running.
const bool isSupported = false;
bool get isRunning => false;

Future<ServerStartResult> start({int port = 8090}) async =>
    const ServerStartResult.failed(
      'This device cannot run the server. Use the desktop app on the computer '
      'that will host it, then connect this device to that machine.',
    );

Future<void> stop() async {}
