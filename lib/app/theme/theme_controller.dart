import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier controlling dynamic Light, Dark, and System theme modes.
class ThemeController extends Notifier<ThemeMode> {
  static const String _keyTheme = 'mind_forensics_theme_mode';

  @override
  ThemeMode build() {
    _loadSavedTheme();
    return ThemeMode.light; // Default to soft Daylight Lab
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyTheme);
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else if (saved == 'light') {
      state = ThemeMode.light;
    } else if (saved == 'system') {
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(_keyTheme, 'dark');
    } else if (mode == ThemeMode.light) {
      await prefs.setString(_keyTheme, 'light');
    } else {
      await prefs.setString(_keyTheme, 'system');
    }
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

