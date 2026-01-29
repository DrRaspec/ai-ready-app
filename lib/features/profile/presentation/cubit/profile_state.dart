import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final String? avatarPath;
  final String? profilePictureUrl;
  final String? firstName;
  final String? lastName;
  final int conversationCount;
  final int messageCount;
  final List<String> unlockedAchievements;
  final List<String> newlyUnlocked;
  final bool isLoading;
  final bool isUploading;
  final String? errorMessage;

  const ProfileState({
    this.avatarPath,
    this.profilePictureUrl,
    this.firstName,
    this.lastName,
    this.conversationCount = 0,
    this.messageCount = 0,
    this.unlockedAchievements = const [],
    this.newlyUnlocked = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    String? avatarPath,
    bool clearAvatar = false,
    String? profilePictureUrl,
    bool clearProfilePicture = false,
    String? firstName,
    String? lastName,
    int? conversationCount,
    int? messageCount,
    List<String>? unlockedAchievements,
    List<String>? newlyUnlocked,
    bool? isLoading,
    bool? isUploading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      profilePictureUrl: clearProfilePicture
          ? null
          : (profilePictureUrl ?? this.profilePictureUrl),
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      conversationCount: conversationCount ?? this.conversationCount,
      messageCount: messageCount ?? this.messageCount,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      newlyUnlocked: newlyUnlocked ?? this.newlyUnlocked,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    avatarPath,
    profilePictureUrl,
    firstName,
    lastName,
    conversationCount,
    messageCount,
    unlockedAchievements,
    newlyUnlocked,
    isLoading,
    isUploading,
    errorMessage,
  ];
}
