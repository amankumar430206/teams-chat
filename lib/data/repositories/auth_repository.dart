import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teams_chat/data/datasources/local/local_storage.dart';
import 'package:teams_chat/data/datasources/remote/auth_api.dart';
import 'package:teams_chat/data/models/user_model.dart';
import 'package:teams_chat/domain/entities/user_entity.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(localStorageProvider),
  ),
);

class AuthRepository {
  const AuthRepository(this._api, this._storage);
  final AuthApi _api;
  final LocalStorage _storage;

  /// Authenticates the user, persists token + user, and returns the entity.
  Future<UserEntity> login({
    required String username,
    required String password,
  }) async {
    final json = await _api.login(username: username, password: password);

    final token = json['accessToken'] as String? ?? json['token'] as String?;
    if (token == null) {
      throw const Exception('No token in login response');
    }

    await _storage.saveToken(token);
    await _storage.saveUserJson(json);

    return UserModel.fromJson(json);
  }

  /// Returns the currently stored user, or null if not logged in.
  UserEntity? getStoredUser() {
    final raw = _storage.getUserJson();
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Clears all auth data from local storage.
  Future<void> logout() => _storage.clearAll();

  bool get isLoggedIn => _storage.getToken() != null;
}
