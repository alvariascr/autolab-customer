import 'dart:async';

import 'package:autolab_customer/core/theme/app_theme_mode_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppThemeModeCubit', () {
    test('persiste el modo claro seleccionado', () async {
      final storage = _FakeAppThemeModeStorage();
      final cubit = AppThemeModeCubit(storage: storage);

      await cubit.setThemeMode(ThemeMode.light);

      expect(storage.savedValue, 'light');

      await cubit.close();
    });

    test('carga el modo guardado al iniciar', () async {
      final storage = _FakeAppThemeModeStorage(initialValue: 'light');
      final cubit = AppThemeModeCubit(storage: storage);

      await storage.loadCompleted;

      expect(cubit.state, ThemeMode.light);

      await cubit.close();
    });

    test(
      'mantiene la seleccion reciente aunque exista otro modo guardado',
      () async {
        final storage = _FakeAppThemeModeStorage(
          initialValue: 'dark',
          waitForLoadRelease: true,
        );
        final cubit = AppThemeModeCubit(storage: storage);

        await cubit.setThemeMode(ThemeMode.light);
        storage.releaseLoad();
        await storage.loadCompleted;

        expect(cubit.state, ThemeMode.light);
        expect(storage.savedValue, 'light');

        await cubit.close();
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
  final _loadCompleted = Completer<void>();
  final _loadRelease = Completer<void>();
  String? savedValue;

  Future<void> get loadCompleted => _loadCompleted.future;

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

    scheduleMicrotask(() {
      if (!_loadCompleted.isCompleted) {
        _loadCompleted.complete();
      }
    });

    return initialValue;
  }

  @override
  Future<void> saveThemeMode(String value) async {
    savedValue = value;
  }
}
