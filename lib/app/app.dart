import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/core/theme/theme_state.dart';
import 'package:ai_chat_bot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ai_chat_bot/features/chat/data/chat_repository.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:ai_chat_bot/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/folder_cubit.dart';
import 'package:ai_chat_bot/features/chat/data/folder_repository.dart';
import 'package:ai_chat_bot/features/bookmarks/presentation/bloc/bookmarks_cubit.dart';
import 'package:ai_chat_bot/features/favorites/data/favorites_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_chat_bot/features/gamification/data/gamification_repository.dart';
import 'package:ai_chat_bot/features/gamification/presentation/bloc/gamification_cubit.dart';
import 'package:ai_chat_bot/features/gamification/presentation/widgets/achievement_listener.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_cubit.dart';
import '../features/settings/presentation/bloc/settings_cubit.dart';
import '../features/settings/presentation/bloc/settings_state.dart';
import '../core/routers/app_routes.dart';
import '../core/routers/route_paths.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/data/auth_repository.dart';

class App extends StatelessWidget {
  final ThemeMode initialTheme;
  final SettingsState? initialSettings;

  const App({
    super.key,
    this.initialTheme = ThemeMode.system,
    this.initialSettings,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(initialTheme: initialTheme)),
        BlocProvider(
          create: (_) => SettingsCubit(initialState: initialSettings),
        ),
        BlocProvider(
          create: (_) => AuthBloc(
            tokenStorage: di<TokenStorage>(),
            authRepository: di<AuthRepository>(),
            googleSignIn: di<GoogleSignIn>(),
          )..add(AuthStarted()),
        ),
        BlocProvider(create: (_) => ChatBloc(di<ChatRepository>())),
        BlocProvider(create: (_) => ProfileCubit(di<AuthRepository>())),
        BlocProvider(
          create: (_) =>
              BookmarksCubit(favoritesRepository: di<FavoritesRepository>())
                ..loadBookmarks(),
        ),
        BlocProvider(
          create: (_) => FolderCubit(di<FolderRepository>())..loadFolders(),
        ),
        BlocProvider(
          create: (_) => GamificationCubit(
            di<GamificationRepository>(),
            di<SharedPreferences>(),
          )..checkStatus(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(fontFamily: settingsState.fontFamily),
                darkTheme: AppTheme.dark(fontFamily: settingsState.fontFamily),
                themeMode: themeState.mode,
                routerConfig: appRouter,
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  return BlocListener<AuthBloc, AuthState>(
                    listenWhen: (previous, current) =>
                        current is Unauthenticated,
                    listener: (context, state) {
                      appRouter.go(RoutePaths.login);
                    },
                    child: MediaQuery(
                      data: mediaQuery.copyWith(
                        textScaler: TextScaler.linear(
                          settingsState.textScaleFactor,
                        ),
                      ),
                      child: AchievementListener(child: child!),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
