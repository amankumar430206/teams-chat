/// App-wide scalar constants shared across features.
class AppConstants {
  AppConstants._();

  static const String appName = 'Teams Chat';
  static const String appVersion = '1.0.0';

  // WebSocket reconnect
  static const int wsReconnectDelaySeconds = 3;
  static const int wsMaxReconnectAttempts = 5;

  // Typing indicator
  static const int typingDebounceMs = 500;
  static const int typingClearAfterSeconds = 3;

  // Simulated "other user" activity delays (ms) — demo only
  static const int simulatedTypingDelayMs = 3000;
  static const int simulatedMessageDelayMs = 5500;

  // Message history
  static const int mockHistoryCount = 10;

  // Pagination
  static const int usersPageSize = 20;
}
