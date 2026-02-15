import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/device/device_id_provider.dart';
import 'package:shadow_log/shadow_log.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:ai_chat_bot/core/storage/token_storage.dart';
import 'package:ai_chat_bot/features/auth/data/auth_data.dart';
import 'package:ai_chat_bot/features/auth/data/login_request_data.dart';
import 'package:ai_chat_bot/features/auth/data/models/session.dart';
import 'package:ai_chat_bot/features/auth/data/models/user_preferences.dart';
import 'package:ai_chat_bot/features/auth/data/models/user_stats_data.dart';
import 'package:ai_chat_bot/features/auth/data/register_request_data.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final DioClient _dioClient;
  final DeviceIdProvider _deviceIdProvider;
  final TokenStorage _tokenStorage;

  AuthRepository(
    DioClient dioClient,
    DeviceIdProvider deviceIdProvider,
    TokenStorage tokenStorage,
  ) : _dioClient = dioClient,
      _deviceIdProvider = deviceIdProvider,
      _tokenStorage = tokenStorage;

  Future<ApiResponse<AuthData>> login(LoginRequestData request) async {
    try {
      ShadowLog.i(
        'Login request -> ${_dioClient.dio.options.baseUrl}${ApiPaths.login}',
      );
      final deviceId =
          request.deviceId ?? await _deviceIdProvider.getDeviceId();
      final deviceName =
          request.deviceName ?? await _deviceIdProvider.getDeviceName();
      final deviceType =
          request.deviceType ?? await _deviceIdProvider.getDeviceType();
      final payload = request.copyWith(deviceId: deviceId);
      final enrichedPayload = payload.copyWith(
        deviceName: deviceName,
        deviceType: deviceType,
      );
      final response = await _dioClient.dio.post(
        ApiPaths.login,
        data: enrichedPayload.toJson(),
      );

      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      ShadowLog.e(
        'Login DioException: type=${e.type} message=${e.message} '
        'errorType=${e.error.runtimeType} error=${e.error} '
        'status=${e.response?.statusCode}',
        error: e.error,
        stackTrace: e.stackTrace,
      );
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<AuthData>> register(RegisterRequestData request) async {
    try {
      final deviceId =
          request.deviceId ?? await _deviceIdProvider.getDeviceId();
      final deviceName =
          request.deviceName ?? await _deviceIdProvider.getDeviceName();
      final deviceType =
          request.deviceType ?? await _deviceIdProvider.getDeviceType();
      final payload = request.copyWith(
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
      );
      final response = await _dioClient.dio.post(
        ApiPaths.register,
        data: payload.toMap(),
      );

      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<AuthData>> loginWithGoogle({
    required String idToken,
  }) async {
    try {
      final deviceId = await _deviceIdProvider.getDeviceId();
      final deviceName = await _deviceIdProvider.getDeviceName();
      final deviceType = await _deviceIdProvider.getDeviceType();

      final response = await _dioClient.dio.post(
        ApiPaths.googleLogin,
        data: {
          'idToken': idToken,
          'deviceId': deviceId,
          if (deviceName != null && deviceName.isNotEmpty)
            'deviceName': deviceName,
          if (deviceType.isNotEmpty) 'deviceType': deviceType,
        },
      );

      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<AuthData>> me() async {
    try {
      final response = await _dioClient.dio.post(ApiPaths.me);

      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      final deviceId = await _deviceIdProvider.getDeviceId();

      await _dioClient.dio.post(
        ApiPaths.logout,
        data: {'refreshToken': refreshToken, 'deviceId': deviceId},
      );
      await _tokenStorage.clear();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<AuthData>> refresh({
    String? refreshToken,
    String? deviceId,
  }) async {
    try {
      final token = refreshToken ?? await _tokenStorage.readRefreshToken();
      final resolvedDeviceId =
          deviceId ?? await _deviceIdProvider.getDeviceId();
      final response = await _dioClient.dio.post(
        ApiPaths.refreshToken,
        data: {'refreshToken': token, 'deviceId': resolvedDeviceId},
      );

      final parsed = _parseAuthResponse(response.data);

      if (parsed.success && parsed.data != null) {
        await _tokenStorage.writeTokens(
          accessToken: parsed.data!.accessToken,
          refreshToken: parsed.data!.refreshToken,
        );
      }

      return parsed;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logoutAll() async {
    try {
      await _dioClient.dio.post(ApiPaths.logoutAll);
      await _tokenStorage.clear();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<AuthData>> getProfile() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.profile);

      return ApiResponse<AuthData>.fromJson(
        response.data,
        (json) => AuthData.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<AuthData>> updateProfile({
    String? firstName,
    String? lastName,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;

      final response = await _dioClient.dio.put(ApiPaths.profile, data: data);

      return ApiResponse<AuthData>.fromJson(
        response.data,
        (json) => AuthData.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<AuthData>> uploadProfilePicture(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dioClient.dio.post(
        ApiPaths.profilePicture,
        data: formData,
      );

      return ApiResponse<AuthData>.fromJson(
        response.data,
        (json) => AuthData.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  ApiResponse<AuthData> _parseAuthResponse(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return ApiResponse<AuthData>(
        success: false,
        message: 'Invalid response format',
        status: 500,
      );
    }

    final normalized = Map<String, dynamic>.from(responseData);
    normalized['data'] = _extractAuthPayload(normalized['data']);

    return ApiResponse<AuthData>.fromJson(
      normalized,
      (json) => AuthData.fromJson(json as Map<String, dynamic>),
    );
  }

  dynamic _extractAuthPayload(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return data;
    }

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }

    return data;
  }

  Future<ApiResponse<UserStatsData>> getUserStats() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.userStats);
      return ApiResponse<UserStatsData>.fromJson(
        response.data,
        (json) => UserStatsData.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<UserPreferences>> getPreferences() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.preferences);
      return ApiResponse<UserPreferences>.fromJson(
        response.data,
        (json) => UserPreferences.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<UserPreferences>> updatePreferences(
    UserPreferences prefs,
  ) async {
    try {
      final response = await _dioClient.dio.put(
        ApiPaths.preferences,
        data: prefs.toJson(),
      );
      return ApiResponse<UserPreferences>.fromJson(
        response.data,
        (json) => UserPreferences.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<List<Session>>> getSessions() async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.sessions,
        options: Options(
          headers: {'X-Device-Id': await _deviceIdProvider.getDeviceId()},
        ),
      );
      return ApiResponse<List<Session>>.fromJson(
        response.data,
        (json) => (json as List)
            .map((e) => Session.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> terminateSession(String sessionId) async {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty ||
        normalizedSessionId.toLowerCase() == 'null') {
      throw ApiException(message: 'Invalid session id');
    }

    try {
      await _dioClient.dio.delete(
        ApiPaths.session(normalizedSessionId),
        options: Options(
          headers: {'X-Device-Id': await _deviceIdProvider.getDeviceId()},
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> terminateAllOtherSessions() async {
    try {
      await _dioClient.dio.delete(
        ApiPaths.sessionsAllOthers,
        options: Options(
          headers: {'X-Device-Id': await _deviceIdProvider.getDeviceId()},
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
