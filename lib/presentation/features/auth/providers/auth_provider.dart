import 'dart:convert';

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
    this.isLoading = false,
  });

  const AuthState.initial()
      : isAuthenticated = false,
        user = null,
        error = null,
        isLoading = false;

  final bool isAuthenticated;
  final UserEntity? user;
  final String? error;
  final bool isLoading;

  AuthState copyWith({
    bool? isAuthenticated,
    UserEntity? user,
    String? error,
    bool? isLoading,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        user: user ?? this.user,
        error: error,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState.initial()) {
    // Restore session from SharedPreferences on cold start.
    _restoreSession();
  }

  final AuthRepository _repo;

  void _restoreSession() {
    if (!_repo.isLoggedIn) return;
    final user = _repo.getStoredUser();
    if (user != null) {
      state = AuthState(isAuthenticated: true, user: user);
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(username: username, password: password);
      state = AuthState(isAuthenticated: true, user: user);
    } on AppException catch (e) {
      state = AuthState(isAuthenticated: false, error: e.message);
    } catch (_) {
      state = const AuthState(isAuthenticated: false, error: 'Login failed');
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.initial();
  }
}
