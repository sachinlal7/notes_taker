import 'dart:async';

import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart' as geo;

import '../permissions/permission_service.dart';

enum AppLocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class AppLocation {
  const AppLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.heading,
    this.speed,
    this.timestamp,
    this.address,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final double? heading;
  final double? speed;
  final DateTime? timestamp;
  final AppLocationAddress? address;

  AppLocation copyWith({AppLocationAddress? address}) {
    return AppLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      heading: heading,
      speed: speed,
      timestamp: timestamp,
      address: address ?? this.address,
    );
  }
}

class LocationPermissionResult {
  const LocationPermissionResult({required this.status, this.message});

  final AppLocationPermissionStatus status;
  final String? message;

  bool get isGranted => status == AppLocationPermissionStatus.granted;
}

class AppLocationAddress {
  const AppLocationAddress({
    this.name,
    this.street,
    this.subLocality,
    this.locality,
    this.subAdministrativeArea,
    this.administrativeArea,
    this.postalCode,
    this.country,
  });

  final String? name;
  final String? street;
  final String? subLocality;
  final String? locality;
  final String? subAdministrativeArea;
  final String? administrativeArea;
  final String? postalCode;
  final String? country;

  String get formattedAddress {
    final parts = [
      name,
      street,
      subLocality,
      locality,
      subAdministrativeArea,
      administrativeArea,
      postalCode,
      country,
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();

    return parts.toSet().join(', ');
  }
}

abstract interface class LocationService {
  Stream<AppLocation> get locationStream;

  Future<LocationPermissionResult> ensurePermission();

  Future<AppLocation?> getCurrentLocation({
    bool includeAddress = false,
    String? localeIdentifier,
  });

  Future<AppLocationAddress?> getCurrentAddress({String? localeIdentifier});

  Future<AppLocationAddress?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
    String? localeIdentifier,
  });

  Future<void> start();

  Future<void> stop();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService({
    required PermissionService permissionService,
    geo.LocationSettings? locationSettings,
  }) : _permissionService = permissionService,
       _locationSettings =
           locationSettings ??
           const geo.LocationSettings(
             accuracy: geo.LocationAccuracy.high,
             distanceFilter: 10,
           );

  final PermissionService _permissionService;
  final geo.LocationSettings _locationSettings;
  final StreamController<AppLocation> _locationController =
      StreamController<AppLocation>.broadcast();

  StreamSubscription<geo.Position>? _positionSubscription;

  @override
  Stream<AppLocation> get locationStream => _locationController.stream;

  @override
  Future<LocationPermissionResult> ensurePermission() async {
    final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationPermissionResult(
        status: AppLocationPermissionStatus.serviceDisabled,
        message:
            'Location services are disabled. Please enable location services.',
      );
    }

    final permission = await _permissionService.request(
      AppPermissionType.locationWhenInUse,
    );

    return _mapPermission(permission);
  }

  @override
  Future<AppLocation?> getCurrentLocation({
    bool includeAddress = false,
    String? localeIdentifier,
  }) async {
    final permissionResult = await ensurePermission();
    if (!permissionResult.isGranted) return null;

    final position = await geo.Geolocator.getCurrentPosition(
      locationSettings: _locationSettings,
    );

    final location = _mapPosition(position);
    if (!includeAddress) return location;

    final address = await getAddressFromCoordinates(
      latitude: location.latitude,
      longitude: location.longitude,
      localeIdentifier: localeIdentifier,
    );

    return location.copyWith(address: address);
  }

  @override
  Future<AppLocationAddress?> getCurrentAddress({
    String? localeIdentifier,
  }) async {
    final location = await getCurrentLocation();
    if (location == null) return null;

    return getAddressFromCoordinates(
      latitude: location.latitude,
      longitude: location.longitude,
      localeIdentifier: localeIdentifier,
    );
  }

  @override
  Future<AppLocationAddress?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
    String? localeIdentifier,
  }) async {
    try {
      if (localeIdentifier != null && localeIdentifier.trim().isNotEmpty) {
        await geocoding.setLocaleIdentifier(localeIdentifier.trim());
      }

      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) return null;

      return _mapPlacemark(placemarks.first);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> start() async {
    final permissionResult = await ensurePermission();
    if (!permissionResult.isGranted || _positionSubscription != null) return;

    _positionSubscription = geo.Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(_onPosition);
  }

  @override
  Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  Future<void> openAppSettings() {
    return _permissionService.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() {
    return geo.Geolocator.openLocationSettings();
  }

  void _onPosition(geo.Position position) {
    if (_locationController.isClosed) return;

    _locationController.add(_mapPosition(position));
  }

  LocationPermissionResult _mapPermission(AppPermissionResult permission) {
    return switch (permission.status) {
      AppPermissionStatus.granted ||
      AppPermissionStatus.limited ||
      AppPermissionStatus.provisional => const LocationPermissionResult(
        status: AppLocationPermissionStatus.granted,
      ),
      AppPermissionStatus.denied => LocationPermissionResult(
        status: AppLocationPermissionStatus.denied,
        message: permission.message,
      ),
      AppPermissionStatus.permanentlyDenied ||
      AppPermissionStatus.restricted => LocationPermissionResult(
        status: AppLocationPermissionStatus.deniedForever,
        message: permission.message,
      ),
    };
  }

  AppLocation _mapPosition(geo.Position position) {
    return AppLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      heading: position.heading,
      speed: position.speed,
      timestamp: position.timestamp,
    );
  }

  AppLocationAddress _mapPlacemark(geocoding.Placemark placemark) {
    return AppLocationAddress(
      name: placemark.name,
      street: placemark.street,
      subLocality: placemark.subLocality,
      locality: placemark.locality,
      subAdministrativeArea: placemark.subAdministrativeArea,
      administrativeArea: placemark.administrativeArea,
      postalCode: placemark.postalCode,
      country: placemark.country,
    );
  }
}
