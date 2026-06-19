import 'package:flutter/material.dart';

class AppThemeModeController {
  const AppThemeModeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.dark);

  static void toggle() {
    mode.value = mode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  static void setDarkMode(bool isDark) {
    mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
