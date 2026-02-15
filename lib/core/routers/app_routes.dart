import 'package:ai_chat_bot/features/auth/presentation/pages/login_page.dart';
import 'package:ai_chat_bot/features/auth/presentation/pages/register_page.dart';
import 'package:ai_chat_bot/features/chat/presentation/pages/chat_page.dart';
import 'package:ai_chat_bot/features/chat/presentation/pages/usage_page.dart';
import 'package:ai_chat_bot/features/profile/presentation/profile_screen.dart';
import 'package:ai_chat_bot/features/bookmarks/presentation/pages/bookmarks_page.dart';
import 'package:ai_chat_bot/features/discover/presentation/pages/discover_page.dart';
import 'package:ai_chat_bot/features/prompts/presentation/pages/prompt_library_page.dart'; // Added import
import 'package:ai_chat_bot/features/settings/presentation/pages/personalization_page.dart'; // Added import
import 'package:ai_chat_bot/features/auth/presentation/pages/sessions_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';
import 'route_paths.dart';
import 'router_guards.dart';
import '../di/dependency_injection.dart';
import '../storage/token_storage.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.chat,
  redirect: (context, state) async {
    final storage = di<TokenStorage>();
    return await RouterGuards.authGuard(state, storage);
  },
  routes: [
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      redirect: (context, state) => RoutePaths.chat,
    ),
    GoRoute(
      path: RoutePaths.login,
      name: RouteNames.login,
      pageBuilder: (context, state) =>
          _buildAdaptivePage(state: state, child: const LoginPage()),
    ),
    GoRoute(
      path: RoutePaths.register,
      name: RouteNames.register,
      pageBuilder: (context, state) =>
          _buildAdaptivePage(state: state, child: const RegisterPage()),
    ),
    // GoRoute(
    //   path: RoutePaths.conversations,
    //   name: RouteNames.conversations,
    //   builder: (context, state) => const ConversationsPage(),
    // ),
    GoRoute(
      path: RoutePaths.chat,
      name: RouteNames.chat,
      pageBuilder: (context, state) {
        final extra = state.extra;
        String? conversationId;
        String? scrollToMessageId;

        if (extra is String) {
          conversationId = extra;
        } else if (extra is Map<String, dynamic>) {
          conversationId = extra['conversationId'] as String?;
          scrollToMessageId = extra['messageId'] as String?;
        }

        return _buildAdaptivePage(
          state: state,
          child: ChatPage(
            conversationId: conversationId,
            scrollToMessageId: scrollToMessageId,
          ),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.usage,
      name: RouteNames.usage,
      pageBuilder: (context, state) =>
          _buildAdaptivePage(state: state, child: const UsagePage()),
    ),
    GoRoute(
      path: RoutePaths.profile,
      name: RouteNames.profile,
      pageBuilder: (context, state) =>
          _buildAdaptivePage(state: state, child: const ProfileScreen()),
    ),
    GoRoute(
      path: RoutePaths.bookmarks,
      name: RouteNames.bookmarks,
      pageBuilder: (context, state) =>
          _buildAdaptivePage(state: state, child: const BookmarksPage()),
    ),
    GoRoute(
      path: RoutePaths.discover,
      name: RouteNames.discover,
      pageBuilder: (context, state) =>
          _buildAdaptivePage(state: state, child: const DiscoverPage()),
    ),
    GoRoute(
      path: RoutePaths.prompts,
      name: RouteNames.prompts,
      pageBuilder: (context, state) =>
          _buildAdaptivePage(state: state, child: const PromptLibraryPage()),
    ),
    GoRoute(
      path: RoutePaths.personalization,
      name: RouteNames.personalization,
      pageBuilder: (context, state) =>
          _buildAdaptivePage(state: state, child: const PersonalizationPage()),
    ),
    GoRoute(
      path: RoutePaths.sessions,
      name: RouteNames.sessions,
      pageBuilder: (context, state) =>
          _buildAdaptivePage(state: state, child: const SessionsPage()),
    ),
  ],
);

CustomTransitionPage<void> _buildAdaptivePage({
  required GoRouterState state,
  required Widget child,
}) {
  final isCupertino =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  if (isCupertino) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final primary = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final secondary = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(primary),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.25, 0),
            ).animate(secondary),
            child: child,
          ),
        );
      },
    );
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
