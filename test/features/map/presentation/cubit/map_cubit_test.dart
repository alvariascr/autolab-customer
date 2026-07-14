import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/map/presentation/cubit/map_cubit.dart';
import 'package:autolab_customer/features/map/presentation/cubit/map_state.dart';
import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:autolab_customer/features/products/domain/repositories/product_repository.dart';
import 'package:autolab_customer/features/workshops/application/workshop_discovery_query_store.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/domain/repositories/workshop_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkshopRepository extends Mock implements WorkshopRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockFeatureLogger extends Mock implements FeatureLogger {}

void main() {
  group('MapCubit', () {
    late MockWorkshopRepository repository;
    late MockProductRepository productRepository;
    late MockFeatureLogger featureLogger;
    late WorkshopDiscoveryQueryStore queryStore;
    late MapCubit cubit;
    var getWorkshopsCalls = 0;

    setUp(() {
      repository = MockWorkshopRepository();
      productRepository = MockProductRepository();
      featureLogger = MockFeatureLogger();
      queryStore = WorkshopDiscoveryQueryStore();
      getWorkshopsCalls = 0;

      when(() => repository.getWorkshops()).thenAnswer((_) async {
        getWorkshopsCalls += 1;
        return const Right(_workshops);
      });
      when(
        () => productRepository.getActiveProducts(),
      ).thenAnswer((_) async => const Right(<Product>[]));
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

      cubit = MapCubit(
        repository,
        productRepository,
        featureLogger,
        queryStore: queryStore,
        queryDebounceDuration: Duration.zero,
      );
    });

    tearDown(() async {
      if (!cubit.isClosed) {
        await cubit.close();
      }
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

    test('recalcula ubicacion usando talleres cacheados', () async {
      await cubit.loadWorkshops(_currentLocation);
      await cubit.loadWorkshops(
        const CurrentLocation(latitude: 9.9340, longitude: -84.0800),
      );

      expect(getWorkshopsCalls, 1);
      expect(cubit.state, isA<MapLoaded>());
      expect((cubit.state as MapLoaded).currentLocation?.latitude, 9.9340);
    });

    test(
      'ignora respuestas de talleres cuando el cubit ya fue cerrado',
      () async {
        final pendingWorkshops = Completer<Either<Failure, List<Workshop>>>();
        when(
          () => repository.getWorkshops(),
        ).thenAnswer((_) => pendingWorkshops.future);

        final loadFuture = cubit.loadWorkshops(_currentLocation);

        await cubit.close();
        pendingWorkshops.complete(const Right(_workshops));

        await expectLater(loadFuture, completes);
      },
    );

    test('emite loading mientras carga talleres por primera vez', () async {
      final pendingWorkshops = Completer<Either<Failure, List<Workshop>>>();
      when(
        () => repository.getWorkshops(),
      ).thenAnswer((_) => pendingWorkshops.future);

      final loadFuture = cubit.loadWorkshops(_currentLocation);

      expect(cubit.state, const MapLoading());

      pendingWorkshops.complete(const Right(_workshops));
      await loadFuture;
    });

    test('aplica debounce al refiltrar por query', () async {
      final debouncedQueryStore = WorkshopDiscoveryQueryStore();
      final debouncedCubit = MapCubit(
        repository,
        productRepository,
        featureLogger,
        queryStore: debouncedQueryStore,
        queryDebounceDuration: const Duration(milliseconds: 30),
      );

      addTearDown(debouncedCubit.close);

      await debouncedCubit.loadWorkshops(_currentLocation);

      debouncedQueryStore.setQuery('frenos');

      expect(
        (debouncedCubit.state as MapLoaded).workshops.map(
          (workshop) => workshop.name,
        ),
        ['Autolab Escazu', 'Frenos Heredia'],
      );

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(
        (debouncedCubit.state as MapLoaded).workshops.map(
          (workshop) => workshop.name,
        ),
        ['Frenos Heredia'],
      );
    });

    test('solo aplica el ultimo query durante el debounce', () async {
      final debouncedQueryStore = WorkshopDiscoveryQueryStore();
      final debouncedCubit = MapCubit(
        repository,
        productRepository,
        featureLogger,
        queryStore: debouncedQueryStore,
        queryDebounceDuration: const Duration(milliseconds: 30),
      );

      addTearDown(debouncedCubit.close);

      await debouncedCubit.loadWorkshops(_currentLocation);

      debouncedQueryStore.setQuery('auto');
      debouncedQueryStore.setQuery('frenos');

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect((debouncedCubit.state as MapLoaded).query, 'frenos');
      expect(
        (debouncedCubit.state as MapLoaded).workshops.map(
          (workshop) => workshop.name,
        ),
        ['Frenos Heredia'],
      );
    });

    test('ignora respuestas viejas cuando hay cargas concurrentes', () async {
      final firstLoad = Completer<Either<Failure, List<Workshop>>>();
      final secondLoad = Completer<Either<Failure, List<Workshop>>>();
      var callIndex = 0;

      when(() => repository.getWorkshops()).thenAnswer((_) {
        callIndex += 1;
        return callIndex == 1 ? firstLoad.future : secondLoad.future;
      });

      final firstFuture = cubit.loadWorkshops(_currentLocation);
      final secondFuture = cubit.loadWorkshops(_currentLocation);

      secondLoad.complete(const Right([_updatedWorkshop]));
      await secondFuture;

      expect(cubit.state, isA<MapLoaded>());
      expect(
        (cubit.state as MapLoaded).workshops.map((workshop) => workshop.name),
        ['Taller Actualizado'],
      );

      firstLoad.complete(const Right(_workshops));
      await firstFuture;

      expect(
        (cubit.state as MapLoaded).workshops.map((workshop) => workshop.name),
        ['Taller Actualizado'],
      );
    });
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

const _updatedWorkshop = Workshop(
  id: '4',
  name: 'Taller Actualizado',
  description: 'Carga mas reciente',
  locationAddress: 'San Jose',
  avatarUrl: '',
  coverUrl: '',
  latitude: 9.9330,
  longitude: -84.0800,
  deliveryRadiusKm: 8,
);
