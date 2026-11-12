import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() {
    return _instance;
  }

  ThemeService._internal();

  static const _darkModeKey = 'dark_mode_enabled';

  final ValueNotifier<bool> _isDarkModeNotifier = ValueNotifier(false);

  bool get isDarkMode => _isDarkModeNotifier.value;

  /// Loads the persisted preference. Call once, early (e.g. in the first
  /// screen's initState) — the notifier starts at `false` until this
  /// resolves, then flips to the saved value.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkModeNotifier.value = prefs.getBool(_darkModeKey) ?? false;
  }

  void toggleTheme() {
    setDarkMode(!isDarkMode);
  }

  void setDarkMode(bool value) {
    _isDarkModeNotifier.value = value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_darkModeKey, value),
    );
  }

  ValueNotifier<bool> get isDarkModeNotifier => _isDarkModeNotifier;
}
