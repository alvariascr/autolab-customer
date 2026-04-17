import '../../../../core/location/current_location.dart';
import '../entities/workshop.dart';
import 'workshop_distance_calculator.dart';

class WorkshopProximityFilter {
  const WorkshopProximityFilter();

  List<Workshop> filterNearby({
    required List<Workshop> workshops,
    required CurrentLocation? currentLocation,
  }) {
    if (currentLocation == null || !currentLocation.hasValidCoordinates) {
      return const <Workshop>[];
    }

    final nearby = workshops.where((workshop) {
      if (!workshop.hasValidCoordinates || !workshop.hasValidDeliveryRadius) {
        return false;
      }

      return WorkshopDistanceCalculator.distanceInKm(
            currentLocation: currentLocation,
            workshop: workshop,
          ) <=
          workshop.deliveryRadiusKm;
    }).toList();

    nearby.sort((first, second) {
      final firstDistance = WorkshopDistanceCalculator.distanceInKm(
        currentLocation: currentLocation,
        workshop: first,
      );
      final secondDistance = WorkshopDistanceCalculator.distanceInKm(
        currentLocation: currentLocation,
        workshop: second,
      );

      return firstDistance.compareTo(secondDistance);
    });

    return nearby;
  }
}
