import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/storage/token_storage.dart';
import 'package:ai_chat_bot/core/storage/local_storage.dart';
import 'package:ai_chat_bot/core/device/device_id_provider.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:ai_chat_bot/features/chat/data/chat_repository.dart';
import 'package:ai_chat_bot/features/chat/data/folder_repository.dart';
import 'package:ai_chat_bot/features/prompts/data/prompt_repository.dart';
import 'package:ai_chat_bot/features/chat/data/streaming_service.dart';
import 'package:ai_chat_bot/features/gamification/data/gamification_repository.dart';
import 'package:ai_chat_bot/features/favorites/data/favorites_repository.dart';
import 'package:ai_chat_bot/features/analytics/data/analytics_repository.dart';
import 'package:ai_chat_bot/features/health/data/health_repository.dart';
import 'package:ai_chat_bot/core/config/env_config.dart';
import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/core/routers/app_routes.dart';
import 'package:ai_chat_bot/core/routers/route_paths.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shadow_log/shadow_log.dart';

Future<void> setupDI() async {
  // Initialize local storage (Hive)
  await LocalStorage.init();

  // Storage
  di.registerLazySingleton<TokenStorage>(() => TokenStorage());
  di.registerLazySingleton<DeviceIdProvider>(
    () => DeviceIdProvider(tokenStorage: di<TokenStorage>()),
  );

  di.registerLazySingleton<GoogleSignIn>(() {
    final serverClientId = EnvConfig.googleWebClientId;
    if (serverClientId.isEmpty) {
      ShadowLog.w(
        'GOOGLE_WEB_CLIENT_ID is empty. Google sign-in will fail until set.',
      );
    }
    return GoogleSignIn(serverClientId: serverClientId);
  });

  // Network
  di.registerLazySingleton<DioClient>(
    () => DioClient(
      tokenStorage: di<TokenStorage>(),
      deviceIdProvider: di<DeviceIdProvider>(),
      onUnauthorized: () async {
        // Force clear tokens to ensure RouterGuard sees unauthenticated state
        await di<TokenStorage>().clear();

        // Using delayed to ensure context is ready and frame is settled
        Future.delayed(const Duration(milliseconds: 300), () {
          appRouter.go(RoutePaths.login);
        });
      },
    ),
  );

  // Repositories
  di.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      di<DioClient>(),
      di<DeviceIdProvider>(),
      di<TokenStorage>(),
    ),
  );
  di.registerLazySingleton<ChatRepository>(
    () => ChatRepository(di<DioClient>()),
  );
  di.registerLazySingleton<FolderRepository>(
    () => FolderRepository(di<DioClient>()),
  );
  di.registerLazySingleton<PromptRepository>(
    () => PromptRepository(di<DioClient>()),
  );
  di.registerLazySingleton<GamificationRepository>(
    () => GamificationRepository(di<DioClient>()),
  );
  di.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepository(di<DioClient>()),
  );
  di.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepository(di<DioClient>()),
  );
  di.registerLazySingleton<HealthRepository>(
    () => HealthRepository(di<DioClient>()),
  );

  // Services
  di.registerLazySingleton<StreamingService>(
    () => StreamingService(
      dio: di<DioClient>().dio,
      baseUrl: EnvConfig.apiBaseUrl,
    ),
  );
}
