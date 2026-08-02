import 'package:flutter/services.dart';

class ScreenOrientationService {
  const ScreenOrientationService._();

  static Future<void> lockPortrait() {
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  static Future<void> unlock() {
    return SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }
}
