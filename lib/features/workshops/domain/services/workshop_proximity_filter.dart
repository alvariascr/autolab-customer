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

    final nearbyWithDistance = workshops
        .where(
          (workshop) =>
              workshop.hasValidCoordinates && workshop.hasValidDeliveryRadius,
        )
        .map(
          (workshop) => (
            workshop: workshop,
            distance: WorkshopDistanceCalculator.distanceInKm(
              currentLocation: currentLocation,
              workshop: workshop,
            ),
          ),
        )
        .where(
          (item) => item.distance <= item.workshop.deliveryRadiusKm,
        )
        .toList();

    nearbyWithDistance.sort((first, second) {
      return first.distance.compareTo(second.distance);
    });

    return nearbyWithDistance
        .map((item) => item.workshop)
        .toList(growable: false);
  }
}
