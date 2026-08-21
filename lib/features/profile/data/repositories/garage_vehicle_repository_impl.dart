import '../../domain/entities/garage_vehicle.dart';
import '../../domain/repositories/garage_vehicle_repository.dart';
import '../garage_vehicle_remote_data_source.dart';

class GarageVehicleRepositoryImpl implements GarageVehicleRepository {
  GarageVehicleRepositoryImpl(this._remoteDataSource);

  final GarageVehicleRemoteDataSource _remoteDataSource;
  Future<GarageVehicle?>? _defaultVehicleRequest;
  Future<dynamic>? _defaultVehicleMutation;
  int _defaultVehicleRequestGeneration = 0;

  @override
  Future<List<GarageVehicle>> getVehicles() => _remoteDataSource.getVehicles();

  @override
  Future<GarageVehicle?> getDefaultVehicle() async {
    final pendingMutation = _defaultVehicleMutation;
    if (pendingMutation != null) {
      await pendingMutation;
    }

    final pendingRequest = _defaultVehicleRequest;
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final requestGeneration = _defaultVehicleRequestGeneration;
    final request = _remoteDataSource.getDefaultVehicle();
    _defaultVehicleRequest = request;
    try {
      final vehicle = await request;
      if (requestGeneration != _defaultVehicleRequestGeneration) {
        return await getDefaultVehicle();
      }

      return vehicle;
    } finally {
      if (identical(_defaultVehicleRequest, request)) {
        _defaultVehicleRequest = null;
      }
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
    return _runDefaultVehicleMutation(
      () => _remoteDataSource.createVehicle(
        licensePlate: licensePlate,
        vehicleType: vehicleType,
        brand: brand,
        model: model,
        year: year,
        color: color,
        fuelType: fuelType,
        transmissionType: transmissionType,
      ),
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
    return _runDefaultVehicleMutation(
      () => _remoteDataSource.updateVehicle(
        id: id,
        licensePlate: licensePlate,
        vehicleType: vehicleType,
        brand: brand,
        model: model,
        year: year,
        color: color,
        fuelType: fuelType,
        transmissionType: transmissionType,
      ),
    );
  }

  @override
  Future<void> deleteVehicle(String id) {
    return _runDefaultVehicleMutation(
      () => _remoteDataSource.deleteVehicle(id),
    );
  }

  @override
  Future<void> setDefaultVehicle(String vehicleId) {
    return _runDefaultVehicleMutation(
      () => _remoteDataSource.setDefaultGarageVehicle(vehicleId),
    );
  }

  @override
  Future<void> uploadVehicleImage({
    required String garageVehicleId,
    required String localFilePath,
  }) {
    return _runDefaultVehicleMutation(
      () => _remoteDataSource.uploadVehicleImage(
        garageVehicleId: garageVehicleId,
        localFilePath: localFilePath,
      ),
    );
  }

  Future<T> _runDefaultVehicleMutation<T>(Future<T> Function() action) {
    _clearDefaultVehicleRequest();
    final request = action();
    _defaultVehicleMutation = request;
    return request.whenComplete(() {
      if (identical(_defaultVehicleMutation, request)) {
        _defaultVehicleMutation = null;
        _clearDefaultVehicleRequest();
      }
    });
  }

  void _clearDefaultVehicleRequest() {
    _defaultVehicleRequestGeneration++;
    _defaultVehicleRequest = null;
  }
}
