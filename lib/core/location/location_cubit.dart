import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'current_location_data_source.dart';
import 'location_permission_service.dart';
import 'location_place_resolver.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit(
    this._permissionService,
    this._currentLocationDataSource,
    this._placeResolver, {
    GlobalErrorHandler? errorHandler,
  }) : _errorHandler = errorHandler,
       super(const LocationState.initial());

  final LocationPermissionService _permissionService;
  final CurrentLocationDataSource _currentLocationDataSource;
  final LocationPlaceResolver _placeResolver;
  final GlobalErrorHandler? _errorHandler;

  Future<void> loadCurrentLocation() async {
    emit(
      state.copyWith(status: LocationFlowStatus.loading, clearMessage: true),
    );

    final permissionStatus = await _permissionService.getPermissionStatus();

    switch (permissionStatus) {
      case LocationPermissionStatus.granted:
        break;
      case LocationPermissionStatus.denied:
        emit(
          state.copyWith(
            status: LocationFlowStatus.permissionRequired,
            clearLocation: true,
            clearPlaceName: true,
            clearMessage: true,
          ),
        );
        return;
      case LocationPermissionStatus.deniedForever:
        emit(
          state.copyWith(
            status: LocationFlowStatus.deniedForever,
            clearLocation: true,
            clearPlaceName: true,
            clearMessage: true,
          ),
        );
        return;
      case LocationPermissionStatus.restricted:
        emit(
          state.copyWith(
            status: LocationFlowStatus.restricted,
            message: 'La ubicación está restringida por el sistema operativo.',
            clearLocation: true,
            clearPlaceName: true,
          ),
        );
        return;
      case LocationPermissionStatus.serviceDisabled:
        emit(
          state.copyWith(
            status: LocationFlowStatus.serviceDisabled,
            clearLocation: true,
            clearPlaceName: true,
            clearMessage: true,
          ),
        );
        return;
    }

    final result = await _currentLocationDataSource.getCurrentLocation();

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: LocationFlowStatus.error,
            message: _mapLocationFailureMessage(failure),
            clearLocation: true,
            clearPlaceName: true,
          ),
        );
      },
      (location) async {
        try {
          final resolution = await _placeResolver.resolvePlaceName(location);

          emit(
            state.copyWith(
              status: LocationFlowStatus.success,
              location: location,
              placeName: resolution.placeName,
              clearMessage: true,
            ),
          );
        } catch (error, stackTrace) {
          _errorHandler?.handle(error, stackTrace);

          emit(
            state.copyWith(
              status: LocationFlowStatus.success,
              location: location,
              clearPlaceName: true,
              clearMessage: true,
            ),
          );
        }
      },
    );
  }

  Future<void> requestPermission() async {
    try {
      final result = await _permissionService.requestWhileInUsePermission();

      switch (result) {
        case LocationPermissionRequestResult.granted:
        case LocationPermissionRequestResult.denied:
        case LocationPermissionRequestResult.deniedForever:
        case LocationPermissionRequestResult.restricted:
        case LocationPermissionRequestResult.serviceDisabled:
          await loadCurrentLocation();
      }
    } catch (error, stackTrace) {
      _emitActionError(error, stackTrace);
    }
  }

  Future<void> openAppSettings() async {
    try {
      await _permissionService.openAppSettings();
    } catch (error, stackTrace) {
      _emitActionError(error, stackTrace);
    }
  }

  Future<void> openLocationSettings() async {
    try {
      await _permissionService.openLocationSettings();
    } catch (error, stackTrace) {
      _emitActionError(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadCurrentLocation();
  }

  void _emitActionError(Object error, StackTrace stackTrace) {
    _errorHandler?.handle(error, stackTrace);

    emit(
      state.copyWith(
        status: LocationFlowStatus.error,
        message:
            'No fue posible completar la acción de ubicación. Intenta nuevamente.',
        clearLocation: true,
        clearPlaceName: true,
      ),
    );
  }

  String _mapLocationFailureMessage(Failure failure) {
    switch (failure.code) {
      case 'CUS_LOC_001':
        return 'Activa tu ubicación para ver talleres y servicios cercanos.';
      case 'CUS_LOC_002':
        return 'Enciende el GPS del dispositivo para continuar.';
      case 'CUS_LOC_003':
        return 'No pudimos obtener una ubicación válida. Intenta nuevamente.';
      case 'CUS_LOC_004':
        return 'La ubicación no está disponible en este momento. Intenta más tarde.';
      case 'CUS_LOC_005':
        return 'La ubicación está restringida por el sistema operativo.';
      case 'NET_002':
        return 'La ubicación tardó demasiado en responder. Intenta nuevamente.';
      default:
        return 'No pudimos obtener tu ubicación en este momento. Intenta nuevamente.';
    }
  }
}
