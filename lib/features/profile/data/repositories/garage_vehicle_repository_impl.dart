import '../../domain/entities/garage_vehicle.dart';
import '../../domain/repositories/garage_vehicle_repository.dart';
import '../garage_vehicle_remote_data_source.dart';

class GarageVehicleRepositoryImpl implements GarageVehicleRepository {
  const GarageVehicleRepositoryImpl(this._remoteDataSource);

  final GarageVehicleRemoteDataSource _remoteDataSource;

  @override
  Future<List<GarageVehicle>> getVehicles() => _remoteDataSource.getVehicles();

  @override
  Future<String> createVehicle({
    required String licensePlate,
    String? vehicleType,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? fuelType,
    String? transmissionType,
  }) {
    return _remoteDataSource.createVehicle(
      licensePlate: licensePlate,
      vehicleType: vehicleType,
      brand: brand,
      model: model,
      year: year,
      color: color,
      fuelType: fuelType,
      transmissionType: transmissionType,
    );
  }

  @override
  Future<void> updateVehicle({
    required String id,
    required String licensePlate,
    String? vehicleType,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? fuelType,
    String? transmissionType,
  }) {
    return _remoteDataSource.updateVehicle(
      id: id,
      licensePlate: licensePlate,
      vehicleType: vehicleType,
      brand: brand,
      model: model,
      year: year,
      color: color,
      fuelType: fuelType,
      transmissionType: transmissionType,
    );
  }

  @override
  Future<void> deleteVehicle(String id) => _remoteDataSource.deleteVehicle(id);

  @override
  Future<void> setDefaultVehicle(String vehicleId) =>
      _remoteDataSource.setDefaultGarageVehicle(vehicleId);

  @override
  Future<void> uploadVehicleImage({
    required String garageVehicleId,
    required String localFilePath,
  }) {
    return _remoteDataSource.uploadVehicleImage(
      garageVehicleId: garageVehicleId,
      localFilePath: localFilePath,
    );
  }
}
