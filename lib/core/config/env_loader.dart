import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'env.dart';
import 'app_env.dart';

class EnvLoader {
  static Future<void> load() async {
    final candidates = switch (Env.appEnv) {
      AppEnv.dev => const [
        'env/.env.dev',
        'env/.env.dev.example',
        'env/.env.example',
      ],
      AppEnv.production => const [
        'env/.env.production',
        'env/.env.production.example',
        'env/.env.example',
      ],
    };

    for (final file in candidates) {
      try {
        await dotenv.load(fileName: file);
        return;
      } catch (_) {
        // Try the next fallback.
      }
    }

    throw StateError(
      'Missing environment file. Expected one of: ${candidates.join(', ')}',
    );
  }

  static String get(String key, {String fallback = ''}) {
    return dotenv.env[key] ?? fallback;
  }
}
