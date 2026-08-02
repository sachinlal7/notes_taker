import '../errors/failures.dart';

typedef Result<T> = Future<({Failure? failure, T? data})>;

class ApiResponse<T> {
  const ApiResponse({required this.data, this.statusCode});

  final T data;
  final int? statusCode;
}
