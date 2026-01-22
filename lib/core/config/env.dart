import 'app_env.dart';

class Env {
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static AppEnv get appEnv {
    switch (_env) {
      case 'production':
        return AppEnv.production;
      case 'dev':
      default:
        return AppEnv.dev;
    }
  }

  static bool get isDev => appEnv == AppEnv.dev;
  static bool get isProduction => appEnv == AppEnv.production;
}
