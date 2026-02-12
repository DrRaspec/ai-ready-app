import 'package:ai_chat_bot/features/settings/presentation/controllers/settings_state.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static const String _textScaleKey = 'text_scale_factor';
  static const String _fontFamilyKey = 'font_family';
  static const String _bubbleColorKey = 'bubble_color';
  final Rx<SettingsState> rxState;

  SettingsState get state => rxState.value;

  void _setState(SettingsState newState) {
    rxState.value = newState;
  }

  SettingsController({SettingsState? initialState})
    : rxState = (initialState ?? SettingsState.initial()).obs {
    if (initialState == null) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
    final fontFamily = prefs.getString(_fontFamilyKey) ?? 'Inter';
    final bubbleColor = prefs.getInt(_bubbleColorKey);
    _setState(
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
    _setState(state.copyWith(textScaleFactor: scale));
  }

  Future<void> setFontFamily(String family) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, family);
    _setState(state.copyWith(fontFamily: family));
  }

  Future<void> setBubbleColor(int? colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    if (colorValue == null) {
      await prefs.remove(_bubbleColorKey);
      _setState(state.copyWith(clearBubbleColor: true));
    } else {
      await prefs.setInt(_bubbleColorKey, colorValue);
      _setState(state.copyWith(bubbleColor: colorValue));
    }
  }
}
