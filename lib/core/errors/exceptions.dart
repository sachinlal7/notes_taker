sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;
}

class ServerException extends AppException {
  const ServerException([super.message = 'Unable to process request.']);
}

class StorageException extends AppException {
  const StorageException([super.message = 'Unable to access local data.']);
}

class ApiServerUnavailableException extends AppException {
  const ApiServerUnavailableException([
    super.message = 'Unable to process request. Please try again.',
  ]);
}

class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'No internet connection. Please check your network and try again.',
  ]);
}

class TimeoutException extends AppException {
  const TimeoutException([
    super.message = 'Network is slow. Please try again.',
  ]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class SocketDisconnectedException extends AppException {
  const SocketDisconnectedException([
    super.message = 'Live updates are temporarily unavailable.',
  ]);
}

class SocketReconnectingException extends AppException {
  const SocketReconnectingException([
    super.message = 'Reconnecting to live updates...',
  ]);
}

class SocketAuthException extends AppException {
  const SocketAuthException([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class SocketMalformedMessageException extends AppException {
  const SocketMalformedMessageException([
    super.message = 'Live updates are temporarily unavailable.',
  ]);
}

class SocketUnknownEventException extends AppException {
  const SocketUnknownEventException([
    super.message = 'Live updates are temporarily unavailable.',
  ]);
}
