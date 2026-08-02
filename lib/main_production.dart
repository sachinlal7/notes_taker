import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'app/bloc_observer.dart';
import 'app/injection_container.dart';
import 'core/env/env_loader.dart';
import 'core/lifecycle/screen_orientation_service.dart';
import 'core/lifecycle/system_ui_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenOrientationService.lockPortrait();
  SystemUiService.applyLightSystemUi();
  Bloc.observer = const AppBlocObserver();

  final config = await EnvLoader.load(fileName: '.env.production');
  await initializeDependencies(config: config);

  runApp(NotesTakerApp(config: config));
}
