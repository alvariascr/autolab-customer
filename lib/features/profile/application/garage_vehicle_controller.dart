import 'package:flutter/foundation.dart';

import '../domain/usecases/delete_garage_vehicle.dart';
import '../domain/usecases/set_default_garage_vehicle.dart';

/// Updates garage vehicle state and tells visible screens to reload Supabase.
class GarageVehicleController extends ChangeNotifier {
  GarageVehicleController(
    this._setDefaultGarageVehicle,
    this._deleteGarageVehicle,
  );

  final SetDefaultGarageVehicle _setDefaultGarageVehicle;
  final DeleteGarageVehicle _deleteGarageVehicle;

  Future<void> setDefaultVehicle(String vehicleId) async {
    final normalizedId = vehicleId.trim();
    if (normalizedId.isEmpty) return;

    await _setDefaultGarageVehicle(normalizedId);
    notifyListeners();
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final normalizedId = vehicleId.trim();
    if (normalizedId.isEmpty) return;

    await _deleteGarageVehicle(normalizedId);
    notifyListeners();
  }

  void notifyVehiclesChanged() => notifyListeners();
}
