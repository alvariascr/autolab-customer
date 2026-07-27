import 'package:flutter/foundation.dart';

import '../data/garage_vehicle_remote_data_source.dart';

/// Updates garage vehicle state and tells visible screens to reload Supabase.
class GarageVehicleController extends ChangeNotifier {
  GarageVehicleController(this._dataSource);

  final GarageVehicleRemoteDataSource _dataSource;

  Future<void> setDefaultVehicle(String vehicleId) async {
    final normalizedId = vehicleId.trim();
    if (normalizedId.isEmpty) return;

    await _dataSource.setDefaultGarageVehicle(normalizedId);
    notifyListeners();
  }

  void notifyVehiclesChanged() => notifyListeners();
}
