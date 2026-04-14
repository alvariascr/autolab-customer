import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/core/location/current_location_data_source.dart';
import 'package:autolab_customer/core/location/location_cubit.dart';
import 'package:autolab_customer/core/location/location_permission_service.dart';
import 'package:autolab_customer/core/location/location_place_resolver.dart';
import 'package:autolab_customer/core/location/location_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationPermissionService extends Mock
    implements LocationPermissionService {}

class MockCurrentLocationDataSource extends Mock
    implements CurrentLocationDataSource {}

class MockLocationPlaceResolver extends Mock implements LocationPlaceResolver {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class FakeCurrentLocation extends Fake implements CurrentLocation {}

void main() {
  group('LocationCubit', () {
    late MockLocationPermissionService permissionService;
    late MockCurrentLocationDataSource currentLocationDataSource;
    late MockLocationPlaceResolver placeResolver;
    late MockGlobalErrorHandler errorHandler;
    late LocationCubit cubit;

    setUpAll(() {
      registerFallbackValue(FakeCurrentLocation());
    });

    setUp(() {
      permissionService = MockLocationPermissionService();
      currentLocationDataSource = MockCurrentLocationDataSource();
      placeResolver = MockLocationPlaceResolver();
      errorHandler = MockGlobalErrorHandler();

      when(() => errorHandler.handle(any(), any())).thenReturn(
        const UnknownFailure(message: 'Ocurrió un error inesperado.'),
      );

      cubit = LocationCubit(
        permissionService,
        currentLocationDataSource,
        placeResolver,
        errorHandler: errorHandler,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('carga ubicación exitosa y la deja disponible en memoria', () async {
      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.granted);
      when(() => currentLocationDataSource.getCurrentLocation()).thenAnswer(
        (_) async =>
            const Right(CurrentLocation(latitude: 9.9281, longitude: -84.0907)),
      );
      when(() => placeResolver.resolvePlaceName(any())).thenAnswer(
        (_) async => const LocationPlaceResolution(
          placeName: 'Escazu, San Jose, Costa Rica',
          debugDetails: 'test',
        ),
      );

      await cubit.loadCurrentLocation();

      expect(cubit.state.status, LocationFlowStatus.success);
      expect(cubit.state.location, isNotNull);
      expect(cubit.state.placeName, 'Escazu, San Jose, Costa Rica');
    });

    test('reporta permiso requerido cuando no hay autorización', () async {
      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.denied);

      await cubit.loadCurrentLocation();

      expect(cubit.state.status, LocationFlowStatus.permissionRequired);
      expect(cubit.state.location, isNull);
    });

    test('reporta servicio deshabilitado cuando aplica', () async {
      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.serviceDisabled);

      await cubit.loadCurrentLocation();

      expect(cubit.state.status, LocationFlowStatus.serviceDisabled);
    });

    test('mapea timeout a error controlado', () async {
      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.granted);
      when(() => currentLocationDataSource.getCurrentLocation()).thenAnswer(
        (_) async => const Left(
          TimeoutFailure(
            message: 'La solicitud tardó demasiado tiempo. Intenta nuevamente.',
            code: 'NET_002',
          ),
        ),
      );

      await cubit.loadCurrentLocation();

      expect(cubit.state.status, LocationFlowStatus.error);
      expect(
        cubit.state.message,
        'La ubicación tardó demasiado en responder. Intenta nuevamente.',
      );
    });

    test('mantiene la ubicación aunque falle el reverse geocoding', () async {
      final geocodingError = Exception('reverse geocoding failed');

      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.granted);
      when(() => currentLocationDataSource.getCurrentLocation()).thenAnswer(
        (_) async =>
            const Right(CurrentLocation(latitude: 9.9281, longitude: -84.0907)),
      );
      when(
        () => placeResolver.resolvePlaceName(any()),
      ).thenThrow(geocodingError);

      await cubit.loadCurrentLocation();

      expect(cubit.state.status, LocationFlowStatus.success);
      expect(cubit.state.location, isNotNull);
      expect(cubit.state.placeName, isNull);
      verify(() => errorHandler.handle(geocodingError, any())).called(1);
    });

    test('si abrir ajustes falla, emite error controlado', () async {
      final settingsError = Exception('settings unavailable');

      when(
        () => permissionService.openLocationSettings(),
      ).thenThrow(settingsError);

      await cubit.openLocationSettings();

      expect(cubit.state.status, LocationFlowStatus.error);
      expect(
        cubit.state.message,
        'No fue posible completar la acción de ubicación. Intenta nuevamente.',
      );
      verify(() => errorHandler.handle(settingsError, any())).called(1);
    });

    test('emite requestingPermission mientras solicita permiso', () async {
      final completer = Completer<LocationPermissionRequestResult>();

      when(
        () => permissionService.requestWhileInUsePermission(),
      ).thenAnswer((_) => completer.future);

      final requestFuture = cubit.requestPermission();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, LocationFlowStatus.requestingPermission);

      completer.complete(LocationPermissionRequestResult.denied);
      await requestFuture;
    });
  });
}
