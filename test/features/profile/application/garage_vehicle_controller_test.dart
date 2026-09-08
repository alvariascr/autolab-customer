import 'package:autolab_customer/features/profile/application/garage_vehicle_controller.dart';
import 'package:autolab_customer/features/profile/domain/usecases/delete_garage_vehicle.dart';
import 'package:autolab_customer/features/profile/domain/usecases/set_default_garage_vehicle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSetDefaultGarageVehicle extends Mock
    implements SetDefaultGarageVehicle {}

class _MockDeleteGarageVehicle extends Mock implements DeleteGarageVehicle {}

void main() {
  late _MockSetDefaultGarageVehicle setDefaultGarageVehicle;
  late _MockDeleteGarageVehicle deleteGarageVehicle;
  late GarageVehicleController controller;

  setUp(() {
    setDefaultGarageVehicle = _MockSetDefaultGarageVehicle();
    deleteGarageVehicle = _MockDeleteGarageVehicle();
    controller = GarageVehicleController(
      setDefaultGarageVehicle,
      deleteGarageVehicle,
    );
  });

  group('setDefaultVehicle', () {
    test('sets the database default vehicle and notifies screens', () async {
      when(() => setDefaultGarageVehicle(any())).thenAnswer((_) async {});
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setDefaultVehicle('vehicle-1');

      verify(() => setDefaultGarageVehicle('vehicle-1')).called(1);
      expect(notifications, 1);
    });

    test('propagates errors without notifying screens', () async {
      final error = Exception('garage_vehicle_not_found_or_not_owned');
      when(() => setDefaultGarageVehicle(any())).thenThrow(error);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await expectLater(
        controller.setDefaultVehicle('vehicle-1'),
        throwsA(same(error)),
      );

      verify(() => setDefaultGarageVehicle('vehicle-1')).called(1);
      expect(notifications, 0);
    });
  });

  group('deleteVehicle', () {
    test('deletes the vehicle and notifies screens', () async {
      when(() => deleteGarageVehicle(any())).thenAnswer((_) async {});
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.deleteVehicle('vehicle-1');

      verify(() => deleteGarageVehicle('vehicle-1')).called(1);
      expect(notifications, 1);
    });

    test('propagates errors without notifying screens', () async {
      final error = Exception('garage_vehicle_not_found_or_not_owned');
      when(() => deleteGarageVehicle(any())).thenThrow(error);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await expectLater(
        controller.deleteVehicle('vehicle-1'),
        throwsA(same(error)),
      );

      verify(() => deleteGarageVehicle('vehicle-1')).called(1);
      expect(notifications, 0);
    });

    test('does nothing for a blank vehicle id', () async {
      await controller.deleteVehicle('   ');

      verifyNever(() => deleteGarageVehicle(any()));
    });
  });
}
