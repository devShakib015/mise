import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../core/server/server_host.dart';
import 'models/restaurant.dart';
import 'models/staff.dart';
import 'prefs.dart';
import 'server_status.dart';

/// Where this device is in the journey from "freshly installed" to "taking
/// orders". Every screen the app can show maps to one of these.
sealed class SessionState {
  const SessionState();
}

/// Checking a remembered server. Shown for a blink, or longer on a slow LAN.
class SessionBooting extends SessionState {
  const SessionBooting();
}

/// No server remembered, or the remembered one did not answer.
class SessionNeedsServer extends SessionState {
  const SessionNeedsServer({this.error, this.lastUrl});
  final String? error;
  final String? lastUrl;
}

/// Server reachable but nobody has set the restaurant up yet.
class SessionNeedsSetup extends SessionState {
  const SessionNeedsSetup(this.serverUrl);
  final String serverUrl;
}

/// Set up and waiting for a staff member to sign in.
class SessionNeedsAuth extends SessionState {
  const SessionNeedsAuth({required this.serverUrl, required this.venueName});
  final String serverUrl;
  final String venueName;
}

/// Signed in and ready to work.
class SessionReady extends SessionState {
  const SessionReady({required this.staff, required this.restaurant});
  final Staff staff;
  final Restaurant restaurant;
}

class SessionController extends Notifier<SessionState> {
  PocketBase? _pb;

  /// Only valid once the session has reached [SessionNeedsAuth] or beyond.
  PocketBase get pb => _pb!;

  @override
  SessionState build() {
    scheduleMicrotask(_boot);
    return const SessionBooting();
  }

  Prefs get _prefs => ref.read(prefsProvider);

  // ------------------------------------------------------------------ startup

  Future<void> _boot() async {
    // A host machine that was restarted mid-service should come back on its
    // own. Nobody is going to press a button in the office at 7pm.
    if (_prefs.isHosting && ServerHost.isSupported) {
      final result = await ServerHost.start();
      if (result.ok) {
        _hosted = result.server;
        await _attach(result.server!.url, remember: true);
        return;
      }
      state = SessionNeedsServer(error: result.error, lastUrl: _prefs.serverUrl);
      return;
    }

    final saved = _prefs.serverUrl;
    if (saved == null) {
      state = const SessionNeedsServer();
      return;
    }
    await _attach(saved, remember: false);
  }

  /// Points this device at [rawUrl] and works out what it should show next.
  /// Returns null on success, or a message to put in front of the user.
  Future<String?> connect(String rawUrl) async {
    final url = normalizeServerUrl(rawUrl);
    if (url == null) {
      return 'That does not look like a server address.';
    }

    state = const SessionBooting();
    final error = await _attach(url, remember: true);
    return error;
  }

  Future<String?> _attach(String url, {required bool remember}) async {
    final pb = PocketBase(
      url,
      authStore: AsyncAuthStore(
        save: (data) async => _prefs.setAuthData(data),
        initial: _prefs.authData,
      ),
    );

    final ServerStatus status;
    try {
      final json = await pb
          .send<Map<String, dynamic>>('/api/app/status')
          .timeout(const Duration(seconds: 8));
      status = ServerStatus.fromJson(json);
    } catch (err) {
      final message = describeError(err, fallback: 'Could not reach $url');
      state = SessionNeedsServer(error: message, lastUrl: url);
      return message;
    }

    _pb = pb;
    if (remember) await _prefs.setServerUrl(url);

    if (!status.configured) {
      state = SessionNeedsSetup(url);
      return null;
    }

    // A remembered sign-in survives a restart, so a terminal comes back up
    // mid-service without anyone having to key a PIN in again.
    if (pb.authStore.isValid && pb.authStore.record != null) {
      try {
        await pb.collection('staff').authRefresh();
        await _loadReady(pb);
        return null;
      } catch (_) {
        pb.authStore.clear();
      }
    }

    state = SessionNeedsAuth(serverUrl: url, venueName: status.name);
    return null;
  }

  /// Starts the bundled server on this machine and connects to it.
  ///
  /// This is the path for the computer that will host: one download, one
  /// button, no terminal.
  Future<String?> hostHere() async {
    state = const SessionBooting();

    final result = await ServerHost.start();
    if (!result.ok) {
      state = SessionNeedsServer(error: result.error);
      return result.error;
    }

    _hosted = result.server;
    await _prefs.setHosting(true);
    return _attach(result.server!.url, remember: true);
  }

  /// Set once this device is hosting, so the setup screens can read out the
  /// address that tablets should join.
  LocalServer? _hosted;
  LocalServer? get hostedServer => _hosted;

  // ------------------------------------------------------------------- set up

