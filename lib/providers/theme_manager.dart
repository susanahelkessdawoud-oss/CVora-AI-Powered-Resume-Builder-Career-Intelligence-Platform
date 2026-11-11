import 'package:flutter/material.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() {
    return _instance;
  }

  ThemeService._internal();

  final ValueNotifier<bool> _isDarkModeNotifier = ValueNotifier(false);

  bool get isDarkMode => _isDarkModeNotifier.value;

  void toggleTheme() {
    _isDarkModeNotifier.value = !_isDarkModeNotifier.value;
  }

  void setDarkMode(bool value) {
    _isDarkModeNotifier.value = value;
  }

  ValueNotifier<bool> get isDarkModeNotifier => _isDarkModeNotifier;
}
