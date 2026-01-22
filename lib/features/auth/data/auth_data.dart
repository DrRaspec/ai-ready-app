class AuthData {
  final String? userId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? role;
  final String? accessToken;
  final String? refreshToken;
  final String? accessTokenExpiresAt;

  const AuthData({
    this.userId,
    this.email,
    this.firstName,
    this.lastName,
    this.role,
    this.accessToken,
    this.refreshToken,
    this.accessTokenExpiresAt,
  });

  @override
  String toString() {
    return 'AuthData(userId: $userId, email: $email, firstName: $firstName, lastName: $lastName, role: $role, accessToken: $accessToken, refreshToken: $refreshToken, accessTokenExpiresAt: $accessTokenExpiresAt)';
  }

  factory AuthData.fromJson(Map<String, dynamic> json) => AuthData(
    userId: json['userId'] as String?,
    email: json['email'] as String?,
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
    role: json['role'] as String?,
    accessToken: json['accessToken'] as String?,
    refreshToken: json['refreshToken'] as String?,
    accessTokenExpiresAt: json['accessTokenExpiresAt'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'role': role,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'accessTokenExpiresAt': accessTokenExpiresAt,
  };

  AuthData copyWith({
    String? userId,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? accessToken,
    String? refreshToken,
    String? accessTokenExpiresAt,
  }) {
    return AuthData(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
    );
  }
}
