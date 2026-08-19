import '../../domain/entities/garage_vehicle.dart';
import '../../domain/repositories/garage_vehicle_repository.dart';
import '../garage_vehicle_remote_data_source.dart';

class GarageVehicleRepositoryImpl implements GarageVehicleRepository {
  GarageVehicleRepositoryImpl(this._remoteDataSource);

  final GarageVehicleRemoteDataSource _remoteDataSource;
  Future<GarageVehicle?>? _defaultVehicleRequest;

  @override
  Future<List<GarageVehicle>> getVehicles() => _remoteDataSource.getVehicles();

  @override
  Future<GarageVehicle?> getDefaultVehicle() async {
    final pendingRequest = _defaultVehicleRequest;
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _remoteDataSource.getDefaultVehicle();
    _defaultVehicleRequest = request;
    try {
      return await request;
    } finally {
      _defaultVehicleRequest = null;
    }
  }

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
    _clearDefaultVehicleRequest();
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
    _clearDefaultVehicleRequest();
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
  Future<void> deleteVehicle(String id) {
    _clearDefaultVehicleRequest();
    return _remoteDataSource.deleteVehicle(id);
  }

  @override
  Future<void> setDefaultVehicle(String vehicleId) {
    _clearDefaultVehicleRequest();
    return _remoteDataSource.setDefaultGarageVehicle(vehicleId);
  }

  @override
  Future<void> uploadVehicleImage({
    required String garageVehicleId,
    required String localFilePath,
  }) {
    _clearDefaultVehicleRequest();
    return _remoteDataSource.uploadVehicleImage(
      garageVehicleId: garageVehicleId,
      localFilePath: localFilePath,
    );
  }

  void _clearDefaultVehicleRequest() {
    _defaultVehicleRequest = null;
  }
}
