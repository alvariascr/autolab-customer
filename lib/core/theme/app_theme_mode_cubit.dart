import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppThemeModeCubit extends Cubit<ThemeMode> {
  AppThemeModeCubit() : super(ThemeMode.system);

  void toggle() {
    emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setDarkMode(bool isDark) {
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
