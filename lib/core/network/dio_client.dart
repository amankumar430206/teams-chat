import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teams_chat/core/constants/api_constants.dart';
import 'package:teams_chat/core/constants/storage_keys.dart';
import 'package:teams_chat/core/errors/app_exception.dart';
import 'package:teams_chat/data/datasources/local/local_storage.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dioClientProvider = Provider<Dio>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout:
          const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout:
          const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Injects the stored Bearer token on every request.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = prefs.getString(StorageKeys.authToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(_mapDioError(error));
      },
    ),
  );

  return dio;
});

// ---------------------------------------------------------------------------
// Error mapping — converts Dio errors into typed [AppException]s
// ---------------------------------------------------------------------------

DioException _mapDioError(DioException error) {
  final appEx = switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout =>
      const NetworkException('Request timed out. Check your connection.'),
    DioExceptionType.connectionError =>
      const NetworkException('No internet connection.'),
    DioExceptionType.badResponse => _fromStatusCode(
        error.response?.statusCode,
        error.response?.data,
      ),
    _ => const UnknownException('An unexpected error occurred.'),
  };

  // Wrap in a DioException so callers can still catch DioException if needed,
  // but the error field carries our typed exception.
  return DioException(
    requestOptions: error.requestOptions,
    error: appEx,
    type: error.type,
    response: error.response,
  );
}

AppException _fromStatusCode(int? code, dynamic data) {
  final msg = _extractMessage(data);
  return switch (code) {
    400 => NetworkException(msg ?? 'Bad request.', statusCode: 400),
    401 || 403 => AuthException(msg ?? 'Invalid credentials.'),
    404 => NetworkException(msg ?? 'Resource not found.', statusCode: 404),
    500 || 503 => NetworkException(
        msg ?? 'Server error. Please try again.',
        statusCode: code,
      ),
    _ => NetworkException(
        msg ?? 'Something went wrong (HTTP $code).',
        statusCode: code,
      ),
  };
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    return (data['message'] as String?) ??
        (data['error'] as String?);
  }
  return null;
}
