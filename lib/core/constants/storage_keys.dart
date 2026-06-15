/// SharedPreferences key strings in one place to prevent typos.
class StorageKeys {
  StorageKeys._();

  static const String authToken = 'auth_token';
  static const String currentUser = 'current_user';
  static const String themeMode = 'theme_mode';

  /// Prefix for cached messages: messages_<roomId>
  static const String messagesPrefix = 'messages_';
}
