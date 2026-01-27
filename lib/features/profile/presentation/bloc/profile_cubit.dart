import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_chat_bot/core/storage/local_storage.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository _authRepository;

  ProfileCubit(this._authRepository) : super(const ProfileState());

  /// Fetch profile from API
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

  /// Update profile name
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

  /// Upload profile picture
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

  /// Load profile data from local storage (legacy method)
  Future<void> loadProfile({required int conversationCount}) async {
    emit(state.copyWith(isLoading: true));

    final avatarPath = LocalStorage.getAvatarPath();
    final messageCount = LocalStorage.getMessageCount();
    final unlockedAchievements = LocalStorage.getUnlockedAchievements();

    // Check for new achievements
    final newlyUnlocked = await LocalStorage.checkAndUnlockAchievements(
      conversationCount: conversationCount,
      messageCount: messageCount,
    );

    emit(
      state.copyWith(
        avatarPath: avatarPath,
        conversationCount: conversationCount,
        messageCount: messageCount,
        unlockedAchievements: [...unlockedAchievements, ...newlyUnlocked],
        newlyUnlocked: newlyUnlocked,
        isLoading: false,
      ),
    );

    // Also fetch from API to get server profile picture
    await fetchProfile();
  }

  /// Update avatar path (local fallback)
  Future<void> setAvatar(String? path) async {
    await LocalStorage.setAvatarPath(path);
    emit(state.copyWith(avatarPath: path, clearAvatar: path == null));
  }

  /// Clear newly unlocked (after showing celebration)
  void clearNewlyUnlocked() {
    emit(state.copyWith(newlyUnlocked: []));
  }

  /// Refresh stats
  Future<void> refreshStats({required int conversationCount}) async {
    final messageCount = LocalStorage.getMessageCount();

    // Check for new achievements
    final newlyUnlocked = await LocalStorage.checkAndUnlockAchievements(
      conversationCount: conversationCount,
      messageCount: messageCount,
    );

    if (newlyUnlocked.isNotEmpty) {
      emit(
        state.copyWith(
          conversationCount: conversationCount,
          messageCount: messageCount,
          unlockedAchievements: [
            ...state.unlockedAchievements,
            ...newlyUnlocked,
          ],
          newlyUnlocked: newlyUnlocked,
        ),
      );
    } else {
      emit(
        state.copyWith(
          conversationCount: conversationCount,
          messageCount: messageCount,
        ),
      );
    }
  }
}
