import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gère le mode de thème de l'app (clair / sombre / système).
/// La préférence est persistée via flutter_secure_storage.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'katian_theme_mode';
  static const _storage = FlutterSecureStorage();

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Charge la préférence sauvegardée. À appeler au démarrage.
  Future<void> load() async {
    try {
      final stored = await _storage.read(key: _key);
      _mode = _parse(stored);
      notifyListeners();
    } catch (_) {
      _mode = ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (_) {}
  }

  ThemeMode _parse(String? v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
