import 'package:autolab_customer/core/theme/app_theme_mode_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppThemeModeCubit', () {
    test('persiste el modo claro seleccionado', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = AppThemeModeCubit();

      await cubit.setThemeMode(ThemeMode.light);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('app_theme_mode'), 'light');

      await cubit.close();
    });

    test('carga el modo guardado al iniciar', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
      final cubit = AppThemeModeCubit();

      await expectLater(cubit.stream, emits(ThemeMode.light));

      await cubit.close();
    });
  });
}
