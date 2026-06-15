import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teams_chat/core/constants/api_constants.dart';
import 'package:teams_chat/core/errors/app_exception.dart';
import 'package:teams_chat/core/network/dio_client.dart';

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioClientProvider)),
);

class AuthApi {
  const AuthApi(this._dio);
  final Dio _dio;

  /// POST /auth/login — returns the raw JSON response map from DummyJSON.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.loginEndpoint,
        data: {
          'username': username,
          'password': password,
          'expiresInMins': 60,
        },
      );
      final data = response.data;
      if (data == null) throw const ParseException('Empty login response');
      return data;
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : const NetworkException('Login request failed');
    }
  }
}
