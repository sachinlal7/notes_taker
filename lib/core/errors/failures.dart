sealed class Failure {
  const Failure(this.message);

  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Unable to process request. Please try again.',
  ]);
}

class ApiServerUnavailableFailure extends Failure {
  const ApiServerUnavailableFailure([
    super.message = 'Unable to process request. Please try again.',
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        'No internet connection. Please check your network and try again.',
  ]);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Network is slow. Please try again.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}

class SocketUnavailableFailure extends Failure {
  const SocketUnavailableFailure([
    super.message = 'Live updates are temporarily unavailable.',
  ]);
}

class SocketReconnectingFailure extends Failure {
  const SocketReconnectingFailure([
    super.message = 'Reconnecting to live updates...',
  ]);
}
