import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/garage_vehicle.dart';
import '../domain/usecases/get_garage_vehicles.dart';

class ActiveGarageVehicle {
  const ActiveGarageVehicle({required this.vehicle, this.localImagePath});

  final GarageVehicle vehicle;
  final String? localImagePath;
}

Future<ActiveGarageVehicle?> loadActiveGarageVehicle(
  GetGarageVehicles getGarageVehicles,
) async {
  final vehicles = await getGarageVehicles();
  GarageVehicle? vehicle;
  for (final item in vehicles) {
    if (item.isDefault) {
      vehicle = item;
      break;
    }
  }
  if (vehicle == null) return null;

  final preferences = await SharedPreferences.getInstance();
  final imagePath = preferences.getString('garage_vehicle_image_${vehicle.id}');
  final localImagePath = imagePath != null && File(imagePath).existsSync()
      ? imagePath
      : null;

  return ActiveGarageVehicle(vehicle: vehicle, localImagePath: localImagePath);
}
