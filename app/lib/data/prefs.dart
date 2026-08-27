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

  String? get serverUrl {
    final v = _p.getString(_kServerUrl);
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> setServerUrl(String url) => _p.setString(_kServerUrl, url);
  Future<void> clearServerUrl() => _p.remove(_kServerUrl);

  String? get authData => _p.getString(_kAuth);
  Future<void> setAuthData(String data) => _p.setString(_kAuth, data);
  Future<void> clearAuthData() => _p.remove(_kAuth);

  String? get themeMode => _p.getString(_kThemeMode);
  Future<void> setThemeMode(String mode) => _p.setString(_kThemeMode, mode);
}

/// Overridden in main() once SharedPreferences has loaded.
final prefsProvider = Provider<Prefs>(
  (ref) => throw UnimplementedError('prefsProvider must be overridden'),
);
