import '../repositories/garage_vehicle_repository.dart';

class DeleteGarageVehicle {
  const DeleteGarageVehicle(this._repository);

  final GarageVehicleRepository _repository;

  Future<void> call(String vehicleId) => _repository.deleteVehicle(vehicleId);
}
