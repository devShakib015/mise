import 'discovery.dart';

/// Web: a browser cannot send or listen for multicast, so the address gets
/// typed. Saying so is better than a button that quietly finds nothing.
const bool isSupported = false;

Future<void> advertise({required String venueName, required int port}) async {}
Future<void> stopAdvertising() async {}
Stream<List<FoundServer>> search() => const Stream.empty();
Future<void> stopSearching() async {}
