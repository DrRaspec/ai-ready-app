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
    final rawSessionId = json['sessionId'] ?? json['id'];
    final sessionId = rawSessionId?.toString() ?? '';

    final directDeviceInfo = (json['deviceInfo'] as String?)?.trim();
    final deviceName = (json['deviceName'] as String?)?.trim();
    final deviceType = (json['deviceType'] as String?)?.trim();
    final deviceId = (json['deviceId'] as String?)?.trim();
    final deviceInfo = (directDeviceInfo != null && directDeviceInfo.isNotEmpty)
        ? directDeviceInfo
        : (deviceName != null && deviceName.isNotEmpty)
        ? deviceName
        : (deviceType != null && deviceType.isNotEmpty)
        ? deviceType
        : (deviceId != null && deviceId.isNotEmpty)
        ? deviceId
        : 'Unknown Device';

    final rawIpAddress = (json['ipAddress'] as String?)?.trim();
    final ipAddress = (rawIpAddress != null && rawIpAddress.isNotEmpty)
        ? rawIpAddress
        : 'Unknown IP';

    final rawLastActive = json['lastActive'] ?? json['lastUsedAt'];
    final DateTime? lastActive = rawLastActive == null
        ? null
        : DateTime.tryParse(rawLastActive.toString());

    final rawIsCurrent = json['isCurrentSession'] ?? json['current'];
    final bool isCurrentSession = rawIsCurrent is bool
        ? rawIsCurrent
        : rawIsCurrent is num
        ? rawIsCurrent != 0
        : rawIsCurrent?.toString().toLowerCase() == 'true';

    return Session(
      sessionId: sessionId,
      deviceInfo: deviceInfo,
      ipAddress: ipAddress,
      lastActive: lastActive,
      isCurrentSession: isCurrentSession,
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
