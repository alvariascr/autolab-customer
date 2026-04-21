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
        .where((w) => w.hasValidCoordinates && w.hasValidDeliveryRadius)
        .map((w) => (
    workshop: w,
    distance: WorkshopDistanceCalculator.distanceInKm(
      currentLocation: currentLocation,
      workshop: w,
    ),
    ))
        .where((item) => item.distance <= item.workshop.deliveryRadiusKm)
        .toList();

    nearbyWithDistance.sort((a, b) => a.distance.compareTo(b.distance));

    return List<Workshop>.from(
      nearbyWithDistance.map((item) => item.workshop),
      growable: false,
    );
  }
}
