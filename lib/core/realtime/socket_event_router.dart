import '../errors/exceptions.dart';
import '../errors/failures.dart';
import '../monitoring/logger.dart';
import 'socket_error_mapper.dart';
import 'socket_message.dart';

typedef SocketEventHandler = Future<void> Function(SocketMessage message);

class SocketEventRouter {
  SocketEventRouter({Logger logger = const Logger()}) : _logger = logger;

  static const String _logTag = 'SocketEventRouter';

  final Logger _logger;
  final Map<String, SocketEventHandler> _handlers = {};

  bool hasHandler(String event) {
    return _handlers.containsKey(_normalizeEvent(event));
  }

  void register(
    String event,
    SocketEventHandler handler, {
    bool replace = false,
  }) {
    final normalizedEvent = _normalizeEvent(event);
    if (normalizedEvent.isEmpty) {
      _logger.warning('Socket event registration ignored', tag: _logTag);
      return;
    }

    if (_handlers.containsKey(normalizedEvent) && !replace) {
      _logger.warning(
        'Duplicate socket event handler ignored',
        tag: _logTag,
        data: {'event': normalizedEvent},
      );
      return;
    }

    _handlers[normalizedEvent] = handler;
    _logger.debug(
      'Socket event handler registered',
      tag: _logTag,
      data: {'event': normalizedEvent, 'replace': replace},
    );
  }

  void unregister(String event) {
    final normalizedEvent = _normalizeEvent(event);
    final removedHandler = _handlers.remove(normalizedEvent);

    if (removedHandler == null) {
      _logger.debug(
        'Socket event handler unregister skipped',
        tag: _logTag,
        data: {'event': normalizedEvent},
      );
      return;
    }

    _logger.debug(
      'Socket event handler unregistered',
      tag: _logTag,
      data: {'event': normalizedEvent},
    );
  }

  void clear() {
    final count = _handlers.length;
    _handlers.clear();
    _logger.debug(
      'Socket event handlers cleared',
      tag: _logTag,
      data: {'count': count},
    );
  }

  Future<Failure?> route(SocketMessage message) async {
    final normalizedEvent = _normalizeEvent(message.event);
    if (normalizedEvent.isEmpty) {
      final failure = SocketErrorMapper.map(
        const SocketMalformedMessageException(),
      );
      _logger.warning(
        'Socket event ignored',
        tag: _logTag,
        data: {'reason': failure.message},
      );
      return failure;
    }

    final handler = _handlers[normalizedEvent];
    if (handler == null) {
      final failure = SocketErrorMapper.map(
        const SocketUnknownEventException(),
      );
      _logger.warning(
        'Unknown socket event ignored',
        tag: _logTag,
        data: {'event': normalizedEvent, 'reason': failure.message},
      );
      return failure;
    }

    try {
      await handler(
        SocketMessage(event: normalizedEvent, payload: message.payload),
      );
      _logger.debug(
        'Socket event routed',
        tag: _logTag,
        data: {'event': normalizedEvent},
      );
      return null;
    } on Object catch (error, stackTrace) {
      final failure = SocketErrorMapper.map(error);
      _logger.error(
        'Socket event handler failed',
        tag: _logTag,
        error: failure.message,
        stackTrace: stackTrace,
        data: {'event': normalizedEvent},
      );
      return failure;
    }
  }

  String _normalizeEvent(String event) {
    return event.trim();
  }
}
