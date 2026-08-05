import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeModeCubit extends Cubit<ThemeMode> {
  AppThemeModeCubit({AppThemeModeStorage? storage})
    : _storage = storage ?? const SharedPreferencesAppThemeModeStorage(),
      super(ThemeMode.system) {
    _loadSavedMode();
  }

  final AppThemeModeStorage _storage;
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

    await _storage.saveThemeMode(_modeToValue(mode));
  }

  Future<void> _loadSavedMode() async {
    final value = await _storage.loadThemeMode();
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

abstract class AppThemeModeStorage {
  Future<String?> loadThemeMode();

  Future<void> saveThemeMode(String value);
}

class SharedPreferencesAppThemeModeStorage implements AppThemeModeStorage {
  const SharedPreferencesAppThemeModeStorage();

  @override
  Future<String?> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(AppThemeModeCubit._preferenceKey);
  }

  @override
  Future<void> saveThemeMode(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(AppThemeModeCubit._preferenceKey, value);
  }
}
