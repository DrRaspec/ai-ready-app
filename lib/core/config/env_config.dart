import 'env_loader.dart';

class EnvConfig {
  // Network
  static String get apiBaseUrl => EnvLoader.get('API_BASE_URL');

  static int get connectTimeout =>
      int.parse(EnvLoader.get('CONNECT_TIMEOUT', fallback: '10000'));

  // Feature flags
  static bool get enableMockAuth =>
      EnvLoader.get('ENABLE_MOCK_AUTH', fallback: 'false') == 'true';
}
