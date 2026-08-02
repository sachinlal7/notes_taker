import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../app/app_config.dart';

class EnvLoader {
  const EnvLoader._();

  static Future<AppConfig> load({required String fileName}) async {
    await dotenv.load(fileName: fileName);

    return AppConfig.fromEnv(dotenv.env);
  }
}
