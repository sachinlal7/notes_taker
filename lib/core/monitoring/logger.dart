import 'package:flutter/foundation.dart';

enum LogLevel {
  debug('DEBUG'),
  info('INFO'),
  warning('WARN'),
  error('ERROR');

  const LogLevel(this.label);

  final String label;
}

class Logger {
  const Logger({this.enabled = kDebugMode, this.includeTimestamp = true});

  final bool enabled;
  final bool includeTimestamp;

  void debug(String message, {String? tag, Map<String, Object?>? data}) {
    _write(LogLevel.debug, message, tag: tag, data: data);
  }

  void info(String message, {String? tag, Map<String, Object?>? data}) {
    _write(LogLevel.info, message, tag: tag, data: data);
  }

  void warning(String message, {String? tag, Map<String, Object?>? data}) {
    _write(LogLevel.warning, message, tag: tag, data: data);
  }

  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    _write(LogLevel.error, message, tag: tag, data: data);

    if (error != null) {
      _write(LogLevel.error, 'Cause: $error', tag: tag);
    }

    if (stackTrace != null) {
      _write(LogLevel.error, stackTrace.toString(), tag: tag);
    }
  }

  void _write(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, Object?>? data,
  }) {
    if (!enabled) return;

    final parts = <String>[
      if (includeTimestamp) DateTime.now().toIso8601String(),
      level.label,
      if (tag != null && tag.trim().isNotEmpty) tag.trim(),
      _redactText(message),
      if (data != null && data.isNotEmpty) _formatData(data),
    ];

    debugPrint(parts.map((part) => '[$part]').join(' '));
  }

  String _formatData(Map<String, Object?> data) {
    final sanitizedData = data.map(
      (key, value) => MapEntry(key, _sanitizeValue(key, value)),
    );

    return sanitizedData.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
  }

  Object? _sanitizeValue(String key, Object? value) {
    if (_isSensitiveKey(key)) return '[REDACTED]';
    if (value == null) return null;

    return _redactText(value.toString());
  }

  String _redactText(String value) {
    return value
        .replaceAll(_bearerTokenPattern, 'Bearer [REDACTED]')
        .replaceAllMapped(_keyValuePattern, (match) {
          final key = match.group(1) ?? '';
          final separator = match.group(2) ?? '=';

          return '$key$separator[REDACTED]';
        })
        .replaceAllMapped(_jsonKeyValuePattern, (match) {
          final key = match.group(1) ?? '';
          final separator = match.group(2) ?? ':';

          return '"$key"$separator"[REDACTED]"';
        });
  }

  bool _isSensitiveKey(String key) {
    return _sensitiveKeys.contains(key.trim().toLowerCase());
  }

  static const Set<String> _sensitiveKeys = {
    'token',
    'accesstoken',
    'access_token',
    'refreshtoken',
    'refresh_token',
    'password',
    'otp',
    'secret',
    'apikey',
    'api_key',
    'authorization',
    'auth',
    'cookie',
    'session',
  };

  static final RegExp _bearerTokenPattern = RegExp(
    r'Bearer\s+[A-Za-z0-9._~+/=-]+',
    caseSensitive: false,
  );

  static final RegExp _keyValuePattern = RegExp(
    r'\b(token|accessToken|access_token|refreshToken|refresh_token|password|otp|secret|apiKey|api_key|authorization|auth|cookie|session)\b\s*(:|=)\s*[^,\s]+',
    caseSensitive: false,
  );

  static final RegExp _jsonKeyValuePattern = RegExp(
    r'"(token|accessToken|access_token|refreshToken|refresh_token|password|otp|secret|apiKey|api_key|authorization|auth|cookie|session)"\s*(:)\s*"[^"]*"',
    caseSensitive: false,
  );
}
