import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(ThemeMode.system));

  void light() => emit(const ThemeState(ThemeMode.light));
  void dark() => emit(const ThemeState(ThemeMode.dark));
  void system() => emit(const ThemeState(ThemeMode.system));
}
