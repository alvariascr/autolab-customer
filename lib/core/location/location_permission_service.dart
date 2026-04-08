import 'package:geolocator/geolocator.dart';

enum LocationPermissionRequestResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

abstract class LocationPermissionService {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
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
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
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
