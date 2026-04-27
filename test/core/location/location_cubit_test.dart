import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/errors/customer_error_catalog.dart';
import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/core/location/current_location_data_source.dart';
import 'package:autolab_customer/core/location/location_cubit.dart';
import 'package:autolab_customer/core/location/location_flow_recovery_service.dart';
import 'package:autolab_customer/core/location/location_permission_service.dart';
import 'package:autolab_customer/core/location/location_place_resolver.dart';
import 'package:autolab_customer/core/location/location_state.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationPermissionService extends Mock
    implements LocationPermissionService {}

class MockCurrentLocationDataSource extends Mock
    implements CurrentLocationDataSource {}

class MockLocationPlaceResolver extends Mock implements LocationPlaceResolver {}

class MockLocationFlowRecoveryService extends Mock
    implements LocationFlowRecoveryService {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class MockFeatureLogger extends Mock implements FeatureLogger {}

class FakeCurrentLocation extends Fake implements CurrentLocation {}

void main() {
  group('LocationCubit', () {
    late MockLocationPermissionService permissionService;
    late MockCurrentLocationDataSource currentLocationDataSource;
    late MockLocationPlaceResolver placeResolver;
    late MockLocationFlowRecoveryService flowRecoveryService;
    late MockGlobalErrorHandler errorHandler;
    late MockFeatureLogger featureLogger;
    late LocationCubit cubit;

    setUpAll(() {
      registerFallbackValue(FakeCurrentLocation());
    });

    setUp(() {
      permissionService = MockLocationPermissionService();
      currentLocationDataSource = MockCurrentLocationDataSource();
      placeResolver = MockLocationPlaceResolver();
      flowRecoveryService = MockLocationFlowRecoveryService();
      errorHandler = MockGlobalErrorHandler();
      featureLogger = MockFeatureLogger();

      when(() => errorHandler.handle(any(), any())).thenReturn(
        const UnknownFailure(message: 'Ocurrió un error inesperado.'),
      );
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
      when(
        () => featureLogger.error(
          feature: any(named: 'feature'),
          action: any(named: 'action'),
          code: any(named: 'code'),
          context: any(named: 'context'),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);
      when(
        () => flowRecoveryService.consumePendingSettingsSync(),
      ).thenAnswer((_) async => false);
      when(
        () => flowRecoveryService.markPendingSettingsSync(),
      ).thenAnswer((_) async {});

      cubit = LocationCubit(
        permissionService,
        currentLocationDataSource,
        placeResolver,
        flowRecoveryService: flowRecoveryService,
        errorHandler: errorHandler,
        featureLogger: featureLogger,
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
        (_) async => Left(
          TimeoutFailure(
            message: CustomerErrorCatalog.locationRequestTimeout.code,
            code: 'NET_002',
            uiKey: CustomerErrorCatalog.locationRequestTimeout.uiKey,
          ),
        ),
      );

      await cubit.loadCurrentLocation();

      expect(cubit.state.status, LocationFlowStatus.error);
      expect(cubit.state.failureCode, 'NET_002');
      expect(
        cubit.state.failureUiKey,
        CustomerErrorCatalog.locationRequestTimeout.uiKey,
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
        cubit.state.failureUiKey,
        CustomerErrorCatalog.locationActionFailed.uiKey,
      );
      verify(() => errorHandler.handle(settingsError, any())).called(1);
    });

    test(
      'si abrir ajustes del GPS retorna false, emite error controlado',
      () async {
        when(
          () => permissionService.openLocationSettings(),
        ).thenAnswer((_) async => false);

        await cubit.openLocationSettings();

        expect(cubit.state.status, LocationFlowStatus.error);
        expect(
          cubit.state.failureUiKey,
          CustomerErrorCatalog.locationActionFailed.uiKey,
        );
        verify(() => errorHandler.handle(any(), any())).called(1);
      },
    );

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

    test(
      'después de rechazos repetidos escala a deniedForever para enviar a configuración',
      () async {
        when(
          () => permissionService.requestWhileInUsePermission(),
        ).thenAnswer((_) async => LocationPermissionRequestResult.denied);

        await cubit.requestPermission();
        expect(cubit.state.status, LocationFlowStatus.permissionRequired);
        expect(cubit.state.permissionDeniedCount, 1);

        await cubit.requestPermission();
        expect(cubit.state.status, LocationFlowStatus.deniedForever);
        expect(cubit.state.permissionDeniedCount, 2);
      },
    );
  });
}
