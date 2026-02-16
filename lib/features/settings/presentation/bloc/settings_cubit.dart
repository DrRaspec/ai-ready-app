import 'package:ai_chat_bot/features/settings/presentation/bloc/settings_state.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:shadow_log/shadow_log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const String _textScaleKey = 'text_scale_factor';
  static const String _fontFamilyKey = 'font_family';
  static const String _bubbleColorKey = 'bubble_color';
  static const String _localeCodeKey = 'locale_code';
  static const Set<String> _khmerFontFamilies = {
    'App Default',
    'Noto Sans Khmer',
    'Kantumruy Pro',
    'Battambang',
    'Hanuman',
    'Khmer',
  };
  final AuthRepository? _authRepository;

  SettingsCubit({SettingsState? initialState, AuthRepository? authRepository})
    : _authRepository = authRepository,
      super(initialState ?? SettingsState.initial()) {
    if (initialState == null) {
      _loadSettings();
    }
  }

  Future<void> syncFromServerPreferences() async {
    if (_authRepository == null) return;

    try {
      final response = await _authRepository.getPreferences();
      final remote = response.data;
      if (!response.success || remote == null) {
        return;
      }

      final remoteLocaleCode = _normalizeLocaleCode(remote.preferredLanguage);
      if (remoteLocaleCode != null && remoteLocaleCode != state.localeCode) {
        await _applyLocaleCode(remoteLocaleCode);
      }
    } on ApiException catch (e) {
      ShadowLog.w('Failed to sync preferences from server: ${e.message}');
    } catch (e) {
      ShadowLog.w('Failed to sync preferences from server: $e');
    }
  }

  Future<void> _applyLocaleCode(String normalized) async {
    final prefs = await SharedPreferences.getInstance();
    final shouldUseKhmerFont =
        normalized == 'km' && !_khmerFontFamilies.contains(state.fontFamily);
    final nextFontFamily = shouldUseKhmerFont ? 'App Default' : state.fontFamily;

    await prefs.setString(_localeCodeKey, normalized);
    if (shouldUseKhmerFont) {
      await prefs.setString(_fontFamilyKey, nextFontFamily);
    }
    emit(state.copyWith(localeCode: normalized, fontFamily: nextFontFamily));
  }

  String? _normalizeLocaleCode(String? preferredLanguage) {
    final value = preferredLanguage?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    if (value == 'km' || value == 'kh' || value == 'khmer') return 'km';
    if (value == 'en' || value == 'english') return 'en';
    return null;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
    final fontFamily = prefs.getString(_fontFamilyKey) ?? 'App Default';
    final bubbleColor = prefs.getInt(_bubbleColorKey);
    final localeCode = prefs.getString(_localeCodeKey);
    emit(
      SettingsState(
        textScaleFactor: textScale,
        fontFamily: fontFamily,
        bubbleColor: bubbleColor,
        localeCode: localeCode,
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

  Future<void> setLocaleCode(String? localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = localeCode?.trim().toLowerCase();

    final shouldUseKhmerFont =
        normalized == 'km' && !_khmerFontFamilies.contains(state.fontFamily);
    final nextFontFamily = shouldUseKhmerFont ? 'App Default' : state.fontFamily;

    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(_localeCodeKey);
      emit(state.copyWith(clearLocaleCode: true, fontFamily: nextFontFamily));
      return;
    }

    await _applyLocaleCode(normalized);
  }
}
