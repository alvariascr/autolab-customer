import '../../domain/entities/garage_vehicle.dart';
import '../../domain/repositories/garage_vehicle_repository.dart';
import '../garage_vehicle_remote_data_source.dart';

class GarageVehicleRepositoryImpl implements GarageVehicleRepository {
  GarageVehicleRepositoryImpl(this._remoteDataSource);

  final GarageVehicleRemoteDataSource _remoteDataSource;
  GarageVehicle? _defaultVehicleCache;
  Future<GarageVehicle?>? _defaultVehicleRequest;

  @override
  Future<List<GarageVehicle>> getVehicles() => _remoteDataSource.getVehicles();

  @override
  Future<GarageVehicle?> getDefaultVehicle() async {
    final cachedVehicle = _defaultVehicleCache;
    if (cachedVehicle != null) {
      return cachedVehicle;
    }

    final pendingRequest = _defaultVehicleRequest;
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _remoteDataSource.getDefaultVehicle();
    _defaultVehicleRequest = request;
    try {
      final vehicle = await request;
      if (vehicle != null) {
        _defaultVehicleCache = vehicle;
      }
      return vehicle;
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
    _clearDefaultVehicleCache();
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
    _clearDefaultVehicleCache();
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
    _clearDefaultVehicleCache();
    return _remoteDataSource.deleteVehicle(id);
  }

  @override
  Future<void> setDefaultVehicle(String vehicleId) {
    _clearDefaultVehicleCache();
    return _remoteDataSource.setDefaultGarageVehicle(vehicleId);
  }

  @override
  Future<void> uploadVehicleImage({
    required String garageVehicleId,
    required String localFilePath,
  }) {
    _clearDefaultVehicleCache();
    return _remoteDataSource.uploadVehicleImage(
      garageVehicleId: garageVehicleId,
      localFilePath: localFilePath,
    );
  }

  void _clearDefaultVehicleCache() {
    _defaultVehicleCache = null;
    _defaultVehicleRequest = null;
  }
}
