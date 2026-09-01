import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything this device remembers between launches: which server it belongs
/// to, and who was last signed in on it.
class Prefs {
  const Prefs(this._p);

  final SharedPreferences _p;

  static const _kServerUrl = 'server_url';
  static const _kAuth = 'pb_auth';
  static const _kThemeMode = 'theme_mode';
  static const _kHosting = 'hosting';
  static const _kPending = 'pending_writes';
  static const _kSection = 'manager_section';

  String? get serverUrl {
    final v = _p.getString(_kServerUrl);
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> setServerUrl(String url) => _p.setString(_kServerUrl, url);
  Future<void> clearServerUrl() => _p.remove(_kServerUrl);

  String? get authData => _p.getString(_kAuth);
  Future<void> setAuthData(String data) => _p.setString(_kAuth, data);
  Future<void> clearAuthData() => _p.remove(_kAuth);

  /// True when this machine runs the server itself, so it can bring it back
  /// up after a restart without anyone pressing anything.
  bool get isHosting => _p.getBool(_kHosting) ?? false;
  Future<void> setHosting(bool value) => _p.setBool(_kHosting, value);

  /// Writes that have not reached the server yet, as JSON. Kept on the device
  /// so a tablet that is closed mid-outage does not lose a table's order.
  String? get pendingWrites => _p.getString(_kPending);
  Future<void> setPendingWrites(String json) => _p.setString(_kPending, json);

  /// Where the manager was last looking. Reopening the back office should
  /// return you to what you were doing, not to the top of the list.
  String? get managerSection => _p.getString(_kSection);
  Future<void> setManagerSection(String name) => _p.setString(_kSection, name);

  String? get themeMode => _p.getString(_kThemeMode);
  Future<void> setThemeMode(String mode) => _p.setString(_kThemeMode, mode);
}

/// Overridden in main() once SharedPreferences has loaded.
final prefsProvider = Provider<Prefs>(
  (ref) => throw UnimplementedError('prefsProvider must be overridden'),
);
