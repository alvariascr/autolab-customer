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

      await expectLater(cubit.stream, emits(ThemeMode.light));

      await cubit.close();
    });

    test(
      'mantiene la seleccion reciente aunque exista otro modo guardado',
      () async {
        final storage = _FakeAppThemeModeStorage(
          initialValue: 'dark',
          loadDelay: Duration.zero,
        );
        final cubit = AppThemeModeCubit(storage: storage);

        await cubit.setThemeMode(ThemeMode.light);
        await Future<void>.delayed(Duration.zero);

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
  _FakeAppThemeModeStorage({this.initialValue, this.loadDelay});

  final String? initialValue;
  final Duration? loadDelay;
  String? savedValue;

  @override
  Future<String?> loadThemeMode() async {
    final delay = loadDelay;
    if (delay != null) {
      await Future<void>.delayed(delay);
    }

    return savedValue ?? initialValue;
  }

  @override
  Future<void> saveThemeMode(String value) async {
    savedValue = value;
  }
}
