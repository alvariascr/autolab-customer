import '../entities/garage_vehicle.dart';
import '../repositories/garage_vehicle_repository.dart';

class GetGarageVehicles {
  const GetGarageVehicles(this._repository);

  final GarageVehicleRepository _repository;

  Future<List<GarageVehicle>> call() => _repository.getVehicles();
}
