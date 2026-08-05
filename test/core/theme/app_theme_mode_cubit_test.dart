import 'dart:async';

import 'package:autolab_customer/core/theme/app_theme_mode_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppThemeModeCubit', () {
    late _FakeAppThemeModeStorage storage;

    blocTest<AppThemeModeCubit, ThemeMode>(
      'persiste el modo claro seleccionado',
      build: () {
        storage = _FakeAppThemeModeStorage();
        return AppThemeModeCubit(storage: storage);
      },
      act: (cubit) => cubit.setThemeMode(ThemeMode.light),
      expect: () => [ThemeMode.light],
      verify: (_) {
        expect(storage.savedValue, 'light');
      },
    );

    blocTest<AppThemeModeCubit, ThemeMode>(
      'carga el modo guardado al iniciar',
      build: () {
        storage = _FakeAppThemeModeStorage(
          initialValue: 'light',
          waitForLoadRelease: true,
        );
        return AppThemeModeCubit(storage: storage);
      },
      act: (_) => storage.releaseLoad(),
      expect: () => [ThemeMode.light],
    );

    blocTest<AppThemeModeCubit, ThemeMode>(
      'mantiene la seleccion reciente aunque exista otro modo guardado',
      build: () {
        storage = _FakeAppThemeModeStorage(
          initialValue: 'dark',
          waitForLoadRelease: true,
        );
        return AppThemeModeCubit(storage: storage);
      },
      act: (cubit) async {
        await cubit.setThemeMode(ThemeMode.light);
        storage.releaseLoad();
      },
      expect: () => [ThemeMode.light],
      verify: (cubit) {
        expect(cubit.state, ThemeMode.light);
        expect(storage.savedValue, 'light');
      },
    );

    test('adapter guarda el modo en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      const storage = SharedPreferencesAppThemeModeStorage();

      await storage.saveThemeMode('light');

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('app_theme_mode'), 'light');
      expect(await storage.loadThemeMode(), 'light');
    });
  });
}

class _FakeAppThemeModeStorage implements AppThemeModeStorage {
  _FakeAppThemeModeStorage({
    this.initialValue,
    this.waitForLoadRelease = false,
  });

  final String? initialValue;
  final bool waitForLoadRelease;
  final _loadRelease = Completer<void>();
  String? savedValue;

  void releaseLoad() {
    if (!_loadRelease.isCompleted) {
      _loadRelease.complete();
    }
  }

  @override
  Future<String?> loadThemeMode() async {
    if (waitForLoadRelease) {
      await _loadRelease.future;
    }

    return initialValue;
  }

  @override
  Future<void> saveThemeMode(String value) async {
    savedValue = value;
  }
}
