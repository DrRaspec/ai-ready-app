import 'package:ai_chat_bot/features/settings/presentation/bloc/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const String _textScaleKey = 'text_scale_factor';
  static const String _fontFamilyKey = 'font_family';
  static const String _bubbleColorKey = 'bubble_color';

  SettingsCubit({SettingsState? initialState})
    : super(initialState ?? SettingsState.initial()) {
    if (initialState == null) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
    final fontFamily = prefs.getString(_fontFamilyKey) ?? 'Inter';
    final bubbleColor = prefs.getInt(_bubbleColorKey);
    emit(
      SettingsState(
        textScaleFactor: textScale,
        fontFamily: fontFamily,
        bubbleColor: bubbleColor,
      ),
    );
  }

  Future<void> setTextScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, scale);
    emit(state.copyWith(textScaleFactor: scale));
  }

  Future<void> setFontFamily(String family) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, family);
    emit(state.copyWith(fontFamily: family));
  }

  Future<void> setBubbleColor(int? colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    if (colorValue == null) {
      await prefs.remove(_bubbleColorKey);
      emit(state.copyWith(clearBubbleColor: true));
    } else {
      await prefs.setInt(_bubbleColorKey, colorValue);
      emit(state.copyWith(bubbleColor: colorValue));
    }
  }
}
