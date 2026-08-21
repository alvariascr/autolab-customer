import '../domain/entities/garage_vehicle.dart';
import '../domain/usecases/get_default_garage_vehicle.dart';

Future<GarageVehicle?> loadActiveGarageVehicle(
  GetDefaultGarageVehicle getDefaultGarageVehicle,
) async {
  try {
    return await getDefaultGarageVehicle();
  } catch (_) {
    return null;
  }
}
