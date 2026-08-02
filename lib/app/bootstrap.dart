import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/background/background_sync_scheduler.dart';
import '../core/env/env_loader.dart';
import '../core/lifecycle/screen_orientation_service.dart';
import '../core/lifecycle/system_ui_service.dart';
import 'app.dart';
import 'bloc_observer.dart';
import 'injection_container.dart';

Future<void> bootstrap({required String environmentFile}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenOrientationService.lockPortrait();
  SystemUiService.applyLightSystemUi();
  Bloc.observer = const AppBlocObserver();

  final config = await EnvLoader.load(fileName: environmentFile);
  final backgroundSync = BackgroundSyncScheduler(
    environmentFile: environmentFile,
  );
  final backgroundSyncReady = await backgroundSync.initialize();
  await initializeDependencies(
    config: config,
    scheduleBackgroundSync: backgroundSyncReady
        ? backgroundSync.schedule
        : null,
  );
  if (backgroundSyncReady) await backgroundSync.registerPeriodicSync();

  runApp(NotesTakerApp(config: config));
}
