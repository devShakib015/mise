import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'server_host.dart';

/// Only a desktop machine hosts. A phone or tablet joins one.
bool get isSupported =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

Process? _process;
bool get isRunning => _process != null;

Future<ServerStartResult> start({int port = 8090}) async {
  if (!isSupported) {
    return const ServerStartResult.failed(
      'Only the desktop app can run the server.',
    );
  }

  // Something may already be listening — a server started by hand, or a second
  // window of this app. Joining it beats fighting it for the port.
  final existing = await _probe(port);
  if (existing) {
    return ServerStartResult.started(
      LocalServer(url: 'http://127.0.0.1:$port', lanUrl: await _lanUrl(port)),
    );
  }

  final Directory home;
  try {
    home = Directory('${(await getApplicationSupportDirectory()).path}/server');
  } catch (err) {
    return ServerStartResult.failed('Could not find a place to keep the data: $err');
  }

  final String executable;
  try {
    executable = await _stage(home);
  } catch (err) {
    return ServerStartResult.failed('Could not unpack the server: $err');
  }

  try {
    _process = await Process.start(
      executable,
      [
        'serve',
        '--dir=${home.path}/pb_data',
        '--migrationsDir=${home.path}/pb_migrations',
        '--hooksDir=${home.path}/pb_hooks',
        // 0.0.0.0, not 127.0.0.1: the waiters' tablets and the kitchen screen
        // have to be able to reach this machine.
        '--http=0.0.0.0:$port',
      ],
      workingDirectory: home.path,
    );
  } catch (err) {
    return ServerStartResult.failed('Could not start the server: $err');
  }

  // Keep the last few lines; if startup fails they are the only explanation
  // anyone will get.
  final complaints = <String>[];
  void collect(String line) {
    complaints.add(line.trim());
    if (complaints.length > 6) complaints.removeAt(0);
  }

  _process!.stdout.transform(const SystemEncoding().decoder).listen(collect);
  _process!.stderr.transform(const SystemEncoding().decoder).listen(collect);

  unawaited(_process!.exitCode.then((_) => _process = null));

  // Migrations run on first boot, so allow a slow start before giving up.
  for (var i = 0; i < 60; i++) {
    if (_process == null) {
      final why = complaints.where((l) => l.isNotEmpty).join(' ');
      return ServerStartResult.failed(
        why.isEmpty ? 'The server stopped straight away.' : 'The server stopped: $why',
      );
    }
    if (await _probe(port)) {
      return ServerStartResult.started(
        LocalServer(url: 'http://127.0.0.1:$port', lanUrl: await _lanUrl(port)),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  await stop();
  return const ServerStartResult.failed('The server did not come up in time.');
}

Future<void> stop() async {
  final process = _process;
  _process = null;
  if (process == null) return;

  process.kill(ProcessSignal.sigterm);
  try {
    await process.exitCode.timeout(const Duration(seconds: 5));
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
  }
}

/// Copies the bundled server out of the app and onto disk, once.
///
/// Re-staged whenever the pinned version changes, so an app update brings its
/// schema and hooks with it. `pb_data` is never touched — that is the
/// restaurant's own data.
Future<String> _stage(Directory home) async {
  final manifest = await rootBundle.loadString('assets/server/manifest.txt');

  var binaryName = 'pocketbase';
  var version = '0';
  final migrations = <String>[];
  final hooks = <String>[];

  for (final line in manifest.split('\n')) {
    final i = line.indexOf('=');
    if (i < 1) continue;
    final key = line.substring(0, i).trim();
    final value = line.substring(i + 1).trim();
    switch (key) {
      case 'binary':
        binaryName = value;
      case 'version':
        version = value;
      case 'migration':
        migrations.add(value);
      case 'hook':
        hooks.add(value);
    }
  }

  await home.create(recursive: true);
  final stamp = File('${home.path}/.staged');
  final executable = File('${home.path}/$binaryName');

  final alreadyStaged = await executable.exists() &&
      await stamp.exists() &&
      (await stamp.readAsString()).trim() == version;

  if (!alreadyStaged) {
    Future<void> write(String asset, File target) async {
      final data = await rootBundle.load(asset);
      await target.parent.create(recursive: true);
      await target.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }

    await write('assets/server/$binaryName', executable);
    for (final m in migrations) {
      await write('assets/server/pb_migrations/$m',
          File('${home.path}/pb_migrations/$m'));
    }
    for (final h in hooks) {
      await write('assets/server/pb_hooks/$h', File('${home.path}/pb_hooks/$h'));
    }

    // Flutter's asset bundle carries no file mode, so the binary lands without
    // its executable bit and has to be given one.
    if (!Platform.isWindows) {
      final chmod = await Process.run('chmod', ['755', executable.path]);
      if (chmod.exitCode != 0) {
        throw Exception('could not make the server executable: ${chmod.stderr}');
      }
    }

    if (Platform.isMacOS) {
      // macOS quarantines everything a sandboxed app writes, and a quarantined
      // binary is refused execution outright — the chmod above is not enough on
      // its own. Clearing the attribute on a file we just unpacked from our own
      // signed bundle is safe: nothing untrusted has been near it.
      await Process.run('xattr', ['-d', 'com.apple.quarantine', executable.path]);
    }

    await stamp.writeAsString(version);
  }

  return executable.path;
}

Future<bool> _probe(int port) async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    final request = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/health'));
    final response = await request.close().timeout(const Duration(seconds: 3));
    await response.drain<void>();
    client.close();
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

/// The address to read out when setting up a tablet.
Future<String> _lanUrl(int port) async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    for (final i in interfaces) {
      for (final addr in i.addresses) {
        // Private ranges only; a public address here would be a misconfigured
        // machine, not something to print on a setup screen.
        final ip = addr.address;
        if (ip.startsWith('192.168.') ||
            ip.startsWith('10.') ||
            RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip)) {
          return 'http://$ip:$port';
        }
      }
    }
  } catch (_) {
    // Fall through.
  }
  return 'http://127.0.0.1:$port';
}
