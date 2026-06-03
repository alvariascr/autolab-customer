import '../../domain/entities/garage_vehicle.dart';

class GarageVehicleModel extends GarageVehicle {
  const GarageVehicleModel({
    required super.id,
    required super.licensePlate,
    super.vehicleType,
    super.brand,
    super.model,
    super.year,
    super.color,
    super.fuelType,
    super.transmissionType,
  });

  factory GarageVehicleModel.fromMap(Map<String, dynamic> map) {
    return GarageVehicleModel(
      id: map['id']?.toString() ?? '',
      licensePlate: map['license_plate']?.toString() ?? '',
      vehicleType: map['vehicle_type']?.toString(),
      brand: map['brand']?.toString(),
      model: map['model']?.toString(),
      year: map['year'] is int ? map['year'] as int : null,
      color: map['color']?.toString(),
      fuelType: map['fuel_type']?.toString(),
      transmissionType: map['transmission_type']?.toString(),
    );
  }
}
