import 'env_loader.dart';

class EnvConfig {
  // Network
  static String get apiBaseUrl {
    final modern = EnvLoader.get('API_BASE_URL');
    if (modern.isNotEmpty) return modern;
    return EnvLoader.get('BASE_URL');
  }

  static int get connectTimeout =>
      int.parse(EnvLoader.get('CONNECT_TIMEOUT', fallback: '10000'));

  // Feature flags
  static bool get enableMockAuth =>
      EnvLoader.get('ENABLE_MOCK_AUTH', fallback: 'false') == 'true';

  static String get googleWebClientId {
    final raw = EnvLoader.get('GOOGLE_WEB_CLIENT_ID').trim();
    if (raw.isEmpty) return '';
    return raw
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }
}
