import 'package:flutter/widgets.dart';

class AppLifecycleService with WidgetsBindingObserver {
  AppLifecycleService({this.onPaused, this.onResumed});

  final VoidCallback? onPaused;
  final VoidCallback? onResumed;

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        onPaused?.call();
      case AppLifecycleState.resumed:
        onResumed?.call();
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break;
    }
  }
}
