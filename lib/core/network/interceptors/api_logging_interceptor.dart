import 'package:dio/dio.dart';

import '../../monitoring/logger.dart';

class ApiLoggingInterceptor extends Interceptor {
  ApiLoggingInterceptor(this._logger);

  static const String _logTag = 'API';

  final Logger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['startedAt'] = DateTime.now();
    _logger.info(
      'Request started',
      tag: _logTag,
      data: {
        'method': options.method,
        'path': options.path,
        'queryKeys': options.queryParameters.keys.join(','),
      },
    );

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.info(
      'Request completed',
      tag: _logTag,
      data: {
        'method': response.requestOptions.method,
        'path': response.requestOptions.path,
        'statusCode': response.statusCode,
        'durationMs': _durationMs(response.requestOptions),
      },
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.warning(
      'Request failed',
      tag: _logTag,
      data: {
        'method': err.requestOptions.method,
        'path': err.requestOptions.path,
        'statusCode': err.response?.statusCode,
        'type': err.type.name,
        'durationMs': _durationMs(err.requestOptions),
      },
    );

    handler.next(err);
  }

  int? _durationMs(RequestOptions options) {
    final startedAt = options.extra['startedAt'];
    if (startedAt is! DateTime) return null;

    return DateTime.now().difference(startedAt).inMilliseconds;
  }
}
