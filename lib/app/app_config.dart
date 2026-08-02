class AppConfig {
  const AppConfig({
    required this.environmentName,
    required this.appName,
    required this.baseUrl,
    required this.socketUrl,
    required this.enableLogging,
    required this.enableCrashReporting,
    this.sentryDsn,
  });

  final String environmentName;
  final String appName;
  final String baseUrl;
  final String socketUrl;
  final bool enableLogging;
  final bool enableCrashReporting;
  final String? sentryDsn;

  factory AppConfig.fromEnv(Map<String, String> env) {
    return AppConfig(
      environmentName: _required(env, 'APP_ENV'),
      appName: _required(env, 'APP_NAME'),
      baseUrl: _required(env, 'BASE_URL'),
      socketUrl: _required(env, 'SOCKET_URL'),
      enableLogging: _bool(env['ENABLE_LOGGING']),
      enableCrashReporting: _bool(env['ENABLE_CRASH_REPORTING']),
      sentryDsn: _optional(env['SENTRY_DSN']),
    );
  }

  factory AppConfig.staging() {
    return const AppConfig(
      environmentName: 'staging',
      appName: 'Notes Taker Staging',
      baseUrl: 'https://staging-api.example.com',
      socketUrl: 'wss://staging-socket.example.com',
      enableLogging: true,
      enableCrashReporting: false,
    );
  }

  factory AppConfig.production() {
    return const AppConfig(
      environmentName: 'production',
      appName: 'Notes Taker',
      baseUrl: 'https://api.example.com',
      socketUrl: 'wss://socket.example.com',
      enableLogging: false,
      enableCrashReporting: true,
    );
  }

  static String _required(Map<String, String> env, String key) {
    final value = env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment value: $key');
    }

    return value;
  }

  static bool _bool(String? value) {
    return value?.trim().toLowerCase() == 'true';
  }

  static String? _optional(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) return null;

    return trimmedValue;
  }
}
