import 'package:go_router/go_router.dart';

import '../storage/token_storage.dart';
import 'route_paths.dart';

class RouterGuards {
  static Future<String?> authGuard(
    GoRouterState state,
    TokenStorage storage,
  ) async {
    final isLoggedIn = await storage.hasValidToken();
    final location = state.matchedLocation;

    if (!isLoggedIn &&
        (location == RoutePaths.login || location == RoutePaths.register)) {
      return null;
    }

    if (!isLoggedIn) {
      return RoutePaths.login;
    }

    if (isLoggedIn &&
        (location == RoutePaths.login || location == RoutePaths.register)) {
      return RoutePaths.home;
    }

    return null;
  }
}
