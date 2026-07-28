import 'package:autolab_customer/features/profile/application/garage_vehicle_controller.dart';
import 'package:autolab_customer/features/profile/domain/usecases/set_default_garage_vehicle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSetDefaultGarageVehicle extends Mock
    implements SetDefaultGarageVehicle {}

void main() {
  test('sets the database default vehicle and notifies screens', () async {
    final setDefaultGarageVehicle = _MockSetDefaultGarageVehicle();
    when(() => setDefaultGarageVehicle(any())).thenAnswer((_) async {});
    final controller = GarageVehicleController(setDefaultGarageVehicle);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setDefaultVehicle('vehicle-1');

    verify(() => setDefaultGarageVehicle('vehicle-1')).called(1);
    expect(notifications, 1);
  });

  test('propagates errors without notifying screens', () async {
    final setDefaultGarageVehicle = _MockSetDefaultGarageVehicle();
    final error = Exception('garage_vehicle_not_found_or_not_owned');
    when(() => setDefaultGarageVehicle(any())).thenThrow(error);
    final controller = GarageVehicleController(setDefaultGarageVehicle);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await expectLater(
      controller.setDefaultVehicle('vehicle-1'),
      throwsA(same(error)),
    );

    verify(() => setDefaultGarageVehicle('vehicle-1')).called(1);
    expect(notifications, 0);
  });
}
