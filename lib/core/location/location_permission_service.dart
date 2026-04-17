import 'package:geolocator/geolocator.dart';

import 'location_permission_client.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  restricted,
  serviceDisabled,
}

enum LocationPermissionRequestResult {
  granted,
  denied,
  deniedForever,
  restricted,
  serviceDisabled,
}

abstract class LocationPermissionService {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermissionStatus> getPermissionStatus();
  Future<LocationPermissionRequestResult> requestWhileInUsePermission();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class GeolocatorLocationPermissionService implements LocationPermissionService {
  const GeolocatorLocationPermissionService(this._client);

  final LocationPermissionClient _client;

  @override
  Future<bool> isLocationServiceEnabled() {
    return _client.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermissionStatus> getPermissionStatus() async {
    final serviceEnabled = await _client.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    final permission = await _client.checkPermission();
    return _mapPermissionStatus(permission);
  }

  @override
  Future<LocationPermissionRequestResult> requestWhileInUsePermission() async {
    final serviceEnabled = await _client.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionRequestResult.serviceDisabled;
    }

    var permission = await _client.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _client.requestPermission();
    }

    return switch (_mapPermissionStatus(permission)) {
      LocationPermissionStatus.granted =>
        LocationPermissionRequestResult.granted,
      LocationPermissionStatus.denied => LocationPermissionRequestResult.denied,
      LocationPermissionStatus.deniedForever =>
        LocationPermissionRequestResult.deniedForever,
      LocationPermissionStatus.restricted =>
        LocationPermissionRequestResult.restricted,
      LocationPermissionStatus.serviceDisabled =>
        LocationPermissionRequestResult.serviceDisabled,
    };
  }

  @override
  Future<bool> openAppSettings() {
    return _client.openAppSettings();
  }

  @override
  Future<bool> openLocationSettings() {
    return _client.openLocationSettings();
  }

  LocationPermissionStatus _mapPermissionStatus(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionStatus.granted,
      LocationPermission.denied => LocationPermissionStatus.denied,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      LocationPermission.unableToDetermine =>
        LocationPermissionStatus.restricted,
    };
  }
}
