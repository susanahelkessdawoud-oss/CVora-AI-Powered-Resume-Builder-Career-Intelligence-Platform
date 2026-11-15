import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() {
    return _instance;
  }

  ThemeService._internal();

  static const _darkModeKey = 'dark_mode_enabled';

  // Dark-first brand: the app opens in dark mode unless the user has
  // explicitly switched to light.
  final ValueNotifier<bool> _isDarkModeNotifier = ValueNotifier(true);

  bool get isDarkMode => _isDarkModeNotifier.value;

  /// Loads the persisted preference. Call once, early (e.g. in the first
  /// screen's initState) — the notifier starts at `true` until this
  /// resolves, then flips to the saved value if the user picked one.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkModeNotifier.value = prefs.getBool(_darkModeKey) ?? true;
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
