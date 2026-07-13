import '../../domain/entities/garage_vehicle.dart';

String garageVehicleTitle(GarageVehicle vehicle) {
  final title = [
    vehicle.brand,
    vehicle.model,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

  return title.isEmpty ? vehicle.licensePlate : title;
}

String garageVehicleSelectorSubtitle(GarageVehicle vehicle) {
  return [
    vehicle.model,
    if (vehicle.year != null) vehicle.year.toString(),
  ].where((part) => part != null && part.trim().isNotEmpty).join(' - ');
}

String garageActiveVehicleSubtitle(GarageVehicle vehicle) {
  return [
    if (vehicle.year != null) vehicle.year.toString(),
    vehicle.licensePlate,
  ].where((part) => part.trim().isNotEmpty).join(' - ');
}
