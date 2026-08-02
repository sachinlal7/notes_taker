import 'api_response.dart';
import 'request_cancel_token.dart';

abstract interface class ApiClient {
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    RequestCancelToken? cancelToken,
  });

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  });

  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  });

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  });

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  });
}
