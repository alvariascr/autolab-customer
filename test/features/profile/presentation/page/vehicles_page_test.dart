import 'package:autolab_customer/core/di/app_injection.dart';
import 'package:autolab_customer/features/profile/application/garage_vehicle_controller.dart';
import 'package:autolab_customer/features/profile/application/garage_vehicle_image_service.dart';
import 'package:autolab_customer/features/profile/domain/entities/garage_vehicle.dart';
import 'package:autolab_customer/features/profile/domain/repositories/garage_vehicle_repository.dart';
import 'package:autolab_customer/features/profile/domain/usecases/get_garage_vehicles.dart';
import 'package:autolab_customer/features/profile/presentation/page/vehicles_page.dart';
import 'package:autolab_customer/l10n/app_localizations.dart';
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
