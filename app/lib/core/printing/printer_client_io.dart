import 'dart:io';

import 'printer_client.dart';

const bool isSupported = true;

Future<PrintResult> send({
  required String host,
  required int port,
  required List<int> bytes,
  required Duration timeout,
}) async {
  Socket? socket;
  try {
    socket = await Socket.connect(host, port, timeout: timeout);
    socket.add(bytes);
    await socket.flush().timeout(timeout);
    return const PrintResult.ok();
  } on SocketException catch (e) {
    // The address and port are the two things worth putting in front of
    // whoever has to go and look at the printer.
    return PrintResult.failed('Could not reach $host:$port — ${e.osError?.message ?? e.message}');
  } catch (e) {
    return PrintResult.failed('Printing failed: $e');
  } finally {
    try {
      await socket?.close();
    } catch (_) {
      // Already gone.
    }
  }
}
