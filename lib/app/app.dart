import 'package:ai_chat_bot/core/di/dependency_injection.dart';
import 'package:ai_chat_bot/core/theme/theme_state.dart';
import 'package:ai_chat_bot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ai_chat_bot/features/chat/data/chat_repository.dart';
import 'package:ai_chat_bot/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_cubit.dart';
import '../core/routers/app_routes.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/data/auth_repository.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(
          create: (_) => AuthBloc(
            tokenStorage: di<TokenStorage>(),
            authRepository: di<AuthRepository>(),
          )..add(AppStarted()),
        ),
        BlocProvider(create: (_) => ChatBloc(di<ChatRepository>())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: state.mode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
