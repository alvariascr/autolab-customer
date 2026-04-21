import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/location/current_location.dart';
import 'package:autolab_customer/core/location/current_location_data_source.dart';
import 'package:autolab_customer/core/errors/customer_error_catalog.dart';
import 'package:autolab_customer/core/location/location_cubit.dart';
import 'package:autolab_customer/core/location/location_flow_recovery_service.dart';
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

class MockLocationFlowRecoveryService extends Mock
    implements LocationFlowRecoveryService {}

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
    late MockLocationFlowRecoveryService flowRecoveryService;
    late MockGlobalErrorHandler errorHandler;
    late MockAppLogger logger;
    late AuthBloc authBloc;
    late LocationCubit locationCubit;

    setUpAll(() {
      registerFallbackValue(FakeCurrentLocation());
    });

    setUp(() async {
      permissionService = MockLocationPermissionService();
      currentLocationDataSource = MockCurrentLocationDataSource();
      placeResolver = MockLocationPlaceResolver();
      flowRecoveryService = MockLocationFlowRecoveryService();
      errorHandler = MockGlobalErrorHandler();
      logger = MockAppLogger();
      authBloc = AuthBloc(_UnusedAuthRepository());

      when(() => errorHandler.logger).thenReturn(logger);
      when(() => errorHandler.handle(any(), any())).thenReturn(
        const UnknownFailure(message: 'Ocurrió un error inesperado.'),
      );
      when(
        () => flowRecoveryService.consumePendingSettingsSync(),
      ).thenAnswer((_) async => false);
      when(
        () => flowRecoveryService.markPendingSettingsSync(),
      ).thenAnswer((_) async {});
      when(
        () => permissionService.requestWhileInUsePermission(),
      ).thenAnswer((_) async => LocationPermissionRequestResult.denied);

      locationCubit = LocationCubit(
        permissionService,
        currentLocationDataSource,
        placeResolver,
        flowRecoveryService: flowRecoveryService,
        errorHandler: errorHandler,
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

      expect(find.text('Entregar ahora'), findsOneWidget);
      expect(find.text('Elegir dirección'), findsOneWidget);
      expect(
        find.text(
          'Usa tu ubicación actual para descubrir talleres y servicios cercanos.',
        ),
        findsOneWidget,
      );
      expect(find.text('Usar ubicación actual'), findsNothing);
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

      expect(find.text('Entregar ahora'), findsOneWidget);
      expect(find.text('Escazu, San Jose'), findsOneWidget);
      expect(find.text('Usar ubicación actual'), findsNothing);
    });

    testWidgets('muestra mensaje claro cuando el servicio está desactivado', (
      tester,
    ) async {
      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.serviceDisabled);

      await _pumpPage(tester, authBloc, locationCubit);

      expect(find.text('Ubicación desactivada'), findsOneWidget);
      expect(find.text('Encender GPS'), findsOneWidget);
      expect(
        find.text(
          'Activa la ubicación del dispositivo para ver resultados cercanos.',
        ),
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
          (_) async => Left(
            TimeoutFailure(
              message: CustomerErrorCatalog.locationRequestTimeout.message,
              code: 'NET_002',
            ),
          ),
        );

        await _pumpPage(tester, authBloc, locationCubit);

        expect(find.text('No pudimos confirmar tu zona'), findsOneWidget);
        expect(find.text('No pudimos confirmar tu dirección'), findsOneWidget);
        expect(
          find.text(
            'La ubicación tardó demasiado en responder. Intenta nuevamente.',
          ),
          findsOneWidget,
        );
        expect(find.text('Usar ubicación actual'), findsNothing);
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
      await _pumpUntilVisible(tester, find.text('Buscando cerca de ti'));

      expect(find.text('Buscando cerca de ti'), findsOneWidget);
      expect(find.text('Buscando tu ubicación actual'), findsOneWidget);
      expect(
        find.text(
          'Estamos consultando la ubicación del dispositivo para mostrarte talleres cercanos.',
        ),
        findsOneWidget,
      );
      expect(find.text('No pudimos confirmar tu dirección'), findsNothing);
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

      await tester.pumpWidget(_buildTestApp(authBloc, locationCubit));
      await _pumpUntilVisible(tester, find.text('Confirmando acceso'));

      expect(find.text('Confirmando acceso'), findsOneWidget);
      expect(find.text('Confirma el acceso a tu ubicación'), findsOneWidget);
      expect(
        find.text('Esperando tu respuesta para acceder a la ubicación.'),
        findsNothing,
      );
      expect(
        find.text(
          'Estamos esperando tu respuesta para poder ubicar tu zona de entrega.',
        ),
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
        await tester.tap(find.text('Encender GPS').last);
        await tester.pumpAndSettle();

        expect(find.text('No pudimos confirmar tu zona'), findsOneWidget);
        expect(find.text('No pudimos confirmar tu dirección'), findsOneWidget);
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
        await tester.tap(find.text('Encender GPS').last);
        await tester.pumpAndSettle();

        expect(find.text('No pudimos confirmar tu zona'), findsOneWidget);
        expect(find.text('No pudimos confirmar tu dirección'), findsOneWidget);
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
      'después de rechazar repetidamente muestra configuración en lugar de activar',
      (tester) async {
        when(
          () => permissionService.getPermissionStatus(),
        ).thenAnswer((_) async => LocationPermissionStatus.denied);
        when(
          () => permissionService.requestWhileInUsePermission(),
        ).thenAnswer((_) async => LocationPermissionRequestResult.denied);

        await _pumpPage(tester, authBloc, locationCubit);

        await tester.tap(find.text('Elegir dirección'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Usar ubicación actual'));
        await tester.pumpAndSettle();
        expect(find.text('Permiso de ubicación'), findsOneWidget);
        expect(find.text('Abrir configuración'), findsOneWidget);
        expect(find.text('Usar ubicación actual'), findsNothing);
      },
    );

    testWidgets('abre opciones de ubicación al tocar el header', (
      tester,
    ) async {
      when(
        () => permissionService.getPermissionStatus(),
      ).thenAnswer((_) async => LocationPermissionStatus.denied);

      await _pumpPage(tester, authBloc, locationCubit);

      await tester.tap(find.text('Elegir dirección'));
      await tester.pumpAndSettle();

      expect(find.text('Selecciona dónde entregar'), findsOneWidget);
      expect(find.text('Usar ubicación actual'), findsOneWidget);
      expect(find.text('Escribir dirección'), findsOneWidget);
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Trabajo'), findsOneWidget);
    });
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

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 50),
  Duration timeout = const Duration(seconds: 2),
}) async {
  var elapsed = Duration.zero;

  while (finder.evaluate().isEmpty) {
    if (elapsed >= timeout) {
      throw TestFailure(
        'No se encontró el widget esperado dentro de ${timeout.inMilliseconds}ms.',
      );
    }

    await tester.pump(step);
    elapsed += step;
  }
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
