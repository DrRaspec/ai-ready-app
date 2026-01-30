class UsageStats {
  final int todayTokens;
  final int todayRequests;
  final int weeklyTokens;
  final int weeklyRequests;
  final int monthlyTokens;
  final int monthlyRequests;

  const UsageStats({
    required this.todayTokens,
    required this.todayRequests,
    required this.weeklyTokens,
    required this.weeklyRequests,
    required this.monthlyTokens,
    required this.monthlyRequests,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      todayTokens: (json['todayTokens'] as num?)?.toInt() ?? 0,
      todayRequests: (json['todayRequests'] as num?)?.toInt() ?? 0,
      weeklyTokens: (json['weeklyTokens'] as num?)?.toInt() ?? 0,
      weeklyRequests: (json['weeklyRequests'] as num?)?.toInt() ?? 0,
      monthlyTokens: (json['monthlyTokens'] as num?)?.toInt() ?? 0,
      monthlyRequests: (json['monthlyRequests'] as num?)?.toInt() ?? 0,
    );
  }
}
