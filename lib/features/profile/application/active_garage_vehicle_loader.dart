import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/garage_vehicle.dart';
import '../domain/usecases/get_default_garage_vehicle.dart';

class ActiveGarageVehicle {
  const ActiveGarageVehicle({required this.vehicle, this.localImagePath});

  final GarageVehicle vehicle;
  final String? localImagePath;
}

Future<ActiveGarageVehicle?> loadActiveGarageVehicle(
  GetDefaultGarageVehicle getDefaultGarageVehicle,
) async {
  final vehicle = await getDefaultGarageVehicle();
  if (vehicle == null) return null;

  final preferences = await SharedPreferences.getInstance();
  final imagePath = preferences.getString('garage_vehicle_image_${vehicle.id}');
  final localImagePath = imagePath != null && File(imagePath).existsSync()
      ? imagePath
      : null;

  return ActiveGarageVehicle(vehicle: vehicle, localImagePath: localImagePath);
}
