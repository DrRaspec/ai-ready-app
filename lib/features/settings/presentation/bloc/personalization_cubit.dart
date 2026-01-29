import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/auth/data/models/user_preferences.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'personalization_state.dart';

class PersonalizationCubit extends Cubit<PersonalizationState> {
  final AuthRepository _authRepository;

  PersonalizationCubit(this._authRepository)
    : super(const PersonalizationState());

  Future<void> loadPreferences() async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await _authRepository.getPreferences();
      if (response.success && response.data != null) {
        emit(state.copyWith(preferences: response.data, isLoading: false));
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to load preferences',
          ),
        );
      }
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> updatePreferences(UserPreferences newPrefs) async {
    emit(state.copyWith(isLoading: true, isSuccess: false));
    try {
      final response = await _authRepository.updatePreferences(newPrefs);
      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            preferences: response.data,
            isLoading: false,
            isSuccess: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to update preferences',
          ),
        );
      }
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  void resetSuccess() {
    emit(state.copyWith(isSuccess: false));
  }
}
