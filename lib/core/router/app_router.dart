import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teams_chat/presentation/features/auth/providers/auth_provider.dart';
import 'package:teams_chat/presentation/features/auth/screens/login_screen.dart';
import 'package:teams_chat/presentation/features/chat/screens/chat_screen.dart';
import 'package:teams_chat/presentation/features/home/screens/home_screen.dart';

// ---------------------------------------------------------------------------
// Route paths
// ---------------------------------------------------------------------------

abstract class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String chat = '/chat/:roomId';

  static String chatPath(String roomId, {required String roomName}) =>
      '/chat/$roomId?name=${Uri.encodeComponent(roomName)}';
}

// ---------------------------------------------------------------------------
// ChangeNotifier that pings go_router whenever auth state changes
// ---------------------------------------------------------------------------

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Stream<AsyncValue<AuthState>> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final dynamic _sub; // StreamSubscription<AsyncValue<AuthState>>

  @override
  void dispose() {
    (_sub as dynamic).cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(
    ref.watch(authProvider.stream),
  );

  final router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authProvider);

      // While loading the stored session, don't redirect.
      if (authAsync.isLoading) return null;

      final isAuthenticated =
          authAsync.asData?.value.isAuthenticated ?? false;
      final onLoginPage = state.matchedLocation == AppRoutes.login;

      if (!isAuthenticated && !onLoginPage) return AppRoutes.login;
      if (isAuthenticated && onLoginPage) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final roomName =
              state.uri.queryParameters['name'] ?? 'Chat';
          return ChatScreen(roomId: roomId, roomName: roomName);
        },
      ),
    ],
  );

  ref.onDispose(() {
    refreshNotifier.dispose();
    router.dispose();
  });

  return router;
});
