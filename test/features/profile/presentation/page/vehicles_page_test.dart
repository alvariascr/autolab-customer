import 'dart:async';

import 'package:autolab_customer/core/di/app_injection.dart';
import 'package:autolab_customer/features/profile/application/garage_vehicle_controller.dart';
import 'package:autolab_customer/features/profile/application/garage_vehicle_image_service.dart';
import 'package:autolab_customer/features/profile/domain/entities/garage_vehicle.dart';
import 'package:autolab_customer/features/profile/domain/repositories/garage_vehicle_repository.dart';
import 'package:autolab_customer/features/profile/domain/usecases/delete_garage_vehicle.dart';
import 'package:autolab_customer/features/profile/domain/usecases/get_garage_vehicles.dart';
import 'package:autolab_customer/features/profile/domain/usecases/set_default_garage_vehicle.dart';
import 'package:autolab_customer/features/profile/presentation/page/vehicles_page.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
import 'package:autolab_customer/l10n/app_localizations_es.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGarageVehicleRepository extends Mock
    implements GarageVehicleRepository {}

class _MockGarageVehicleImageService extends Mock
    implements GarageVehicleImageService {}

class _MockGarageVehicleController extends Mock
    implements GarageVehicleController {}

class _MockSetDefaultGarageVehicle extends Mock
    implements SetDefaultGarageVehicle {}

class _MockDeleteGarageVehicle extends Mock implements DeleteGarageVehicle {}

