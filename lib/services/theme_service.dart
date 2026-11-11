import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ORIGINAL FEATURE: persistent dark / light / system theme.
///
/// A [ValueNotifier] so the root MaterialApp can rebuild on change with a
/// [ValueListenableBuilder] — no extra state-management package needed.
/// The chosen mode is persisted with SharedPreferences and reloaded on
/// startup, so it survives app restarts.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);
  static final ThemeController instance = ThemeController._();

  static const _key = 'theme_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = _fromName(prefs.getString(_key));
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  ThemeMode _fromName(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
