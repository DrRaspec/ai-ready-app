import 'package:equatable/equatable.dart';
import 'package:ai_chat_bot/features/auth/data/models/user_preferences.dart';

class PersonalizationState extends Equatable {
  final UserPreferences? preferences;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const PersonalizationState({
    this.preferences,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  PersonalizationState copyWith({
    UserPreferences? preferences,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return PersonalizationState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Clear error if not provided
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [preferences, isLoading, errorMessage, isSuccess];
}
