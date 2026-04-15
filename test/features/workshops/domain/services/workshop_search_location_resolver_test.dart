import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/features/workshops/domain/services/workshop_search_location_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopSearchLocationResolver', () {
    const resolver = WorkshopSearchLocationResolver();

    test('usa la ubicacion del usuario cuando esta disponible', () {
      const currentLocation = CurrentLocation(
        latitude: 9.9281,
        longitude: -84.0907,
      );

      expect(resolver.resolve(currentLocation), currentLocation);
      expect(resolver.isUsingFallback(currentLocation), isFalse);
    });

    test('usa Tilaran como fallback cuando no hay ubicacion', () {
      final result = resolver.resolve(null);

      expect(result, WorkshopSearchLocationResolver.tilaranFallbackLocation);
      expect(resolver.isUsingFallback(null), isTrue);
    });
  });
}
