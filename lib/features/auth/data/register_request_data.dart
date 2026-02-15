import 'dart:convert';

class RegisterRequestData {
  String? firstName;
  String? lastName;
  String? email;
  String? password;
  String? deviceId;
  String? deviceName;
  String? deviceType;

  RegisterRequestData({
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.deviceId,
    this.deviceName,
    this.deviceType,
  });

  @override
  String toString() {
    return 'RegisterRequestData(firstName: $firstName, lastName: $lastName, email: $email, password: $password, deviceId: $deviceId, deviceName: $deviceName, deviceType: $deviceType)';
  }

  factory RegisterRequestData.fromMap(Map<String, dynamic> data) {
    return RegisterRequestData(
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      email: data['email'] as String?,
      password: data['password'] as String?,
      deviceId: data['deviceId'] as String?,
      deviceName: data['deviceName'] as String?,
      deviceType: data['deviceType'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'password': password,
    'deviceId': deviceId,
    if (deviceName != null) 'deviceName': deviceName,
    if (deviceType != null) 'deviceType': deviceType,
  };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [RegisterRequestData].
  factory RegisterRequestData.fromJson(String data) {
    return RegisterRequestData.fromMap(
      json.decode(data) as Map<String, dynamic>,
    );
  }

  /// `dart:convert`
  ///
  /// Converts [RegisterRequestData] to a JSON string.
  String toJson() => json.encode(toMap());

  RegisterRequestData copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? deviceId,
    String? deviceName,
    String? deviceType,
  }) {
    return RegisterRequestData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
    );
  }
}
