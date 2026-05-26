class AppointmentVehicleRecord {
  const AppointmentVehicleRecord({
    required this.id,
    required this.licensePlate,
    this.vehicleType,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.fuelType,
    this.transmissionType,
  });

  final String id;
  final String licensePlate;
  final String? vehicleType;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final String? fuelType;
  final String? transmissionType;
}
