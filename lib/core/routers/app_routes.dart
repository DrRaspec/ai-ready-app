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
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: RoutePaths.register,
      name: RouteNames.register,
      builder: (context, state) => const RegisterPage(),
    ),
    // GoRoute(
    //   path: RoutePaths.conversations,
    //   name: RouteNames.conversations,
    //   builder: (context, state) => const ConversationsPage(),
    // ),
    GoRoute(
      path: RoutePaths.chat,
      name: RouteNames.chat,
      builder: (context, state) {
        final extra = state.extra;
        String? conversationId;
        String? scrollToMessageId;

        if (extra is String) {
          conversationId = extra;
        } else if (extra is Map<String, dynamic>) {
          conversationId = extra['conversationId'] as String?;
          scrollToMessageId = extra['messageId'] as String?;
        }

        return ChatPage(
          conversationId: conversationId,
          scrollToMessageId: scrollToMessageId,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.usage,
      name: RouteNames.usage,
      builder: (context, state) => const UsagePage(),
    ),
    GoRoute(
      path: RoutePaths.profile,
      name: RouteNames.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: RoutePaths.bookmarks,
      name: RouteNames.bookmarks,
      builder: (context, state) => const BookmarksPage(),
    ),
    GoRoute(
      path: RoutePaths.discover,
      name: RouteNames.discover,
      builder: (context, state) => const DiscoverPage(),
    ),
    GoRoute(
      path: RoutePaths.prompts,
      name: RouteNames.prompts,
      builder: (context, state) => const PromptLibraryPage(),
    ),
    GoRoute(
      path: RoutePaths.personalization,
      name: RouteNames.personalization,
      builder: (context, state) => const PersonalizationPage(),
    ),
    GoRoute(
      path: RoutePaths.sessions,
      name: RouteNames.sessions,
      builder: (context, state) => const SessionsPage(),
    ),
  ],
);
