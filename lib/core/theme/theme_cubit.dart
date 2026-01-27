import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeModeKey = 'theme_mode';

  ThemeCubit({ThemeMode? initialTheme})
    : super(ThemeState(initialTheme ?? ThemeMode.system)) {
    if (initialTheme == null) {
      _loadTheme();
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeModeKey);
    if (savedMode != null) {
      final mode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedMode,
        orElse: () => ThemeMode.system,
      );
      emit(ThemeState(mode));
    }
  }

  Future<void> light() async {
    await _saveTheme(ThemeMode.light);
    emit(const ThemeState(ThemeMode.light));
  }

  Future<void> dark() async {
    await _saveTheme(ThemeMode.dark);
    emit(const ThemeState(ThemeMode.dark));
  }

  Future<void> system() async {
    await _saveTheme(ThemeMode.system);
    emit(const ThemeState(ThemeMode.system));
  }

  Future<void> toggleTheme() async {
    if (state.mode == ThemeMode.light) {
      await dark();
    } else {
      await light();
    }
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.toString());
  }
}
