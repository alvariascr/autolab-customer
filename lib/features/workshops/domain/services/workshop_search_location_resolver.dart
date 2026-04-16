import '../../../../core/location/current_location.dart';

class WorkshopSearchLocationResolver {
  const WorkshopSearchLocationResolver();

  static const tilaranFallbackLocation = CurrentLocation(
    latitude: 10.4667,
    longitude: -84.9333,
  );

  CurrentLocation resolve(CurrentLocation? currentLocation) {
    if (currentLocation != null && currentLocation.hasValidCoordinates) {
      return currentLocation;
    }

    return tilaranFallbackLocation;
  }

  bool isUsingFallback(CurrentLocation? currentLocation) {
    return currentLocation == null || !currentLocation.hasValidCoordinates;
  }
}
