import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/core/location/current_location_data_source.dart';
import 'package:autolab_customer/core/location/location_cubit.dart';
import 'package:autolab_customer/core/location/location_permission_service.dart';
import 'package:autolab_customer/core/location/location_place_resolver.dart';
import 'package:autolab_customer/features/auth/bloc/auth_bloc.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/repository/auth_repository.dart';
import 'package:autolab_customer/features/home/home_customer_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationPermissionService extends Mock
    implements LocationPermissionService {}

class MockCurrentLocationDataSource extends Mock
    implements CurrentLocationDataSource {}

class MockLocationPlaceResolver extends Mock implements LocationPlaceResolver {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class MockAppLogger extends Mock implements AppLogger {}

class FakeCurrentLocation extends Fake implements CurrentLocation {}

class _UnusedAuthRepository implements AuthRepository {
  @override
  Future<AppUser?> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Unit>> logout() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String name,
    String email,
    String phone,
    String password,
  ) {
    throw UnimplementedError();
  }
}

void main() {
  group('HomeCustomerPage', () {
    late MockLocationPermissionService permissionService;
    late MockCurrentLocationDataSource currentLocationDataSource;
    late MockLocationPlaceResolver placeResolver;
    late MockGlobalErrorHandler errorHandler;
    late MockAppLogger logger;
    late AuthBloc authBloc;
    late LocationCubit locationCubit;

    setUpAll(() {
      registerFallbackValue(FakeCurrentLocation());
    });

    setUp(() {
      permissionService = MockLocationPermissionService();
      currentLocationDataSource = MockCurrentLocationDataSource();
      placeResolver = MockLocationPlaceResolver();
      errorHandler = MockGlobalErrorHandler();
      logger = MockAppLogger();
      authBloc = AuthBloc(_UnusedAuthRepository());
      locationCubit = LocationCubit(
        permissionService,
        currentLocationDataSource,
        placeResolver,
        errorHandler: errorHandler,
      );

      when(() => errorHandler.logger).thenReturn(logger);
      when(() => errorHandler.handle(any(), any())).thenReturn(
        const UnknownFailure(message: 'Ocurrió un error inesperado.'),
      );
    });

    tearDown(() async {
      await authBloc.close();
      await locationCubit.close();
    });

    testWidgets('muestra mensaje claro cuando el permiso fue rechazado', (
      tester,
    ) async {
      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.denied);

      await _pumpPage(tester, authBloc, locationCubit);

      expect(find.text('Usa tu ubicación'), findsOneWidget);
      expect(find.text('Actívala para ver opciones cercanas.'), findsOneWidget);
      expect(find.text('Activar'), findsOneWidget);
    });

    testWidgets('muestra el nombre del lugar cuando el resolver lo entrega', (
      tester,
    ) async {
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

      await _pumpPage(tester, authBloc, locationCubit);

      expect(find.text('Entregando en Escazu, San Jose'), findsOneWidget);
      expect(
        find.text('Mostraremos talleres y servicios cercanos.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra mensaje claro cuando el servicio está desactivado', (
      tester,
    ) async {
      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.serviceDisabled);

      await _pumpPage(tester, authBloc, locationCubit);

      expect(find.text('Activa tu ubicación'), findsOneWidget);
      expect(
        find.text('Enciende tu ubicación para continuar.'),
        findsOneWidget,
      );
      expect(find.text('Encender GPS'), findsOneWidget);
    });

    testWidgets(
      'muestra mensaje controlado cuando la consulta entra en timeout',
      (tester) async {
        when(
          () => permissionService.getPermissionStatus(),
        ).thenAnswer((_) async => LocationPermissionStatus.granted);
        when(() => currentLocationDataSource.getCurrentLocation()).thenAnswer(
          (_) async => const Left(
            TimeoutFailure(
              message:
                  'La solicitud tardó demasiado tiempo. Intenta nuevamente.',
              code: 'NET_002',
            ),
          ),
        );

        await _pumpPage(tester, authBloc, locationCubit);

        expect(find.text('No pudimos ubicarte'), findsOneWidget);
        expect(
          find.text(
            'La ubicación tardó demasiado en responder. Intenta nuevamente.',
          ),
          findsOneWidget,
        );
        expect(find.text('Reintentar'), findsOneWidget);
      },
    );

    testWidgets('muestra un estado de carga informativo sin aparentar error', (
      tester,
    ) async {
      final locationCompleter = Completer<Either<Failure, CurrentLocation>>();

      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.granted);
      when(
        () => currentLocationDataSource.getCurrentLocation(),
      ).thenAnswer((_) => locationCompleter.future);

      await tester.pumpWidget(_buildTestApp(authBloc, locationCubit));
      await tester.pump();

      expect(find.text('Buscando tu ubicación'), findsOneWidget);
      expect(
        find.text('Consultando ubicación del dispositivo...'),
        findsOneWidget,
      );
      expect(find.text('No pudimos ubicarte'), findsNothing);
    });

    testWidgets('muestra retroalimentación visible mientras solicita permiso', (
      tester,
    ) async {
      final permissionCompleter = Completer<LocationPermissionRequestResult>();

      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.denied);
      when(
        () => permissionService.requestWhileInUsePermission(),
      ).thenAnswer((_) => permissionCompleter.future);

      await _pumpPage(tester, authBloc, locationCubit);

      await tester.tap(find.text('Activar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pump();

      expect(find.text('Solicitando permiso'), findsOneWidget);
      expect(
        find.text('Esperando tu respuesta para acceder a la ubicación.'),
        findsOneWidget,
      );

      permissionCompleter.complete(LocationPermissionRequestResult.denied);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'si abrir ajustes falla, la app responde con un mensaje controlado',
      (tester) async {
        when(
          () => permissionService.getPermissionStatus(),
        ).thenAnswer((_) async => LocationPermissionStatus.serviceDisabled);
        when(
          () => permissionService.openLocationSettings(),
        ).thenThrow(Exception('platform channel failed'));

        await _pumpPage(tester, authBloc, locationCubit);

        await tester.tap(find.text('Encender GPS'));
        await tester.pumpAndSettle();

        expect(find.text('No pudimos ubicarte'), findsOneWidget);
        expect(
          find.text(
            'No fue posible completar la acción de ubicación. Intenta nuevamente.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'si abrir ajustes retorna false, la app responde con un mensaje controlado',
      (tester) async {
        when(
          () => permissionService.getPermissionStatus(),
        ).thenAnswer((_) async => LocationPermissionStatus.serviceDisabled);
        when(
          () => permissionService.openLocationSettings(),
        ).thenAnswer((_) async => false);

        await _pumpPage(tester, authBloc, locationCubit);

        await tester.tap(find.text('Encender GPS'));
        await tester.pumpAndSettle();

        expect(find.text('No pudimos ubicarte'), findsOneWidget);
        expect(
          find.text(
            'No fue posible completar la acción de ubicación. Intenta nuevamente.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  AuthBloc authBloc,
  LocationCubit locationCubit,
) async {
  await tester.pumpWidget(_buildTestApp(authBloc, locationCubit));
  await tester.pumpAndSettle();
}

Widget _buildTestApp(AuthBloc authBloc, LocationCubit locationCubit) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<LocationCubit>.value(value: locationCubit),
      ],
      child: const HomeCustomerPage(),
    ),
  );
}
