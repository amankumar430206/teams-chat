import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teams_chat/core/constants/api_constants.dart';
import 'package:teams_chat/core/constants/app_constants.dart';
import 'package:teams_chat/core/errors/app_exception.dart';
import 'package:teams_chat/core/network/dio_client.dart';

final usersApiProvider = Provider<UsersApi>(
  (ref) => UsersApi(ref.watch(dioClientProvider)),
);

class UsersApi {
  const UsersApi(this._dio);
  final Dio _dio;

  /// GET /users?limit=20&skip=0 — returns the 'users' list from DummyJSON.
  Future<List<Map<String, dynamic>>> fetchUsers({
    int limit = AppConstants.usersPageSize,
    int skip = 0,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.usersEndpoint,
        queryParameters: {'limit': limit, 'skip': skip},
      );
      final data = response.data;
      if (data == null) throw const ParseException('Empty users response');
      final users = data['users'] as List<dynamic>?;
      if (users == null) throw const ParseException('Missing users field');
      return users.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : const NetworkException('Failed to load users');
    }
  }
}

