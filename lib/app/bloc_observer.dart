import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/monitoring/logger.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver({Logger logger = const Logger()}) : _logger = logger;

  final Logger _logger;

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logger.error(
      '${bloc.runtimeType} failed',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
