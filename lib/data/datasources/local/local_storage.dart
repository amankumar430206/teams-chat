import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teams_chat/core/constants/storage_keys.dart';

// ---------------------------------------------------------------------------
// Provider — pre-loaded instance injected from main()
// ---------------------------------------------------------------------------

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // Overridden in main() with the pre-awaited instance.
  throw UnimplementedError('sharedPreferencesProvider not overridden');
});

// ---------------------------------------------------------------------------
// Typed wrapper around SharedPreferences
// ---------------------------------------------------------------------------

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage(ref.watch(sharedPreferencesProvider));
});

class LocalStorage {
  const LocalStorage(this._prefs);
  final SharedPreferences _prefs;

  // Auth
  String? getToken() => _prefs.getString(StorageKeys.authToken);
  Future<void> saveToken(String token) =>
      _prefs.setString(StorageKeys.authToken, token);
  Future<void> clearToken() => _prefs.remove(StorageKeys.authToken);

  // Current user JSON blob
  String? getUserJson() => _prefs.getString(StorageKeys.currentUser);
  Future<void> saveUserJson(Map<String, dynamic> user) =>
      _prefs.setString(StorageKeys.currentUser, jsonEncode(user));
  Future<void> clearUser() => _prefs.remove(StorageKeys.currentUser);

  // Cached messages per room
  Future<void> saveMessages(String roomId, List<Map<String, dynamic>> msgs) =>
      _prefs.setString(
        '${StorageKeys.messagesPrefix}$roomId',
        jsonEncode(msgs),
      );

  List<Map<String, dynamic>>? getMessages(String roomId) {
    final raw = _prefs.getString('${StorageKeys.messagesPrefix}$roomId');
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  // Clear everything (logout)
  Future<void> clearAll() => _prefs.clear();
}
