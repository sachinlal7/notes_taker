import 'dart:async';

import 'package:dio/dio.dart';

import '../../monitoring/logger.dart';

typedef UnauthorizedSessionHandler = Future<void> Function();

class SessionInterceptor extends Interceptor {
  SessionInterceptor({
    required UnauthorizedSessionHandler onUnauthorized,
    required Logger logger,
  }) : _onUnauthorized = onUnauthorized,
       _logger = logger;

  static const String _logTag = 'Session';

  final UnauthorizedSessionHandler _onUnauthorized;
  final Logger _logger;
  Future<void>? _pendingUnauthorizedHandling;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _logger.warning(
        'Unauthorized response received',
        tag: _logTag,
        data: {
          'path': err.requestOptions.path,
          'method': err.requestOptions.method,
        },
      );
      _pendingUnauthorizedHandling ??= _handleUnauthorized();
    }

    handler.next(err);
  }

  Future<void> _handleUnauthorized() async {
    try {
      await _onUnauthorized();
    } finally {
      _pendingUnauthorizedHandling = null;
    }
  }
}
