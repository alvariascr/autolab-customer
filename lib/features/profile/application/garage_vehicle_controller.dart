import 'package:flutter/foundation.dart';

import '../domain/usecases/set_default_garage_vehicle.dart';

/// Updates garage vehicle state and tells visible screens to reload Supabase.
class GarageVehicleController extends ChangeNotifier {
  GarageVehicleController(this._setDefaultGarageVehicle);

  final SetDefaultGarageVehicle _setDefaultGarageVehicle;

  Future<void> setDefaultVehicle(String vehicleId) async {
    final normalizedId = vehicleId.trim();
    if (normalizedId.isEmpty) return;

    await _setDefaultGarageVehicle(normalizedId);
    notifyListeners();
  }

  void notifyVehiclesChanged() => notifyListeners();
}
