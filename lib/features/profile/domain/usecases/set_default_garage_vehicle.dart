import '../repositories/garage_vehicle_repository.dart';

class SetDefaultGarageVehicle {
  const SetDefaultGarageVehicle(this._repository);

  final GarageVehicleRepository _repository;

  Future<void> call(String vehicleId) =>
      _repository.setDefaultVehicle(vehicleId);
}
