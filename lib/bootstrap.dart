import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/storage/token_storage.dart';
import 'package:ai_chat_bot/features/auth/data/auth_repository.dart';
import 'package:get_it/get_it.dart';

final GetIt di = GetIt.instance;

Future<void> setupDI() async {
  // Storage
  di.registerLazySingleton<TokenStorage>(() => TokenStorage());

  // Network
  di.registerLazySingleton<DioClient>(
    () => DioClient(tokenStorage: di<TokenStorage>(), onUnauthorized: () {}),
  );

  di.registerLazySingleton<AuthRepository>(
    () => AuthRepository(di<DioClient>()),
  );
}
