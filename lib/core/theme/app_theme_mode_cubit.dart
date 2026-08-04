import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeModeCubit extends Cubit<ThemeMode> {
  AppThemeModeCubit() : super(ThemeMode.system) {
    _loadSavedMode();
  }

  var _hasExplicitSelection = false;

  static const _preferenceKey = 'app_theme_mode';
  static const _darkValue = 'dark';
  static const _lightValue = 'light';
  static const _systemValue = 'system';

  void toggle() {
    setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setDarkMode(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _hasExplicitSelection = true;
    emit(mode);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, _modeToValue(mode));
  }

  Future<void> _loadSavedMode() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_preferenceKey);
    final mode = _modeFromValue(value);

    if (!isClosed && !_hasExplicitSelection && mode != state) {
      emit(mode);
    }
  }

  static ThemeMode _modeFromValue(String? value) {
    return switch (value) {
      _darkValue => ThemeMode.dark,
      _lightValue => ThemeMode.light,
      _systemValue => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  static String _modeToValue(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => _darkValue,
      ThemeMode.light => _lightValue,
      ThemeMode.system => _systemValue,
    };
  }
}