  /// Creates the venue and its first owner, then signs that owner in.
  Future<String?> runSetup({
    required String restaurantName,
    required String ownerName,
    required String ownerUsername,
    required String ownerPin,
    String address = '',
    String phone = '',
    String currencyCode = 'USD',
    String currencySymbol = '\$',
    double taxRate = 0,
    bool taxInclusive = false,
    double serviceChargeRate = 0,
  }) async {
    final pb = _pb;
    if (pb == null) return 'Not connected to a server.';

    try {
      await pb.send<Map<String, dynamic>>(
        '/api/app/bootstrap',
        method: 'POST',
        body: {
          'restaurant_name': restaurantName.trim(),
          'owner_name': ownerName.trim(),
          'owner_username': ownerUsername.trim().toLowerCase(),
          'owner_pin': ownerPin,
          'address': address.trim(),
          'phone': phone.trim(),
          'currency_code': currencyCode,
          'currency_symbol': currencySymbol,
          'tax_rate': taxRate,
          'tax_inclusive': taxInclusive,
          'service_charge_rate': serviceChargeRate,
        },
      );
    } catch (err) {
      return describeError(err, fallback: 'Setup could not be completed.');
    }

    return signIn(ownerUsername.trim().toLowerCase(), ownerPin);
  }

  // ------------------------------------------------------------------- log in

  Future<String?> signIn(String username, String pin) async {
    final pb = _pb;
    if (pb == null) return 'Not connected to a server.';

    try {
      await pb
          .collection('staff')
          .authWithPassword(username.trim().toLowerCase(), pin);
    } catch (err) {
      return describeError(
        err,
        fallback: 'That username and PIN did not match.',
        on400: 'That username and PIN did not match.',
      );
    }

    await _loadReady(pb);
    return null;
  }

  Future<void> _loadReady(PocketBase pb) async {
    final record = pb.authStore.record;
    if (record == null) {
      state = SessionNeedsAuth(
        serverUrl: pb.baseURL,
        venueName: '',
      );
      return;
    }

    final staff = Staff.fromRecord(record);

    Restaurant? restaurant;
    try {
      final rec = await pb.collection('restaurant').getFirstListItem("id != ''");
      restaurant = Restaurant.fromRecord(rec);
    } catch (err) {
      // Signed in but the venue row vanished — treat it as unconfigured rather
      // than dropping the user into a shell with no currency or tax rules.
      state = SessionNeedsSetup(pb.baseURL);
      return;
    }

    state = SessionReady(staff: staff, restaurant: restaurant);
  }

  /// Writes venue settings and refreshes the session copy so every screen sees
  /// the new currency, tax rate and name immediately.
  Future<String?> updateRestaurant(Map<String, dynamic> body) async {
    final pb = _pb;
    final current = state;
    if (pb == null || current is! SessionReady) {
      return 'Not signed in.';
    }

    try {
      final record = await pb
          .collection('restaurant')
          .update(current.restaurant.id, body: body);
      state = SessionReady(
        staff: current.staff,
        restaurant: Restaurant.fromRecord(record),
      );
      return null;
    } catch (err) {
      return describeError(err, fallback: 'Could not save those settings.');
    }
  }

  Future<void> signOut() async {
    final pb = _pb;
    pb?.authStore.clear();
    await _prefs.clearAuthData();

    if (pb == null) {
      state = const SessionNeedsServer();
      return;
    }
    state = SessionNeedsAuth(serverUrl: pb.baseURL, venueName: '');
  }

  /// Detaches this device from its server entirely.
  Future<void> forgetServer() async {
    _pb?.authStore.clear();
    await _prefs.clearAuthData();
    await _prefs.clearServerUrl();
    await _prefs.setHosting(false);
    await ServerHost.stop();
    _pb = null;
    _hosted = null;
    state = const SessionNeedsServer();
  }
}

final sessionProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Convenience for screens that only run inside a signed-in shell.
final currentStaffProvider = Provider<Staff?>((ref) {
  final s = ref.watch(sessionProvider);
  return s is SessionReady ? s.staff : null;
});

final currentRestaurantProvider = Provider<Restaurant?>((ref) {
  final s = ref.watch(sessionProvider);
  return s is SessionReady ? s.restaurant : null;
});

// ---------------------------------------------------------------------- utils

/// Accepts what a person would actually type — `192.168.1.40`, `localhost:8090`,
/// `http://pos.local:8090/` — and returns a URL the client can use.
String? normalizeServerUrl(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;

  if (!s.startsWith('http://') && !s.startsWith('https://')) {
    s = 'http://$s';
  }
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }

  final uri = Uri.tryParse(s);
  if (uri == null || uri.host.isEmpty) return null;

  // A bare host means the default PocketBase port, which is what our installer
  // sets up and what most people will be running.
  if (!uri.hasPort) {
    return Uri(scheme: uri.scheme, host: uri.host, port: 8090).toString();
  }
  return s;
}

/// Turns a PocketBase or socket failure into something worth showing a user.
String describeError(Object err, {required String fallback, String? on400}) {
  if (err is TimeoutException) {
    return 'The server did not respond in time.';
  }
  if (err is ClientException) {
    if (err.statusCode == 0) return fallback;
    if (err.statusCode == 400 && on400 != null) return on400;

    final message = err.response['message'];
    if (message is String && message.isNotEmpty) return message;
    return fallback;
  }
  return fallback;
}
