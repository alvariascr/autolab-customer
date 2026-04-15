import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/domain/services/workshop_proximity_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopProximityFilter', () {
    const filter = WorkshopProximityFilter(maxDistanceInKm: 25);

    test('retorna solo talleres dentro del radio y ordenados por cercania', () {
      const currentLocation = CurrentLocation(
        latitude: 9.9281,
        longitude: -84.0907,
      );
      const closerWorkshop = Workshop(
        id: '1',
        name: 'Taller Escazu',
        description: 'Mas cercano',
        avatarUrl: '',
        coverUrl: '',
        latitude: 9.9330,
        longitude: -84.0800,
      );
      const fartherWorkshop = Workshop(
        id: '2',
        name: 'Taller Heredia',
        description: 'Aun cercano',
        avatarUrl: '',
        coverUrl: '',
        latitude: 10.0024,
        longitude: -84.1165,
      );
      const outOfRangeWorkshop = Workshop(
        id: '3',
        name: 'Taller Liberia',
        description: 'Muy lejos',
        avatarUrl: '',
        coverUrl: '',
        latitude: 10.6350,
        longitude: -85.4377,
      );

      final result = filter.filterNearby(
        workshops: const [outOfRangeWorkshop, fartherWorkshop, closerWorkshop],
        currentLocation: currentLocation,
      );

      expect(result, hasLength(2));
      expect(result.first.id, closerWorkshop.id);
      expect(result.last.id, fartherWorkshop.id);
    });

    test('descarta talleres con coordenadas invalidas', () {
      const currentLocation = CurrentLocation(
        latitude: 9.9281,
        longitude: -84.0907,
      );
      const invalidWorkshop = Workshop(
        id: '1',
        name: 'Sin coordenadas',
        description: '',
        avatarUrl: '',
        coverUrl: '',
        latitude: 0,
        longitude: 0,
      );

      final result = filter.filterNearby(
        workshops: const [invalidWorkshop],
        currentLocation: currentLocation,
      );

      expect(result, isEmpty);
    });

    test('retorna lista vacia cuando la ubicacion no esta disponible', () {
      final result = filter.filterNearby(
        workshops: const [
          Workshop(
            id: '1',
            name: 'Taller Escazu',
            description: '',
            avatarUrl: '',
            coverUrl: '',
            latitude: 9.9330,
            longitude: -84.0800,
          ),
        ],
        currentLocation: null,
      );

      expect(result, isEmpty);
    });
  });
}
