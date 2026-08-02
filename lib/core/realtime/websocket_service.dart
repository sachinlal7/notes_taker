import 'dart:async';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../errors/exceptions.dart';
import '../monitoring/logger.dart';
import 'socket_error_mapper.dart';
import 'socket_event_router.dart';
import 'socket_message.dart';
import 'socket_status.dart';

typedef SocketUnauthorizedHandler = Future<void> Function();
typedef SocketResyncHandler = Future<void> Function();
typedef SocketHeartbeatFactory = SocketMessage Function();

abstract interface class WebSocketService {
  Stream<SocketStatus> get status;

  Stream<SocketMessage> get messages;

  Future<void> connect(String token);

  Future<void> disconnect({bool manual = true});

  Future<void> send(SocketMessage message);

  Future<void> dispose();
}

class AppWebSocketService implements WebSocketService {
  AppWebSocketService({
    required String socketUrl,
    required Logger logger,
    required SocketEventRouter eventRouter,
    SocketUnauthorizedHandler? onUnauthorized,
    SocketResyncHandler? onReconnectResync,
    SocketHeartbeatFactory? heartbeatFactory,
    Duration? heartbeatInterval,
    Duration reconnectInitialDelay = const Duration(seconds: 1),
    Duration reconnectMaxDelay = const Duration(seconds: 30),
    int maxReconnectAttempts = 5,
    int maxQueuedMessages = 50,
  }) : _socketUrl = socketUrl,
       _logger = logger,
       _eventRouter = eventRouter,
       _onUnauthorized = onUnauthorized,
       _onReconnectResync = onReconnectResync,
       _heartbeatFactory = heartbeatFactory,
       _heartbeatInterval = heartbeatInterval,
       _reconnectInitialDelay = reconnectInitialDelay,
       _reconnectMaxDelay = reconnectMaxDelay,
       _maxReconnectAttempts = maxReconnectAttempts,
       _maxQueuedMessages = maxQueuedMessages;

  static const String _logTag = 'WebSocket';
  static const Set<String> _authFailureEvents = {
    'auth_failed',
    'unauthorized',
    'session_expired',
  };
  static const Set<int> _authFailureCloseCodes = {4001, 4003, 4401, 4403};

  final String _socketUrl;
  final Logger _logger;
  final SocketEventRouter _eventRouter;
  final SocketUnauthorizedHandler? _onUnauthorized;
  final SocketResyncHandler? _onReconnectResync;
  final SocketHeartbeatFactory? _heartbeatFactory;
  final Duration? _heartbeatInterval;
  final Duration _reconnectInitialDelay;
  final Duration _reconnectMaxDelay;
  final int _maxReconnectAttempts;
  final int _maxQueuedMessages;
  final StreamController<SocketStatus> _statusController =
      StreamController<SocketStatus>.broadcast();
  final StreamController<SocketMessage> _messageController =
      StreamController<SocketMessage>.broadcast();
  final List<SocketMessage> _queuedMessages = [];

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  SocketStatus _status = SocketStatus.disconnected;
  String? _lastToken;
  bool _manualDisconnect = false;
  bool _disposed = false;
  bool _handlingUnauthorized = false;
  int _reconnectAttempt = 0;

  @override
  Stream<SocketStatus> get status => _statusController.stream;

  @override
  Stream<SocketMessage> get messages => _messageController.stream;

  @override
  Future<void> connect(String token) async {
    if (_disposed) return;
    if (_status == SocketStatus.connected ||
        _status == SocketStatus.connecting) {
      _logger.debug(
        'Socket connect skipped',
        tag: _logTag,
        data: {'status': _status.name},
      );
      return;
    }

    _lastToken = token;
    _manualDisconnect = false;
    _reconnectAttempt = 0;
    await _connectInternal(token, reconnecting: false);
  }

  @override
  Future<void> send(SocketMessage message) async {
    if (!message.isValid) {
      final failure = SocketErrorMapper.map(
        const SocketMalformedMessageException(),
      );
      _logger.warning(
        'Socket send skipped because message is invalid',
        tag: _logTag,
        data: {'reason': failure.message},
      );
      return;
    }

    final channel = _channel;
    if (channel == null || !_status.canSend) {
      _queueMessage(message);
      _logger.warning(
        'Socket send queued because socket is not connected',
        tag: _logTag,
        data: {'event': message.event, 'status': _status.name},
      );
      return;
    }

    _sendNow(message);
  }

  @override
  Future<void> disconnect({bool manual = true}) async {
    _manualDisconnect = manual;
    _cancelReconnect();
    _stopHeartbeat();
    _logger.info(
      'Socket disconnecting',
      tag: _logTag,
      data: {'manual': manual},
    );

    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setStatus(SocketStatus.disconnected);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _queuedMessages.clear();
    await disconnect();
    await _statusController.close();
    await _messageController.close();
  }

