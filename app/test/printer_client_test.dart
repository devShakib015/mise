@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mise/core/printing/printer_client.dart';

/// Stands in for a thermal printer: listens on 9100-style raw TCP and keeps
/// whatever bytes arrive.
class FakePrinter {
  FakePrinter._(this._server);

  final ServerSocket _server;
  final List<int> received = [];

  int get port => _server.port;

  static Future<FakePrinter> start() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final printer = FakePrinter._(server);
    server.listen((socket) {
      socket.listen(
        printer.received.addAll,
        onDone: socket.close,
        onError: (_) => socket.close(),
      );
    });
    return printer;
  }

  Future<void> stop() => _server.close();
}

void main() {
  test('is supported off the web', () {
    expect(PrinterClient.isSupported, isTrue);
  });

  test('delivers the exact bytes to a listening printer', () async {
    final printer = await FakePrinter.start();
    addTearDown(printer.stop);

    final payload = [0x1B, 0x40, ...'Hello, pass\n'.codeUnits, 0x1D, 0x56, 0x42, 0x00];

    final result = await PrinterClient.send(
      host: '127.0.0.1',
      port: printer.port,
      bytes: payload,
    );

    expect(result.success, isTrue, reason: result.message);

    // Give the socket a moment to drain before asserting.
    for (var i = 0; i < 40 && printer.received.length < payload.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    expect(printer.received, payload);
  });

  test('reports a printer that is switched off, rather than throwing', () async {
    // Bind and immediately release, so the port is almost certainly dead.
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final deadPort = probe.port;
    await probe.close();

    final result = await PrinterClient.send(
      host: '127.0.0.1',
      port: deadPort,
      bytes: const [0x1B, 0x40],
      timeout: const Duration(seconds: 2),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('127.0.0.1:$deadPort'));
  });
}
