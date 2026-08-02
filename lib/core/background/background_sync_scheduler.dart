import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../app/injection_container.dart';
import '../../features/notes/data/notes_repository.dart';
import '../env/env_loader.dart';

const _notesSyncTask = 'notes.sync';
const _notesSyncOnce = 'notes.sync.once';
const _notesSyncPeriodic = 'notes.sync.periodic';
const _environmentFileKey = 'background.environmentFile';

@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _notesSyncTask && task != Workmanager.iOSBackgroundTask) {
      return true;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      final environmentFile =
          inputData?[_environmentFileKey] as String? ??
          preferences.getString(_environmentFileKey) ??
          '.env.staging';
      final config = await EnvLoader.load(fileName: environmentFile);
      await initializeDependencies(config: config);
      return await sl<NotesRepository>().sync();
    } on Object {
      return false;
    } finally {
      await disposeDependencies();
    }
  });
}

class BackgroundSyncScheduler {
  BackgroundSyncScheduler({required this.environmentFile});

  final String environmentFile;

  Future<bool> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_environmentFileKey, environmentFile);
      await Workmanager().initialize(backgroundSyncDispatcher);
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> schedule() {
    return Workmanager().registerOneOffTask(
      _notesSyncOnce,
      _notesSyncTask,
      inputData: {_environmentFileKey: environmentFile},
      initialDelay: const Duration(seconds: 30),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );
  }

  Future<void> registerPeriodicSync() async {
    if (!Platform.isAndroid) return;

    await Workmanager().registerPeriodicTask(
      _notesSyncPeriodic,
      _notesSyncTask,
      frequency: const Duration(hours: 1),
      initialDelay: const Duration(hours: 1),
      inputData: {_environmentFileKey: environmentFile},
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );
  }
}
