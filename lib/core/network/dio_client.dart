import 'package:dio/dio.dart';

import '../errors/exceptions.dart';
import 'api_client.dart';
import 'api_response.dart';
import 'network_info.dart';
import 'request_cancel_token.dart';

class DioClient implements ApiClient {
  DioClient(this._dio, this._networkInfo);

  final Dio _dio;
  final NetworkInfo _networkInfo;

  @override
  Future<ApiResponse<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    RequestCancelToken? cancelToken,
  }) async {
    return _send(
      () => _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        cancelToken: _createDioCancelToken(cancelToken),
      ),
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  }) async {
    return _send(
      () => _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        cancelToken: _createDioCancelToken(cancelToken),
      ),
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> put(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  }) async {
    return _send(
      () => _dio.put<Map<String, dynamic>>(
        path,
        data: body,
        cancelToken: _createDioCancelToken(cancelToken),
      ),
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> patch(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  }) async {
    return _send(
      () => _dio.patch<Map<String, dynamic>>(
        path,
        data: body,
        cancelToken: _createDioCancelToken(cancelToken),
      ),
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> delete(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  }) async {
    return _send(
      () => _dio.delete<Map<String, dynamic>>(
        path,
        data: body,
        cancelToken: _createDioCancelToken(cancelToken),
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> _send(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;

      if (data == null) {
        throw const ServerException('Unable to process request.');
      }

      return ApiResponse(data: data, statusCode: response.statusCode);
    } on DioException catch (error) {
      throw await _mapDioException(error);
    }
  }

  CancelToken? _createDioCancelToken(RequestCancelToken? requestToken) {
    if (requestToken == null) return null;

    final dioCancelToken = CancelToken();
    requestToken.onCancel(() {
      dioCancelToken.cancel('Request cancelled.');
    });

    return dioCancelToken;
  }

  Future<AppException> _mapDioException(DioException error) async {
    if (CancelToken.isCancel(error)) {
      return const ServerException('Request cancelled.');
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const TimeoutException(),
      DioExceptionType.connectionError => const NetworkException(),
      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        const UnauthorizedException(),
      DioExceptionType.badResponse
          when _isServerUnavailableStatus(error.response?.statusCode) =>
        const ApiServerUnavailableException(),
      DioExceptionType.badResponse => const ServerException(),
      DioExceptionType.cancel => const ServerException('Request cancelled.'),
      DioExceptionType.badCertificate => const ApiServerUnavailableException(),
      DioExceptionType.unknown => await _mapUnknownError(),
    };
  }

  bool _isServerUnavailableStatus(int? statusCode) {
    if (statusCode == null) return false;

    return statusCode >= 500 && statusCode <= 599;
  }

  Future<AppException> _mapUnknownError() async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) return const NetworkException();

    return const ApiServerUnavailableException();
  }
}
