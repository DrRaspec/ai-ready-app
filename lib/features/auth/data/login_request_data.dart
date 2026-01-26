class LoginRequestData {
  const LoginRequestData({
    required this.email,
    required this.password,
    this.deviceId,
  });

  final String email;
  final String password;
  final String? deviceId;

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'deviceId': deviceId};
  }

  LoginRequestData copyWith({
    String? email,
    String? password,
    String? deviceId,
  }) {
    return LoginRequestData(
      email: email ?? this.email,
      password: password ?? this.password,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
