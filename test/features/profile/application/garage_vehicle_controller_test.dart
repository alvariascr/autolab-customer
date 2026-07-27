import 'package:autolab_customer/features/profile/application/garage_vehicle_controller.dart';
import 'package:autolab_customer/features/profile/data/garage_vehicle_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGarageVehicleRemoteDataSource extends Mock
    implements GarageVehicleRemoteDataSource {}

void main() {
  test('sets the database default vehicle and notifies screens', () async {
    final dataSource = _MockGarageVehicleRemoteDataSource();
    when(
      () => dataSource.setDefaultGarageVehicle(any()),
    ).thenAnswer((_) async {});
    final controller = GarageVehicleController(dataSource);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setDefaultVehicle('vehicle-1');

    verify(() => dataSource.setDefaultGarageVehicle('vehicle-1')).called(1);
    expect(notifications, 1);
  });
}
