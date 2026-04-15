import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/core/location/location_state.dart';
import 'package:autolab_customer/features/workshops/presentation/workshop_empty_state_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopEmptyStateResolver', () {
    const resolver = WorkshopEmptyStateResolver();

    test('indica cuando no hay talleres cercanos', () {
      const state = LocationState(
        status: LocationFlowStatus.success,
        location: CurrentLocation(latitude: 9.9281, longitude: -84.0907),
      );

      expect(
        resolver.resolve(state),
        'No encontramos talleres cercanos a tu ubicación actual.',
      );
    });

    test('indica cuando se necesita activar la ubicacion', () {
      const state = LocationState(
        status: LocationFlowStatus.permissionRequired,
      );

      expect(
        resolver.resolve(state),
        'Activa tu ubicación para ver talleres cercanos.',
      );
    });

    test('indica cuando aun se esta buscando la ubicacion', () {
      const state = LocationState(status: LocationFlowStatus.loading);

      expect(resolver.resolve(state), 'Buscando talleres cercanos...');
    });
  });
}
