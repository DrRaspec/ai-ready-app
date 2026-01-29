import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository _authRepository;

  ProfileCubit(this._authRepository) : super(const ProfileState());

  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final response = await _authRepository.getUserStats();

      if (response.success && response.data != null) {
        final stats = response.data!;
        emit(
          state.copyWith(
            profilePictureUrl: stats.profilePictureUrl,
            firstName: stats.firstName,
            lastName: stats.lastName,
            conversationCount: stats.conversationCount,
            messageCount: stats.messageCount,
            unlockedAchievements: stats.earnedBadges,
            isLoading: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to load profile',
          ),
        );
      }
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> fetchProfile() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final response = await _authRepository.getProfile();

      if (response.success && response.data != null) {
        final user = response.data!;
        emit(
          state.copyWith(
            profilePictureUrl: user.profilePictureUrl,
            firstName: user.firstName,
            lastName: user.lastName,
            isLoading: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to load profile',
          ),
        );
      }
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<bool> updateProfile({String? firstName, String? lastName}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final response = await _authRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );

      if (response.success && response.data != null) {
        final user = response.data!;
        emit(
          state.copyWith(
            firstName: user.firstName,
            lastName: user.lastName,
            isLoading: false,
          ),
        );
        return true;
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to update profile',
          ),
        );
        return false;
      }
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
      return false;
    }
  }

  Future<bool> uploadProfilePicture(String filePath) async {
    emit(state.copyWith(isUploading: true, clearError: true));

    try {
      final response = await _authRepository.uploadProfilePicture(filePath);

      if (response.success && response.data != null) {
        final user = response.data!;
        emit(
          state.copyWith(
            profilePictureUrl: user.profilePictureUrl,
            isUploading: false,
          ),
        );
        return true;
      } else {
        emit(
          state.copyWith(
            isUploading: false,
            errorMessage: response.message ?? 'Failed to upload picture',
          ),
        );
        return false;
      }
    } on ApiException catch (e) {
      emit(state.copyWith(isUploading: false, errorMessage: e.message));
      return false;
    }
  }

  Future<void> refreshStats() async {
    try {
      final response = await _authRepository.getUserStats();

      if (response.success && response.data != null) {
        final stats = response.data!;
        final newBadges = stats.earnedBadges
            .where((badge) => !state.unlockedAchievements.contains(badge))
            .toList();

        emit(
          state.copyWith(
            conversationCount: stats.conversationCount,
            messageCount: stats.messageCount,
            unlockedAchievements: stats.earnedBadges,
            newlyUnlocked: newBadges,
          ),
        );
      }
    } on ApiException {
      // Silent fail for refresh
    }
  }

  void clearNewlyUnlocked() {
    emit(state.copyWith(newlyUnlocked: []));
  }

  Future<void> setAvatar(String? path) async {
    emit(state.copyWith(avatarPath: path, clearAvatar: path == null));
  }
}
