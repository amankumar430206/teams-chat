/// All external API endpoints and URLs in one place.
class ApiConstants {
  ApiConstants._();

  // REST — DummyJSON
  static const String baseUrl = 'https://dummyjson.com';
  static const String loginEndpoint = '/auth/login';
  static const String usersEndpoint = '/users';

  // WebSocket — public echo server used for demo delivery confirmation
  static const String wsUrl = 'wss://echo.websocket.events';

  // Demo credentials shown as a hint on the login screen
  static const String demoUsername = 'emilys';
  static const String demoPassword = 'emilyspass';

  // HTTP timeouts (ms)
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;
}
