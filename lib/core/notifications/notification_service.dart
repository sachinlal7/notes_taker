import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../monitoring/logger.dart';
import '../permissions/permission_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

enum AppNotificationAppState { foreground, background, terminated }

class AppPushToken {
  const AppPushToken({this.fcmToken, this.apnsToken});

  final String? fcmToken;
  final String? apnsToken;
}

class AppNotificationMessage {
  const AppNotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.appState,
  });

  final String? id;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final AppNotificationAppState appState;
}

abstract interface class NotificationService {
  Stream<AppNotificationMessage> get foregroundMessages;

  Stream<AppNotificationMessage> get openedMessages;

  Future<void> initialize();

  Future<AppPermissionResult> requestPermission();

  Future<AppPushToken> getPushToken();

  Future<String?> getFcmToken();

  Future<String?> getApnsToken();

  Future<AppNotificationMessage?> getInitialMessage();

  Future<void> deleteToken();
}

class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
    PermissionService permissionService = const PermissionHandlerService(),
    Logger logger = const Logger(),
  }) : _firebaseMessaging = firebaseMessaging,
       _localNotificationsPlugin =
           localNotificationsPlugin ?? FlutterLocalNotificationsPlugin(),
       _permissionService = permissionService,
       _logger = logger;

  static const String _logTag = 'Notifications';
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_notifications',
        'High Importance Notifications',
        description: 'Important push notifications',
        importance: Importance.high,
      );

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;
  final PermissionService _permissionService;
  final Logger _logger;
  final StreamController<AppNotificationMessage> _foregroundController =
      StreamController<AppNotificationMessage>.broadcast();
  final StreamController<AppNotificationMessage> _openedController =
      StreamController<AppNotificationMessage>.broadcast();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  @override
  Stream<AppNotificationMessage> get foregroundMessages =>
      _foregroundController.stream;

  @override
  Stream<AppNotificationMessage> get openedMessages => _openedController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await Firebase.initializeApp();
      final firebaseMessaging =
          _firebaseMessaging ?? FirebaseMessaging.instance;
      _firebaseMessaging = firebaseMessaging;
      await requestPermission();
      await _initializeLocalNotifications();
      await firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _listenForMessages();
      _listenForTokenRefresh(firebaseMessaging);
      _initialized = true;
      _logger.info('Notification service initialized', tag: _logTag);
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Notification service initialization skipped',
        tag: _logTag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<AppPermissionResult> requestPermission() async {
    final firebaseMessaging = _firebaseMessaging;
    if (firebaseMessaging == null) {
      _logger.warning(
        'Notification permission request skipped before initialization',
        tag: _logTag,
      );
      return const AppPermissionResult(status: AppPermissionStatus.denied);
    }

    final permission = await _permissionService.request(
      AppPermissionType.notification,
    );

    await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _logger.info(
      'Notification permission requested',
      tag: _logTag,
      data: {'status': permission.status.name},
    );
    return permission;
  }

  @override
  Future<AppPushToken> getPushToken() async {
    return AppPushToken(
      fcmToken: await getFcmToken(),
      apnsToken: await getApnsToken(),
    );
  }

  @override
  Future<String?> getFcmToken() async {
    final firebaseMessaging = _firebaseMessaging;
    if (firebaseMessaging == null) {
      _logger.warning(
        'FCM token fetch skipped before initialization',
        tag: _logTag,
      );
      return null;
    }

    final token = await firebaseMessaging.getToken();
    _logger.info(
      'FCM token fetched',
      tag: _logTag,
      data: {'hasToken': token != null && token.isNotEmpty},
    );
    return token;
  }

  @override
  Future<String?> getApnsToken() async {
    if (!Platform.isIOS && !Platform.isMacOS) return null;

    final firebaseMessaging = _firebaseMessaging;
    if (firebaseMessaging == null) {
      _logger.warning(
        'APNs token fetch skipped before initialization',
        tag: _logTag,
      );
      return null;
    }

    final token = await firebaseMessaging.getAPNSToken();
    _logger.info(
      'APNs token fetched',
      tag: _logTag,
      data: {'hasToken': token != null && token.isNotEmpty},
    );
    return token;
  }

  @override
  Future<AppNotificationMessage?> getInitialMessage() async {
    final firebaseMessaging = _firebaseMessaging;
    if (firebaseMessaging == null) {
      _logger.warning(
        'Initial notification fetch skipped before initialization',
        tag: _logTag,
      );
      return null;
    }

    final message = await firebaseMessaging.getInitialMessage();
    if (message == null) return null;

    final appMessage = _mapMessage(message, AppNotificationAppState.terminated);
    _logger.info(
      'Initial notification opened',
      tag: _logTag,
      data: {'messageId': appMessage.id},
    );
    return appMessage;
  }

  @override
  Future<void> deleteToken() async {
    final firebaseMessaging = _firebaseMessaging;
    if (firebaseMessaging == null) {
      _logger.warning(
        'FCM token delete skipped before initialization',
        tag: _logTag,
      );
      return;
    }

    await firebaseMessaging.deleteToken();
    _logger.info('FCM token deleted', tag: _logTag);
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    await _foregroundController.close();
    await _openedController.close();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  void _listenForMessages() {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      final appMessage = _mapMessage(
        message,
        AppNotificationAppState.foreground,
      );
      _foregroundController.add(appMessage);
      _logger.info(
        'Foreground notification received',
        tag: _logTag,
        data: {'messageId': appMessage.id},
      );
      unawaited(_showForegroundNotification(message));
    });

    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      final appMessage = _mapMessage(
        message,
        AppNotificationAppState.background,
      );
      _openedController.add(appMessage);
      _logger.info(
        'Background notification opened',
        tag: _logTag,
        data: {'messageId': appMessage.id},
      );
    });
  }

  void _listenForTokenRefresh(FirebaseMessaging firebaseMessaging) {
    _tokenRefreshSubscription = firebaseMessaging.onTokenRefresh.listen((
      token,
    ) {
      _logger.info(
        'FCM token refreshed',
        tag: _logTag,
        data: {'hasToken': token.isNotEmpty},
      );
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.messageId,
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    _logger.info(
      'Local notification tapped',
      tag: _logTag,
      data: {'payload': response.payload},
    );
  }

  AppNotificationMessage _mapMessage(
    RemoteMessage message,
    AppNotificationAppState appState,
  ) {
    return AppNotificationMessage(
      id: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
      appState: appState,
    );
  }
}
