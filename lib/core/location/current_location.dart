class CurrentLocation {
  final double latitude;
  final double longitude;

  const CurrentLocation({required this.latitude, required this.longitude});

  bool get hasValidCoordinates {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}
