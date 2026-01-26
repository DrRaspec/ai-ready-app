/// Model for usage statistics.
class UsageSummary {
  final int todayTokens;
  final int todayRequests;
  final int weeklyTokens;
  final int weeklyRequests;
  final int monthlyTokens;
  final int monthlyRequests;

  const UsageSummary({
    this.todayTokens = 0,
    this.todayRequests = 0,
    this.weeklyTokens = 0,
    this.weeklyRequests = 0,
    this.monthlyTokens = 0,
    this.monthlyRequests = 0,
  });

  factory UsageSummary.fromJson(Map<String, dynamic> json) => UsageSummary(
    todayTokens: json['todayTokens'] as int? ?? 0,
    todayRequests: json['todayRequests'] as int? ?? 0,
    weeklyTokens: json['weeklyTokens'] as int? ?? 0,
    weeklyRequests: json['weeklyRequests'] as int? ?? 0,
    monthlyTokens: json['monthlyTokens'] as int? ?? 0,
    monthlyRequests: json['monthlyRequests'] as int? ?? 0,
  );
}
