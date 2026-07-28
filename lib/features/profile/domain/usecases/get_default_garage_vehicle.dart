import '../entities/garage_vehicle.dart';
import '../repositories/garage_vehicle_repository.dart';

class GetDefaultGarageVehicle {
  const GetDefaultGarageVehicle(this._repository);

  final GarageVehicleRepository _repository;

  Future<GarageVehicle?> call() => _repository.getDefaultVehicle();
}
