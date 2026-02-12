import 'package:get/get.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/data/models/user_preferences.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'personalization_state.dart';

class PersonalizationController extends GetxController {
  final AuthRepository _authRepository;
  final Rx<PersonalizationState> rxState;

  PersonalizationState get state => rxState.value;

  void _setState(PersonalizationState newState) {
    rxState.value = newState;
  }

  PersonalizationController(this._authRepository)
    : rxState = const PersonalizationState().obs;

  Future<void> loadPreferences() async {
    _setState(state.copyWith(isLoading: true));
    try {
      final response = await _authRepository.getPreferences();
      if (response.success && response.data != null) {
        _setState(state.copyWith(preferences: response.data, isLoading: false));
      } else {
        _setState(
          state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to load preferences',
          ),
        );
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> updatePreferences(UserPreferences newPrefs) async {
    _setState(state.copyWith(isLoading: true, isSuccess: false));
    try {
      final response = await _authRepository.updatePreferences(newPrefs);
      if (response.success && response.data != null) {
        _setState(
          state.copyWith(
            preferences: response.data,
            isLoading: false,
            isSuccess: true,
          ),
        );
      } else {
        _setState(
          state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to update preferences',
          ),
        );
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  void resetSuccess() {
    _setState(state.copyWith(isSuccess: false));
  }
}
