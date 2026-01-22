import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'env.dart';
import 'app_env.dart';

class EnvLoader {
  static Future<void> load() async {
    final file = switch (Env.appEnv) {
      AppEnv.dev => 'env/.env.dev',
      AppEnv.production => 'env/.env.production',
    };

    await dotenv.load(fileName: file);
  }

  static String get(String key, {String fallback = ''}) {
    return dotenv.env[key] ?? fallback;
  }
}
