import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/map/presentation/cubit/map_cubit.dart';
import 'package:autolab_customer/features/map/presentation/cubit/map_state.dart';
import 'package:autolab_customer/features/workshops/application/workshop_discovery_query_store.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/domain/repositories/workshop_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkshopRepository extends Mock implements WorkshopRepository {}

class MockFeatureLogger extends Mock implements FeatureLogger {}

void main() {
  group('MapCubit', () {
    late MockWorkshopRepository repository;
    late MockFeatureLogger featureLogger;
    late WorkshopDiscoveryQueryStore queryStore;
    late MapCubit cubit;
    var getWorkshopsCalls = 0;

    setUp(() {
      repository = MockWorkshopRepository();
      featureLogger = MockFeatureLogger();
      queryStore = WorkshopDiscoveryQueryStore();
      getWorkshopsCalls = 0;

      when(() => repository.getWorkshops()).thenAnswer((_) async {
        getWorkshopsCalls += 1;
        return const Right(_workshops);
      });
      when(
        () => featureLogger.info(
          feature: any(named: 'feature'),
          action: any(named: 'action'),
          code: any(named: 'code'),
          context: any(named: 'context'),
        ),
      ).thenReturn(null);
      when(
        () => featureLogger.warn(
          feature: any(named: 'feature'),
          action: any(named: 'action'),
          code: any(named: 'code'),
          context: any(named: 'context'),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);

      cubit = MapCubit(repository, featureLogger, queryStore: queryStore);
    });

    tearDown(() async {
      await cubit.close();
    });

    test(
      'refiltra marcadores cuando cambia el query sin recargar talleres',
      () async {
        await cubit.loadWorkshops(_currentLocation);

        expect(getWorkshopsCalls, 1);
        expect(cubit.state, isA<MapLoaded>());
        expect(
          (cubit.state as MapLoaded).workshops.map((workshop) => workshop.name),
          ['Autolab Escazu', 'Frenos Heredia'],
        );

        queryStore.setQuery('frenos');

        expect(getWorkshopsCalls, 1);
        expect(
          (cubit.state as MapLoaded).workshops.map((workshop) => workshop.name),
          ['Frenos Heredia'],
        );
        expect((cubit.state as MapLoaded).query, 'frenos');
      },
    );
  });
}

const _currentLocation = CurrentLocation(latitude: 9.9330, longitude: -84.0800);

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
