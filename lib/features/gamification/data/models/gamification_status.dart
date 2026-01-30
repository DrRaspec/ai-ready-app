import 'package:ai_chat_bot/features/gamification/data/models/achievement.dart';

class GamificationStatus {
  final int currentStreak;
  final int totalPoints;
  final int completedAchievements;
  final int totalAchievements;
  final List<Achievement> achievements;

  const GamificationStatus({
    required this.currentStreak,
    required this.totalPoints,
    required this.completedAchievements,
    required this.totalAchievements,
    required this.achievements,
  });

  factory GamificationStatus.fromJson(Map<String, dynamic> json) {
    return GamificationStatus(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      completedAchievements:
          (json['completedAchievements'] as num?)?.toInt() ?? 0,
      totalAchievements: (json['totalAchievements'] as num?)?.toInt() ?? 0,
      achievements:
          (json['achievements'] as List?)
              ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
