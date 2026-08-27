import 'printer_client.dart';

/// Web build: browsers cannot open raw TCP sockets, so there is nothing to do
/// but say so plainly rather than failing in a way that looks like a fault.
const bool isSupported = false;

Future<PrintResult> send({
  required String host,
  required int port,
  required List<int> bytes,
  required Duration timeout,
}) async =>
    const PrintResult.failed(
      'Printing needs the desktop or tablet app — a browser cannot reach a '
      'thermal printer directly. You can still save the receipt as a file.',
    );
