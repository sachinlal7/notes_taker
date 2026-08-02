import 'exceptions.dart';
import 'failures.dart';

class ErrorMapper {
  const ErrorMapper._();

  static Failure map(Object error) {
    return switch (error) {
      NetworkException() => const NetworkFailure(),
      TimeoutException() => const TimeoutFailure(),
      UnauthorizedException() => const UnauthorizedFailure(),
      ApiServerUnavailableException() => const ApiServerUnavailableFailure(),
      SocketAuthException() => const UnauthorizedFailure(),
      SocketReconnectingException() => const SocketReconnectingFailure(),
      SocketDisconnectedException() => const SocketUnavailableFailure(),
      SocketMalformedMessageException() => const SocketUnavailableFailure(),
      SocketUnknownEventException() => const SocketUnavailableFailure(),
      ServerException() => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }
}
