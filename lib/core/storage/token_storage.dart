import 'package:ai_chat_bot/core/constants/storage_keys.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> readAccessToken() =>
      _storage.read(key: StorageKeys.accessToken);

  Future<String?> readRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);
  Future<String?> readDeviceId() => _storage.read(key: StorageKeys.deviceId);

  Future<void> writeTokens({
    required String? accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
    }
  }

  Future<void> writeDeviceId(String deviceId) async {
    await _storage.write(key: StorageKeys.deviceId, value: deviceId);
  }

  Future<void> clear({bool clearDeviceId = false}) async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    if (clearDeviceId) {
      await _storage.delete(key: StorageKeys.deviceId);
    }
  }

  Future<bool> hasValidToken() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
