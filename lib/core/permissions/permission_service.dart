import 'package:permission_handler/permission_handler.dart' as ph;

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
}

enum AppPermissionType {
  camera,
  microphone,
  locationWhenInUse,
  notification,
  photos,
  videos,
  audio,
  storage,
  contacts,
}

class AppPermissionResult {
  const AppPermissionResult({required this.status, this.message});

  final AppPermissionStatus status;
  final String? message;

  bool get isGranted => status == AppPermissionStatus.granted;

  bool get canOpenSettings =>
      status == AppPermissionStatus.permanentlyDenied ||
      status == AppPermissionStatus.restricted;
}

abstract interface class PermissionService {
  Future<AppPermissionResult> check(AppPermissionType type);

  Future<AppPermissionResult> request(AppPermissionType type);

  Future<Map<AppPermissionType, AppPermissionResult>> requestMany(
    List<AppPermissionType> types,
  );

  Future<bool> openAppSettings();

  Future<bool> hasLocationPermission();

  Future<bool> requestLocationPermission();
}

class PermissionHandlerService implements PermissionService {
  const PermissionHandlerService();

  @override
  Future<AppPermissionResult> check(AppPermissionType type) async {
    final status = await _mapType(type).status;

    return _mapStatus(type, status);
  }

  @override
  Future<AppPermissionResult> request(AppPermissionType type) async {
    final status = await _mapType(type).request();

    return _mapStatus(type, status);
  }

  @override
  Future<Map<AppPermissionType, AppPermissionResult>> requestMany(
    List<AppPermissionType> types,
  ) async {
    final permissions = {for (final type in types) _mapType(type): type};
    final statuses = await permissions.keys.toList().request();

    return {
      for (final entry in statuses.entries)
        permissions[entry.key]!: _mapStatus(
          permissions[entry.key]!,
          entry.value,
        ),
    };
  }

  @override
  Future<bool> openAppSettings() {
    return ph.openAppSettings();
  }

  @override
  Future<bool> hasLocationPermission() async {
    final result = await check(AppPermissionType.locationWhenInUse);

    return result.isGranted;
  }

  @override
  Future<bool> requestLocationPermission() async {
    final result = await request(AppPermissionType.locationWhenInUse);

    return result.isGranted;
  }

  ph.Permission _mapType(AppPermissionType type) {
    return switch (type) {
      AppPermissionType.camera => ph.Permission.camera,
      AppPermissionType.microphone => ph.Permission.microphone,
      AppPermissionType.locationWhenInUse => ph.Permission.locationWhenInUse,
      AppPermissionType.notification => ph.Permission.notification,
      AppPermissionType.photos => ph.Permission.photos,
      AppPermissionType.videos => ph.Permission.videos,
      AppPermissionType.audio => ph.Permission.audio,
      AppPermissionType.storage => ph.Permission.storage,
      AppPermissionType.contacts => ph.Permission.contacts,
    };
  }

  AppPermissionResult _mapStatus(
    AppPermissionType type,
    ph.PermissionStatus status,
  ) {
    return switch (status) {
      ph.PermissionStatus.granted => const AppPermissionResult(
        status: AppPermissionStatus.granted,
      ),
      ph.PermissionStatus.denied => AppPermissionResult(
        status: AppPermissionStatus.denied,
        message: _deniedMessage(type),
      ),
      ph.PermissionStatus.permanentlyDenied => AppPermissionResult(
        status: AppPermissionStatus.permanentlyDenied,
        message: _settingsMessage(type),
      ),
      ph.PermissionStatus.restricted => AppPermissionResult(
        status: AppPermissionStatus.restricted,
        message: _settingsMessage(type),
      ),
      ph.PermissionStatus.limited => const AppPermissionResult(
        status: AppPermissionStatus.limited,
      ),
      ph.PermissionStatus.provisional => const AppPermissionResult(
        status: AppPermissionStatus.provisional,
      ),
    };
  }

  String _deniedMessage(AppPermissionType type) {
    return '${_label(type)} permission is required to use this feature.';
  }

  String _settingsMessage(AppPermissionType type) {
    return '${_label(type)} permission is unavailable. Please enable it from app settings.';
  }

  String _label(AppPermissionType type) {
    return switch (type) {
      AppPermissionType.camera => 'Camera',
      AppPermissionType.microphone => 'Microphone',
      AppPermissionType.locationWhenInUse => 'Location',
      AppPermissionType.notification => 'Notification',
      AppPermissionType.photos => 'Photos',
      AppPermissionType.videos => 'Videos',
      AppPermissionType.audio => 'Audio',
      AppPermissionType.storage => 'Storage',
      AppPermissionType.contacts => 'Contacts',
    };
  }
}
