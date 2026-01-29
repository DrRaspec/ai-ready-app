class UserStatsData {
  final int conversationCount;
  final int messageCount;
  final int badges;
  final List<String> earnedBadges;
  final String? userId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;

  const UserStatsData({
    required this.conversationCount,
    required this.messageCount,
    required this.badges,
    required this.earnedBadges,
    this.userId,
    this.email,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
  });

  factory UserStatsData.fromJson(Map<String, dynamic> json) {
    return UserStatsData(
      conversationCount: json['conversationCount'] as int? ?? 0,
      messageCount: json['messageCount'] as int? ?? 0,
      badges: json['badges'] as int? ?? 0,
      earnedBadges:
          (json['earnedBadges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      userId: json['userId'] as String?,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationCount': conversationCount,
      'messageCount': messageCount,
      'badges': badges,
      'earnedBadges': earnedBadges,
      'userId': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
