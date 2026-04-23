import 'dart:math' as math;

import '../../../../core/location/current_location.dart';
import '../entities/workshop.dart';

class WorkshopDistanceCalculator {
  const WorkshopDistanceCalculator._();

  static double distanceInKm({
    required CurrentLocation currentLocation,
    required Workshop workshop,
  }) {
    const earthRadiusInKm = 6371.0;
    final deltaLatitude = _degreesToRadians(
      workshop.latitude - currentLocation.latitude,
    );
    final deltaLongitude = _degreesToRadians(
      workshop.longitude - currentLocation.longitude,
    );
    final startLatitudeInRadians = _degreesToRadians(currentLocation.latitude);
    final endLatitudeInRadians = _degreesToRadians(workshop.latitude);

    final haversine =
        _squareOfSine(deltaLatitude / 2) +
        _squareOfSine(deltaLongitude / 2) *
            math.cos(startLatitudeInRadians) *
            math.cos(endLatitudeInRadians);

    final angularDistance =
        2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));

    return earthRadiusInKm * angularDistance;
  }

  static String formatKm(double distanceInKm) {
    if (!distanceInKm.isFinite) {
      return '-- km';
    }

    if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }

    return '${distanceInKm.round()} km';
  }

  static double _degreesToRadians(double value) {
    return value * (math.pi / 180);
  }

  static double _squareOfSine(double value) {
    final sine = math.sin(value);
    return sine * sine;
  }
}
