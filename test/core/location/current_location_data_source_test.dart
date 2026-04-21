import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/errors/customer_error_catalog.dart';
import 'package:autolab_customer/core/location/current_location_data_source.dart';
import 'package:autolab_customer/core/location/geolocator_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockGeolocatorClient extends Mock implements GeolocatorClient {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class MockAppLogger extends Mock implements AppLogger {}

class FakePosition extends Fake implements Position {}

void main() {
  group('CurrentLocationDataSourceImpl', () {
    late MockGeolocatorClient geolocatorClient;
    late MockGlobalErrorHandler errorHandler;
    late MockAppLogger logger;
    late CurrentLocationDataSource dataSource;

    setUpAll(() {
      registerFallbackValue(FakePosition());
    });

    setUp(() {
      geolocatorClient = MockGeolocatorClient();
      errorHandler = MockGlobalErrorHandler();
      logger = MockAppLogger();

      when(() => errorHandler.logger).thenReturn(logger);
      when(() => errorHandler.handle(any(), any())).thenReturn(
        const UnknownFailure(message: 'Ocurrio un error inesperado.'),
      );

      dataSource = CurrentLocationDataSourceImpl(
        geolocatorClient,
        errorHandler,
      );
    });

    test(
      'retorna coordenadas validas cuando hay permiso y ubicacion activa',
      () async {
        when(
          () => geolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          () => geolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => geolocatorClient.getCurrentPosition()).thenAnswer(
          (_) async => _buildPosition(latitude: 9.9281, longitude: -84.0907),
        );

        final result = await dataSource.getCurrentLocation();

        expect(result.isRight(), true);
        result.fold((_) => fail('Se esperaba una ubicacion valida'), (
          location,
        ) {
          expect(location.latitude, 9.9281);
          expect(location.longitude, -84.0907);
          expect(location.hasValidCoordinates, true);
        });
      },
    );

    test(
      'retorna failure controlado cuando el servicio de ubicacion esta desactivado',
      () async {
        when(
          () => geolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => false);

        final result = await dataSource.getCurrentLocation();

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(
            failure.code,
            CustomerErrorCatalog.locationServiceDisabled.code,
          );
        }, (_) => fail('Se esperaba Failure'));
        verifyNever(() => geolocatorClient.getCurrentPosition());
      },
    );

    test(
      'retorna failure controlado cuando no hay permisos de ubicacion',
      () async {
        when(
          () => geolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          () => geolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);

        final result = await dataSource.getCurrentLocation();

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(
            failure.code,
            CustomerErrorCatalog.locationPermissionRequired.code,
          );
        }, (_) => fail('Se esperaba Failure'));
        verifyNever(() => geolocatorClient.getCurrentPosition());
      },
    );

    test(
      'retorna timeout failure cuando obtener ubicacion excede el tiempo limite',
      () async {
        when(
          () => geolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          () => geolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          () => geolocatorClient.getCurrentPosition(),
        ).thenThrow(TimeoutException('timeout'));

        final result = await dataSource.getCurrentLocation();

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<TimeoutFailure>());
          expect(failure.code, ErrorCatalog.requestTimeout.code);
        }, (_) => fail('Se esperaba Failure'));
      },
    );

    test(
      'usa el error handler para excepciones tecnicas inesperadas',
      () async {
        final exception = Exception('random location error');
        final mappedFailure = UnknownFailure(
          message: ErrorCatalog.unknownError.message,
          code: ErrorCatalog.unknownError.code,
          cause: exception,
        );

        when(
          () => geolocatorClient.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          () => geolocatorClient.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => geolocatorClient.getCurrentPosition()).thenThrow(exception);
        when(
          () => errorHandler.handle(exception, any()),
        ).thenReturn(mappedFailure);

        final result = await dataSource.getCurrentLocation();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, mappedFailure),
          (_) => fail('Se esperaba Failure'),
        );
        verify(() => errorHandler.handle(exception, any())).called(1);
      },
    );
  });
}

Position _buildPosition({required double latitude, required double longitude}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime(2026, 4, 8),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );
}