  Future<void> _connectInternal(
    String token, {
    required bool reconnecting,
  }) async {
    _setStatus(
      reconnecting ? SocketStatus.reconnecting : SocketStatus.connecting,
    );
    _logger.info(
      reconnecting ? 'Socket reconnecting' : 'Socket connecting',
      tag: _logTag,
      data: reconnecting ? {'attempt': _reconnectAttempt} : null,
    );

    try {
      final uri = _buildUri(token);
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;

      _channel = channel;
      _subscription = channel.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _reconnectAttempt = 0;
      _setStatus(SocketStatus.connected);
      _startHeartbeat();
      _flushQueuedMessages();
      _logger.info('Socket connected', tag: _logTag);

      if (reconnecting) {
        await _onReconnectResync?.call();
      }
    } on Object catch (error, stackTrace) {
      final socketException = SocketErrorMapper.toException(error);
      _setStatus(SocketStatus.failed);
      _logger.error(
        'Socket connection failed',
        tag: _logTag,
        error: socketException.message,
        stackTrace: stackTrace,
      );
      _scheduleReconnect();
      throw socketException;
    }
  }

  Uri _buildUri(String token) {
    final uri = Uri.parse(_socketUrl);

    // The cross-platform web_socket_channel API does not expose headers.
    // Prefer token headers if the backend/client transport later supports them.
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'token': token},
    );
  }

  void _sendNow(SocketMessage message) {
    _logger.debug(
      'Socket event sent',
      tag: _logTag,
      data: {'event': message.event},
    );
    _channel!.sink.add(message.encode());
  }

  void _queueMessage(SocketMessage message) {
    if (_queuedMessages.length >= _maxQueuedMessages) {
      _queuedMessages.removeAt(0);
    }
    _queuedMessages.add(message);
  }

  void _flushQueuedMessages() {
    if (_queuedMessages.isEmpty || !_status.canSend) return;

    final messages = List<SocketMessage>.from(_queuedMessages);
    _queuedMessages.clear();
    _logger.debug(
      'Socket queued messages flushing',
      tag: _logTag,
      data: {'count': messages.length},
    );
    for (final message in messages) {
      _sendNow(message);
    }
  }

  Future<void> _onMessage(dynamic rawMessage) async {
    final message = SocketMessage.tryParse(rawMessage);
    if (message == null) {
      final failure = SocketErrorMapper.map(
        const SocketMalformedMessageException(),
      );
      _logger.warning(
        'Socket message ignored',
        tag: _logTag,
        data: {'reason': failure.message},
      );
      return;
    }

    if (_authFailureEvents.contains(message.event)) {
      await _handleUnauthorized();
      return;
    }

    _logger.debug(
      'Socket event received',
      tag: _logTag,
      data: {'event': message.event},
    );
    _messageController.add(message);
    await _eventRouter.route(message);
  }

  void _onError(Object error, StackTrace stackTrace) {
    final failure = SocketErrorMapper.map(error);
    _logger.error(
      'Socket error',
      tag: _logTag,
      error: failure.message,
      stackTrace: stackTrace,
    );
  }

  void _onDone() {
    final closeCode = _channel?.closeCode;
    final isAuthFailure =
        closeCode != null && _authFailureCloseCodes.contains(closeCode);
    final failure = SocketErrorMapper.map(
      isAuthFailure
          ? const SocketAuthException()
          : _manualDisconnect
          ? const SocketDisconnectedException()
          : const SocketReconnectingException(),
    );

    _logger.info(
      'Socket disconnected',
      tag: _logTag,
      data: {
        'manual': _manualDisconnect,
        'closeCode': closeCode,
        'message': failure.message,
      },
    );

    _channel = null;
    _subscription = null;
    _stopHeartbeat();

    if (isAuthFailure) {
      unawaited(_handleUnauthorized());
      return;
    }

    _setStatus(SocketStatus.disconnected);
    if (!_manualDisconnect) {
      _scheduleReconnect();
    }
  }

  Future<void> _handleUnauthorized() async {
    if (_handlingUnauthorized) return;

    _handlingUnauthorized = true;
    _setStatus(SocketStatus.authFailed);
    _logger.warning('Socket authentication failed', tag: _logTag);

    try {
      await _onUnauthorized?.call();
    } finally {
      _handlingUnauthorized = false;
    }
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _disposed) return;
    final token = _lastToken;
    if (token == null || token.trim().isEmpty) return;
    if (_reconnectTimer != null) return;

    if (_reconnectAttempt >= _maxReconnectAttempts) {
      _setStatus(SocketStatus.failed);
      _logger.error(
        'Socket reconnect attempts exhausted',
        tag: _logTag,
        data: {'attempts': _reconnectAttempt},
      );
      return;
    }

    _reconnectAttempt++;
    final delay = _nextReconnectDelay();
    _setStatus(SocketStatus.reconnecting);
    _logger.info(
      'Socket reconnect scheduled',
      tag: _logTag,
      data: {'attempt': _reconnectAttempt, 'delayMs': delay.inMilliseconds},
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(_connectInternal(token, reconnecting: true));
    });
  }

  Duration _nextReconnectDelay() {
    final multiplier = pow(2, _reconnectAttempt - 1).toInt();
    final delayMs = _reconnectInitialDelay.inMilliseconds * multiplier;

    return Duration(
      milliseconds: min(delayMs, _reconnectMaxDelay.inMilliseconds),
    );
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
  }

  void _startHeartbeat() {
    final interval = _heartbeatInterval;
    final heartbeatFactory = _heartbeatFactory;
    if (interval == null || heartbeatFactory == null) return;

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(interval, (_) {
      if (_status.canSend) {
        unawaited(send(heartbeatFactory()));
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _setStatus(SocketStatus status) {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
