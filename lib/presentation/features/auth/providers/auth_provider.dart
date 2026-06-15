import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teams_chat/core/errors/app_exception.dart';
import 'package:teams_chat/data/repositories/auth_repository.dart';
import 'package:teams_chat/domain/entities/user_entity.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.user,
    this.error,
  });

  const AuthState.initial()
      : isAuthenticated = false,
        user = null,
        error = null;

  final bool isAuthenticated;
  final UserEntity? user;
  final String? error;

  AuthState copyWith({
    bool? isAuthenticated,
    UserEntity? user,
    String? error,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        user: user ?? this.user,
        error: error,
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    if (!repo.isLoggedIn) return const AuthState.initial();

    final user = repo.getStoredUser();
    if (user == null) return const AuthState.initial();

    return AuthState(isAuthenticated: true, user: user);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);
      state = AsyncValue.data(
        AuthState(isAuthenticated: true, user: user),
      );
    } on AppException catch (e) {
      state = AsyncValue.data(
        AuthState(isAuthenticated: false, error: e.message),
      );
    } catch (e) {
      state = AsyncValue.data(
        AuthState(isAuthenticated: false, error: 'Login failed'),
      );
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(AuthState.initial());
  }
}
