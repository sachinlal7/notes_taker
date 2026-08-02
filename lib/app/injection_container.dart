import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/location/location_service.dart';
import '../core/monitoring/logger.dart';
import '../core/network/api_client.dart';
import '../core/network/dio_client.dart';
import '../core/network/interceptors/api_logging_interceptor.dart';
import '../core/network/interceptors/auth_interceptor.dart';
import '../core/network/interceptors/session_interceptor.dart';
import '../core/network/network_info.dart';
// import '../core/notifications/notification_service.dart'; // Firebase not configured yet
import '../core/permissions/permission_service.dart';
import '../core/realtime/socket_event_router.dart';
import '../core/realtime/websocket_service.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/storage_keys.dart';
import '../core/auth/token_manager.dart';
import 'app_config.dart';
import 'app_router.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies({required AppConfig config}) async {
  final sharedPreferences = await SharedPreferences.getInstance();

  sl
    ..registerSingleton<AppConfig>(config)
    ..registerLazySingleton<Logger>(() => Logger(enabled: config.enableLogging))
    ..registerLazySingleton<SharedPreferences>(() => sharedPreferences)
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    )
    ..registerLazySingleton<LocalStorage>(
      () => SharedPreferencesLocalStorage(sl()),
    )
    ..registerLazySingleton<SecureStorage>(
      () => FlutterSecureStorageService(sl()),
    )
    ..registerLazySingleton<TokenManager>(() => TokenManager(sl()))
    ..registerLazySingleton<Dio>(() {
      final dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
        ),
      );

      dio.interceptors.addAll([
        AuthInterceptor(sl()),
        ApiLoggingInterceptor(sl()),
        SessionInterceptor(
          logger: sl(),
          onUnauthorized: _handleUnauthorizedSession,
        ),
      ]);

      return dio;
    })
    ..registerLazySingleton<NetworkInfo>(() => InternetConnectionNetworkInfo())
    ..registerLazySingleton<ApiClient>(() => DioClient(sl(), sl()))
    ..registerLazySingleton<PermissionService>(
      () => const PermissionHandlerService(),
    )
    ..registerLazySingleton<LocationService>(
      () => GeolocatorLocationService(permissionService: sl()),
    )
    ..registerLazySingleton<SocketEventRouter>(
      () => SocketEventRouter(logger: sl()),
    )
    ..registerLazySingleton<WebSocketService>(
      () => AppWebSocketService(
        socketUrl: config.socketUrl,
        logger: sl(),
        eventRouter: sl(),
        onUnauthorized: _handleUnauthorizedSession,
      ),
    );
    // ..registerLazySingleton<NotificationService>(
    //   () => FirebaseNotificationService(permissionService: sl(), logger: sl()),
    // );

  // await sl<NotificationService>().initialize(); // Firebase not configured yet
}

Future<void> _handleUnauthorizedSession() async {
  sl<Logger>().warning('Clearing expired session', tag: 'Session');
  await sl<WebSocketService>().disconnect();
  await sl<TokenManager>().clearSession();
  await sl<LocalStorage>().clearExcept(StorageKeys.logoutPreservedKeys);
  AppRouter.goToLogin();
}
