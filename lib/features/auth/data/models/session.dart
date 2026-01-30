class Session {
  final String sessionId;
  final String deviceInfo;
  final String ipAddress;
  final DateTime? lastActive;
  final bool isCurrentSession;

  Session({
    required this.sessionId,
    required this.deviceInfo,
    required this.ipAddress,
    this.lastActive,
    required this.isCurrentSession,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionId: json['sessionId'].toString(),
      deviceInfo: json['deviceInfo'] as String? ?? 'Unknown Device',
      ipAddress: json['ipAddress'] as String? ?? 'Unknown IP',
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'] as String)
          : null,
      isCurrentSession: json['isCurrentSession'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
      'lastActive': lastActive?.toIso8601String(),
      'isCurrentSession': isCurrentSession,
    };
  }
}
