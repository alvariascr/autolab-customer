import 'package:geolocator/geolocator.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  unableToDetermine,
}

enum LocationPermissionRequestResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

abstract class LocationPermissionService {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermissionStatus> checkPermission();
  Future<LocationPermissionRequestResult> requestWhileInUsePermission();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class GeolocatorLocationPermissionService implements LocationPermissionService {
  const GeolocatorLocationPermissionService();

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    final permission = await Geolocator.checkPermission();

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionStatus.granted,
      LocationPermission.denied => LocationPermissionStatus.denied,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      LocationPermission.unableToDetermine =>
        LocationPermissionStatus.unableToDetermine,
    };
  }

  @override
  Future<LocationPermissionRequestResult> requestWhileInUsePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionRequestResult.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionRequestResult.granted,
      LocationPermission.denied => LocationPermissionRequestResult.denied,
      LocationPermission.deniedForever =>
        LocationPermissionRequestResult.deniedForever,
      LocationPermission.unableToDetermine =>
        LocationPermissionRequestResult.denied,
    };
  }

  @override
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  @override
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}
