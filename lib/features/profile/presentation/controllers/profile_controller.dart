import 'package:get/get.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'profile_state.dart';

class ProfileController extends GetxController {
  final AuthRepository _authRepository;
  final Rx<ProfileState> rxState;

  ProfileState get state => rxState.value;

  void _setState(ProfileState newState) {
    rxState.value = newState;
  }

  ProfileController(this._authRepository) : rxState = const ProfileState().obs;

  Future<void> loadProfile() async {
    _setState(state.copyWith(isLoading: true, clearError: true));

    try {
      final response = await _authRepository.getUserStats();

      if (response.success && response.data != null) {
        final stats = response.data!;
        _setState(
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
        _setState(
          state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to load profile',
          ),
        );
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> fetchProfile() async {
    _setState(state.copyWith(isLoading: true, clearError: true));

    try {
      final response = await _authRepository.getProfile();

      if (response.success && response.data != null) {
        final user = response.data!;
        _setState(
          state.copyWith(
            profilePictureUrl: user.profilePictureUrl,
            firstName: user.firstName,
            lastName: user.lastName,
            isLoading: false,
          ),
        );
      } else {
        _setState(
          state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to load profile',
          ),
        );
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<bool> updateProfile({String? firstName, String? lastName}) async {
    _setState(state.copyWith(isLoading: true, clearError: true));

    try {
      final response = await _authRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );

      if (response.success && response.data != null) {
        final user = response.data!;
        _setState(
          state.copyWith(
            firstName: user.firstName,
            lastName: user.lastName,
            isLoading: false,
          ),
        );
        return true;
      } else {
        _setState(
          state.copyWith(
            isLoading: false,
            errorMessage: response.message ?? 'Failed to update profile',
          ),
        );
        return false;
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(isLoading: false, errorMessage: e.message));
      return false;
    }
  }

  Future<bool> uploadProfilePicture(String filePath) async {
    _setState(state.copyWith(isUploading: true, clearError: true));

    try {
      final response = await _authRepository.uploadProfilePicture(filePath);

      if (response.success && response.data != null) {
        final user = response.data!;
        _setState(
          state.copyWith(
            profilePictureUrl: user.profilePictureUrl,
            isUploading: false,
          ),
        );
        return true;
      } else {
        _setState(
          state.copyWith(
            isUploading: false,
            errorMessage: response.message ?? 'Failed to upload picture',
          ),
        );
        return false;
      }
    } on ApiException catch (e) {
      _setState(state.copyWith(isUploading: false, errorMessage: e.message));
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

        _setState(
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
    _setState(state.copyWith(newlyUnlocked: []));
  }

  Future<void> setAvatar(String? path) async {
    _setState(state.copyWith(avatarPath: path, clearAvatar: path == null));
  }
}
