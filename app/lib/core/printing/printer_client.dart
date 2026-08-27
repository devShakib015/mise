import 'printer_client_stub.dart'
    if (dart.library.io) 'printer_client_io.dart' as impl;

class PrintResult {
  const PrintResult.ok()
      : success = true,
        message = '';
  const PrintResult.failed(this.message) : success = false;

  final bool success;
  final String message;
}

/// Sends raw ESC/POS bytes to a network thermal printer.
///
/// Virtually every restaurant printer listens on TCP 9100 and takes a raw byte
/// stream, which is why this needs no driver and no vendor SDK.
///
/// Raw sockets do not exist in a browser, so the web build cannot print. The
/// till runs on desktop or a tablet in practice; web is for the back office.
abstract final class PrinterClient {
  static bool get isSupported => impl.isSupported;

  static Future<PrintResult> send({
    required String host,
    required int port,
    required List<int> bytes,
    Duration timeout = const Duration(seconds: 6),
  }) =>
      impl.send(host: host, port: port, bytes: bytes, timeout: timeout);
}