void main() {
  group('VehiclesPage editing via the "..." menu', () {
    late _MockGarageVehicleRepository vehicleRepository;
    late _MockGarageVehicleImageService vehicleImageService;
    late _MockGarageVehicleController garageVehicleController;

    const vehicle = GarageVehicle(
      id: 'vehicle-1',
      licensePlate: 'ABC-123',
      brand: 'Toyota',
      model: 'Tacoma',
      isDefault: true,
    );

    setUp(() {
      vehicleRepository = _MockGarageVehicleRepository();
      vehicleImageService = _MockGarageVehicleImageService();
      garageVehicleController = _MockGarageVehicleController();

      when(
        () => vehicleRepository.getVehicles(),
      ).thenAnswer((_) async => [vehicle]);
      when(
        () => vehicleImageService.uploadLegacyImages(any()),
      ).thenAnswer((_) async => false);
      when(
        () => vehicleImageService.loadLocalImages(),
      ).thenAnswer((_) async => {});
      when(
        () => vehicleRepository.updateVehicle(
          id: any(named: 'id'),
          licensePlate: any(named: 'licensePlate'),
          vehicleType: any(named: 'vehicleType'),
          brand: any(named: 'brand'),
          model: any(named: 'model'),
          year: any(named: 'year'),
          color: any(named: 'color'),
          fuelType: any(named: 'fuelType'),
          transmissionType: any(named: 'transmissionType'),
        ),
      ).thenAnswer((_) async {});

      sl.registerSingleton<GarageVehicleRepository>(vehicleRepository);
      sl.registerSingleton<GetGarageVehicles>(
        GetGarageVehicles(vehicleRepository),
      );
      sl.registerSingleton<GarageVehicleImageService>(vehicleImageService);
      sl.registerSingleton<GarageVehicleController>(garageVehicleController);
    });

    tearDown(() async {
      await sl.unregister<GarageVehicleRepository>();
      await sl.unregister<GetGarageVehicles>();
      await sl.unregister<GarageVehicleImageService>();
      await sl.unregister<GarageVehicleController>();
    });

    testWidgets('notifies the shared garage controller after saving an edit', (
      tester,
    ) async {
      await tester.pumpWidget(const _TestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar vehículo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar vehículo').last);
      await tester.pumpAndSettle();

      verify(
        () => vehicleRepository.updateVehicle(
          id: 'vehicle-1',
          licensePlate: any(named: 'licensePlate'),
          vehicleType: any(named: 'vehicleType'),
          brand: any(named: 'brand'),
          model: any(named: 'model'),
          year: any(named: 'year'),
          color: any(named: 'color'),
          fuelType: any(named: 'fuelType'),
          transmissionType: any(named: 'transmissionType'),
        ),
      ).called(1);
      verify(() => garageVehicleController.notifyVehiclesChanged()).called(1);
    });

    testWidgets(
      'shows a validation error and blocks saving when the year is not a '
      'number',
      (tester) async {
        await tester.pumpWidget(const _TestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_horiz_rounded));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Editar vehículo'));
        await tester.pumpAndSettle();

        // Scoped to the BottomSheet so it doesn't collide with the
        // embedded form's own year field (same Key) underneath.
        final yearField = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byKey(const Key('vehicle-year-field')),
        );

        await tester.enterText(yearField, 'abcd');
        await tester.tap(find.text('Guardar vehículo').last);
        await tester.pumpAndSettle();

        expect(
          find.text(AppLocalizationsEs().vehiclesYearInvalid),
          findsOneWidget,
        );
        verifyNever(
          () => vehicleRepository.updateVehicle(
            id: any(named: 'id'),
            licensePlate: any(named: 'licensePlate'),
            vehicleType: any(named: 'vehicleType'),
            brand: any(named: 'brand'),
            model: any(named: 'model'),
            year: any(named: 'year'),
            color: any(named: 'color'),
            fuelType: any(named: 'fuelType'),
            transmissionType: any(named: 'transmissionType'),
          ),
        );
      },
    );
  });

  group('VehiclesPage selecting a different vehicle', () {
    late _MockGarageVehicleRepository vehicleRepository;
    late _MockGarageVehicleImageService vehicleImageService;
    late _MockSetDefaultGarageVehicle setDefaultGarageVehicle;
    late _MockDeleteGarageVehicle deleteGarageVehicle;
    late GarageVehicleController garageVehicleController;

    const activeVehicle = GarageVehicle(
      id: 'vehicle-1',
      licensePlate: 'ABC-123',
      brand: 'Toyota',
      model: 'Tacoma',
      isDefault: true,
    );
    const otherVehicle = GarageVehicle(
      id: 'vehicle-2',
      licensePlate: 'XYZ-789',
      brand: 'Honda',
      model: 'Civic',
    );

    setUp(() {
      vehicleRepository = _MockGarageVehicleRepository();
      vehicleImageService = _MockGarageVehicleImageService();
      setDefaultGarageVehicle = _MockSetDefaultGarageVehicle();
      deleteGarageVehicle = _MockDeleteGarageVehicle();
      // Real controller (not mocked): this is the same class Home listens
      // to in production, so a passing test here proves the notification
      // actually reaches listeners, not just that a mock method was called.
      garageVehicleController = GarageVehicleController(
        setDefaultGarageVehicle,
        deleteGarageVehicle,
      );

      when(
        () => vehicleRepository.getVehicles(),
      ).thenAnswer((_) async => [activeVehicle, otherVehicle]);
      when(
        () => vehicleImageService.uploadLegacyImages(any()),
      ).thenAnswer((_) async => false);
      when(
        () => vehicleImageService.loadLocalImages(),
      ).thenAnswer((_) async => {});
      when(() => setDefaultGarageVehicle('vehicle-2')).thenAnswer((_) async {});

      sl.registerSingleton<GarageVehicleRepository>(vehicleRepository);
      sl.registerSingleton<GetGarageVehicles>(
        GetGarageVehicles(vehicleRepository),
      );
      sl.registerSingleton<GarageVehicleImageService>(vehicleImageService);
      sl.registerSingleton<GarageVehicleController>(garageVehicleController);
    });

    tearDown(() async {
      await sl.unregister<GarageVehicleRepository>();
      await sl.unregister<GetGarageVehicles>();
      await sl.unregister<GarageVehicleImageService>();
      await sl.unregister<GarageVehicleController>();
    });

    testWidgets(
      'tapping a non-default vehicle only previews it, without activating',
      (tester) async {
        await tester.pumpWidget(const _TestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Honda Civic'));
        await tester.pumpAndSettle();

        verifyNever(() => setDefaultGarageVehicle(any()));
        expect(find.text('Usar como vehículo activo'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "Usar como vehículo activo" activates the previewed vehicle',
      (tester) async {
        var notifications = 0;
        garageVehicleController.addListener(() => notifications++);

        await tester.pumpWidget(const _TestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Honda Civic'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Usar como vehículo activo'));
        await tester.pumpAndSettle();

        verify(() => setDefaultGarageVehicle('vehicle-2')).called(1);
        expect(
          notifications,
          greaterThan(0),
          reason:
              'GarageVehicleController.setDefaultVehicle() already calls '
              'notifyListeners() internally, so activating a vehicle from '
              'Mi Garaje must already refresh Home.',
        );
      },
    );
  });

  group('VehiclesPage deleting a vehicle', () {
    late _MockGarageVehicleRepository vehicleRepository;
    late _MockGarageVehicleImageService vehicleImageService;
    late _MockGarageVehicleController garageVehicleController;

    const vehicle = GarageVehicle(
      id: 'vehicle-1',
      licensePlate: 'ABC-123',
      brand: 'Toyota',
      model: 'Tacoma',
      isDefault: true,
    );

    setUp(() {
      vehicleRepository = _MockGarageVehicleRepository();
      vehicleImageService = _MockGarageVehicleImageService();
      garageVehicleController = _MockGarageVehicleController();

      when(
        () => vehicleRepository.getVehicles(),
      ).thenAnswer((_) async => [vehicle]);
      when(
        () => vehicleImageService.uploadLegacyImages(any()),
      ).thenAnswer((_) async => false);
      when(
        () => vehicleImageService.loadLocalImages(),
      ).thenAnswer((_) async => {});
      when(
        () => garageVehicleController.deleteVehicle('vehicle-1'),
      ).thenAnswer((_) async {});

      sl.registerSingleton<GarageVehicleRepository>(vehicleRepository);
      sl.registerSingleton<GetGarageVehicles>(
        GetGarageVehicles(vehicleRepository),
      );
      sl.registerSingleton<GarageVehicleImageService>(vehicleImageService);
      sl.registerSingleton<GarageVehicleController>(garageVehicleController);
    });

    tearDown(() async {
      await sl.unregister<GarageVehicleRepository>();
      await sl.unregister<GetGarageVehicles>();
      await sl.unregister<GarageVehicleImageService>();
      await sl.unregister<GarageVehicleController>();
    });

    testWidgets('routes the deletion through the shared garage controller, not '
        'the repository directly, and reloads the list afterwards', (
      tester,
    ) async {
      await tester.pumpWidget(const _TestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      verify(
        () => garageVehicleController.deleteVehicle('vehicle-1'),
      ).called(1);
      verifyNever(() => vehicleRepository.deleteVehicle(any()));
      verify(() => vehicleRepository.getVehicles()).called(2);
    });

    testWidgets('clears the previewed vehicle immediately, before the delete '
        'request resolves', (tester) async {
      final deleteCompleter = Completer<void>();
      when(
        () => garageVehicleController.deleteVehicle('vehicle-1'),
      ).thenAnswer((_) => deleteCompleter.future);

      await tester.pumpWidget(const _TestApp());
      await tester.pumpAndSettle();

      // One in the compact card, one in the preview below it.
      expect(find.text('Toyota Tacoma'), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pump();

      // The delete request is still pending (deleteCompleter unresolved),
      // but the preview should have stopped showing the doomed vehicle
      // already — only the compact card instance remains.
      expect(find.text('Toyota Tacoma'), findsNWidgets(1));

      deleteCompleter.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('restores the previewed vehicle if the delete request fails', (
      tester,
    ) async {
      when(
        () => garageVehicleController.deleteVehicle('vehicle-1'),
      ).thenThrow(Exception('network error'));

      await tester.pumpWidget(const _TestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Toyota Tacoma'), findsNWidgets(2));
      expect(
        find.text('No pudimos eliminar el vehículo. Intenta nuevamente.'),
        findsOneWidget,
      );
    });
  });

  group('VehiclesPage deleting the active vehicle', () {
    late _MockGarageVehicleRepository vehicleRepository;
    late _MockGarageVehicleImageService vehicleImageService;
    late _MockSetDefaultGarageVehicle setDefaultGarageVehicle;
    late _MockDeleteGarageVehicle deleteGarageVehicle;
    late GarageVehicleController garageVehicleController;
    late List<GarageVehicle> currentVehicles;

    const activeVehicle = GarageVehicle(
      id: 'vehicle-1',
      licensePlate: 'ABC-123',
      brand: 'Toyota',
      model: 'Tacoma',
      isDefault: true,
    );
    const otherVehicle = GarageVehicle(
      id: 'vehicle-2',
      licensePlate: 'XYZ-789',
      brand: 'Honda',
      model: 'Civic',
    );

    setUp(() {
      currentVehicles = [activeVehicle, otherVehicle];
      vehicleRepository = _MockGarageVehicleRepository();
      vehicleImageService = _MockGarageVehicleImageService();
      setDefaultGarageVehicle = _MockSetDefaultGarageVehicle();
      deleteGarageVehicle = _MockDeleteGarageVehicle();
      // Real controller: proves setDefaultVehicle() is actually invoked on
      // the promoted vehicle, not just that some mock method was called.
      garageVehicleController = GarageVehicleController(
        setDefaultGarageVehicle,
        deleteGarageVehicle,
      );

      when(
        () => vehicleRepository.getVehicles(),
      ).thenAnswer((_) async => currentVehicles);
      when(
        () => vehicleImageService.uploadLegacyImages(any()),
      ).thenAnswer((_) async => false);
      when(
        () => vehicleImageService.loadLocalImages(),
      ).thenAnswer((_) async => {});
      when(() => deleteGarageVehicle('vehicle-1')).thenAnswer((_) async {
        currentVehicles = currentVehicles
            .where((item) => item.id != 'vehicle-1')
            .toList();
      });
      when(() => setDefaultGarageVehicle('vehicle-2')).thenAnswer((_) async {});

      sl.registerSingleton<GarageVehicleRepository>(vehicleRepository);
      sl.registerSingleton<GetGarageVehicles>(
        GetGarageVehicles(vehicleRepository),
      );
      sl.registerSingleton<GarageVehicleImageService>(vehicleImageService);
      sl.registerSingleton<GarageVehicleController>(garageVehicleController);
    });

    tearDown(() async {
      await sl.unregister<GarageVehicleRepository>();
      await sl.unregister<GetGarageVehicles>();
      await sl.unregister<GarageVehicleImageService>();
      await sl.unregister<GarageVehicleController>();
    });

    testWidgets(
      'promotes the only remaining vehicle to default automatically',
      (tester) async {
        await tester.pumpWidget(const _TestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();

        verify(() => deleteGarageVehicle('vehicle-1')).called(1);
        verify(() => setDefaultGarageVehicle('vehicle-2')).called(1);
        // Once for the initial load, once for the final refresh after
        // deleting and promoting — never a second reload in between.
        verify(() => vehicleRepository.getVehicles()).called(2);
      },
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const VehiclesPage(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
