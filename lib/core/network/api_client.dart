import 'api_response.dart';
import 'request_cancel_token.dart';

abstract interface class ApiClient {
  Future<ApiResponse<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    RequestCancelToken? cancelToken,
  });

  Future<ApiResponse<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  });

  Future<ApiResponse<Map<String, dynamic>>> put(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  });

  Future<ApiResponse<Map<String, dynamic>>> patch(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  });

  Future<ApiResponse<Map<String, dynamic>>> delete(
    String path, {
    Map<String, dynamic>? body,
    RequestCancelToken? cancelToken,
  });
}
