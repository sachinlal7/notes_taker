import 'dart:async' as async;
import 'dart:io';

import '../errors/error_mapper.dart';
import '../errors/exceptions.dart';
import '../errors/failures.dart';

class SocketErrorMapper {
  const SocketErrorMapper._();

  static Failure map(Object error) {
    return ErrorMapper.map(toException(error));
  }

  static AppException toException(Object error) {
    return switch (error) {
      AppException() => error,
      SocketException() => const NetworkException(),
      async.TimeoutException() => const TimeoutException(),
      FormatException() => const SocketMalformedMessageException(),
      WebSocketException() => const SocketDisconnectedException(),
      _ => const SocketDisconnectedException(),
    };
  }
}
