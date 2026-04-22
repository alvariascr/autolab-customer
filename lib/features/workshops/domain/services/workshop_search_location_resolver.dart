import '../../../../core/location/current_location.dart';

class WorkshopSearchLocationResolver {
  const WorkshopSearchLocationResolver();

  CurrentLocation? resolve(CurrentLocation? currentLocation) {
    if (currentLocation != null && currentLocation.hasValidCoordinates) {
      return currentLocation;
    }

    return null;
  }

  bool isUsingFallback(CurrentLocation? currentLocation) {
    return false;
  }
}
