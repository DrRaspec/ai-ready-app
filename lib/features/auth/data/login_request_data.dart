class LoginRequestData {
  const LoginRequestData({
    required this.email,
    required this.password,
    this.deviceId,
    this.deviceName,
    this.deviceType,
  });

  final String email;
  final String password;
  final String? deviceId;
  final String? deviceName;
  final String? deviceType;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
      if (deviceType != null) 'deviceType': deviceType,
    };
  }

  LoginRequestData copyWith({
    String? email,
    String? password,
    String? deviceId,
    String? deviceName,
    String? deviceType,
  }) {
    return LoginRequestData(
      email: email ?? this.email,
      password: password ?? this.password,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
    );
  }
}
