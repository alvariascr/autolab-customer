import 'dart:async';

import '../../core/di/app_injection.dart';
import '../../core/location/location_cubit.dart';
import '../../core/location/location_state.dart';
import '../profile/application/active_garage_vehicle_loader.dart';
import '../profile/domain/usecases/get_default_garage_vehicle.dart';
import '../workshops/domain/repositories/workshop_repository.dart';

class StartupPreloader {
  const StartupPreloader();

  static const _taskTimeout = Duration(seconds: 4);

  Future<void> preload() {
    return Future.wait<void>([
      _runSafely(_preloadWorkshops),
      _runSafely(_preloadLocation),
      _runSafely(_preloadActiveVehicle),
    ]);
  }

  Future<void> _runSafely(Future<void> Function() task) async {
    try {
      await task().timeout(_taskTimeout);
    } catch (_) {
      // Startup preloading is best-effort and must never block the splash flow.
    }
  }

  Future<void> _preloadWorkshops() async {
    if (!sl.isRegistered<WorkshopRepository>()) {
      return;
    }

    await sl<WorkshopRepository>().getWorkshops();
  }

  Future<void> _preloadLocation() async {
    if (!sl.isRegistered<LocationCubit>()) {
      return;
    }

    final locationCubit = sl<LocationCubit>();
    if (locationCubit.state.status == LocationFlowStatus.loading ||
        locationCubit.state.effectiveStatus == LocationFlowStatus.success) {
      return;
    }

    await locationCubit.loadCurrentLocation(requestPermissionIfNeeded: false);
  }

  Future<void> _preloadActiveVehicle() async {
    if (!sl.isRegistered<GetDefaultGarageVehicle>()) {
      return;
    }

    await loadActiveGarageVehicle(sl<GetDefaultGarageVehicle>());
  }
}
