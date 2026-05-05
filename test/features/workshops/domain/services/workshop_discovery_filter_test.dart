import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/domain/services/workshop_discovery_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopDiscoveryFilter', () {
    const filter = WorkshopDiscoveryFilter();
    const currentLocation = CurrentLocation(
      latitude: 9.9330,
      longitude: -84.0800,
    );

    test('aplica proximidad y busqueda de texto en una sola lista', () {
      final results = filter.apply(
        workshops: _workshops,
        currentLocation: currentLocation,
        query: 'frenos',
      );

      expect(results.map((workshop) => workshop.name), ['Frenos Heredia']);
    });

    test('retorna talleres cercanos cuando no hay busqueda', () {
      final results = filter.apply(
        workshops: _workshops,
        currentLocation: currentLocation,
        query: '',
      );

      expect(results.map((workshop) => workshop.name), [
        'Autolab Escazu',
        'Frenos Heredia',
      ]);
    });
  });
}

const _workshops = [
  Workshop(
    id: '1',
    name: 'Autolab Escazu',
    description: 'Mantenimiento general',
    locationAddress: 'Escazu Centro',
    avatarUrl: '',
    coverUrl: '',
    latitude: 9.9330,
    longitude: -84.0800,
    deliveryRadiusKm: 8,
  ),
  Workshop(
    id: '2',
    name: 'Frenos Heredia',
    description: 'Especialistas en frenos',
    locationAddress: 'Heredia Centro',
    avatarUrl: '',
    coverUrl: '',
    latitude: 9.9340,
    longitude: -84.0810,
    deliveryRadiusKm: 12,
  ),
  Workshop(
    id: '3',
    name: 'Llantas Cartago',
    description: 'Llantas y balanceo',
    locationAddress: 'Cartago',
    avatarUrl: '',
    coverUrl: '',
    latitude: 9.8644,
    longitude: -83.9194,
    deliveryRadiusKm: 2,
  ),
];
