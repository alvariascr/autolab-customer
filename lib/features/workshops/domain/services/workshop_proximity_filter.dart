import 'dart:math' as math;

import '../../../../core/location/current_location.dart';
import '../entities/workshop.dart';

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

      return _distanceInKm(
            startLatitude: currentLocation.latitude,
            startLongitude: currentLocation.longitude,
            endLatitude: workshop.latitude,
            endLongitude: workshop.longitude,
          ) <=
          workshop.deliveryRadiusKm;
    }).toList();

    nearby.sort((first, second) {
      final firstDistance = _distanceInKm(
        startLatitude: currentLocation.latitude,
        startLongitude: currentLocation.longitude,
        endLatitude: first.latitude,
        endLongitude: first.longitude,
      );
      final secondDistance = _distanceInKm(
        startLatitude: currentLocation.latitude,
        startLongitude: currentLocation.longitude,
        endLatitude: second.latitude,
        endLongitude: second.longitude,
      );

      return firstDistance.compareTo(secondDistance);
    });

    return nearby;
  }

  double _distanceInKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    const earthRadiusInKm = 6371.0;
    final deltaLatitude = _degreesToRadians(endLatitude - startLatitude);
    final deltaLongitude = _degreesToRadians(endLongitude - startLongitude);
    final startLatitudeInRadians = _degreesToRadians(startLatitude);
    final endLatitudeInRadians = _degreesToRadians(endLatitude);

    final haversine =
        _squareOfSine(deltaLatitude / 2) +
        _squareOfSine(deltaLongitude / 2) *
            _cosine(startLatitudeInRadians) *
            _cosine(endLatitudeInRadians);

    final angularDistance =
        2 * _arcTangent2(_squareRoot(haversine), _squareRoot(1 - haversine));

    return earthRadiusInKm * angularDistance;
  }

  double _degreesToRadians(double value) => value * (3.1415926535897932 / 180);

  double _squareOfSine(double value) {
    final sine = _sine(value);
    return sine * sine;
  }

  double _sine(double value) => MathBridge.sin(value);

  double _cosine(double value) => MathBridge.cos(value);

  double _squareRoot(double value) => MathBridge.sqrt(value);

  double _arcTangent2(double y, double x) => MathBridge.atan2(y, x);
}

class MathBridge {
  static double sin(double value) => math.sin(value);

  static double cos(double value) => math.cos(value);

  static double sqrt(double value) => math.sqrt(value);

  static double atan2(double y, double x) => math.atan2(y, x);
}
