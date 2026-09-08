import '../entities/garage_vehicle.dart';

class GarageVehicleAlreadyExistsException implements Exception {
  const GarageVehicleAlreadyExistsException();
}

abstract interface class GarageVehicleRepository {
  Future<List<GarageVehicle>> getVehicles();

  Future<GarageVehicle?> getDefaultVehicle();

  Future<String> createVehicle({
    required String licensePlate,
    String? vehicleType,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? fuelType,
    String? transmissionType,
  });

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
  });

  Future<void> deleteVehicle(String id);

  Future<void> setDefaultVehicle(String vehicleId);

  Future<void> uploadVehicleImage({
    required String garageVehicleId,
    required String localFilePath,
  });

  /// Re-signs a vehicle photo's storage path, for when a previously loaded
  /// signed URL has expired. Returns null if the image is gone or the
  /// request fails.
  Future<String?> refreshVehicleImageUrl(String imagePath);
}
