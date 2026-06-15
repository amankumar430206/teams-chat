/// Typed exceptions thrown by the data layer and caught in providers.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// HTTP / REST errors (non-2xx responses, timeouts, no internet).
final class NetworkException extends AppException {
  const NetworkException(super.message, {this.statusCode});
  final int? statusCode;
}

/// Credentials rejected by the server (HTTP 401/403).
final class AuthException extends AppException {
  const AuthException(super.message);
}

/// Returned data could not be parsed into the expected shape.
final class ParseException extends AppException {
  const ParseException(super.message);
}

/// WebSocket connection or send error.
final class WebSocketException extends AppException {
  const WebSocketException(super.message);
}

/// Generic catch-all for unexpected errors.
final class UnknownException extends AppException {
  const UnknownException(super.message);
}
