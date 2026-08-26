import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../errors/customer_error_catalog.dart';
import '../logging/feature_logger.dart';
import 'current_location.dart';
import 'current_location_data_source.dart';
import 'location_flow_recovery_service.dart';
import 'location_permission_service.dart';
import 'location_place_resolver.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit(
    this._permissionService,
    this._currentLocationDataSource,
    this._placeResolver, {
    required LocationFlowRecoveryService flowRecoveryService,
    GlobalErrorHandler? errorHandler,
    FeatureLogger? featureLogger,
  }) : _flowRecoveryService = flowRecoveryService,
       _errorHandler = errorHandler,
       _featureLogger = featureLogger,
       super(const LocationState.initial());

  final LocationPermissionService _permissionService;
  final CurrentLocationDataSource _currentLocationDataSource;
  final LocationPlaceResolver _placeResolver;
  final LocationFlowRecoveryService _flowRecoveryService;
  final GlobalErrorHandler? _errorHandler;
  final FeatureLogger? _featureLogger;
  StreamSubscription<Position>? _positionSubscription;

  Future<void> initialize() async {
    final pendingSettingsSync = await _flowRecoveryService
        .consumePendingSettingsSync();
    _featureLogger?.info(
      feature: 'location',
      action: 'initialize',
      context: {'pendingSettingsSync': pendingSettingsSync},
    );
    await loadCurrentLocation(requestPermissionIfNeeded: !pendingSettingsSync);
  }

  Future<void> loadCurrentLocation({
    bool requestPermissionIfNeeded = false,
  }) async {
    _featureLogger?.info(
      feature: 'location',
      action: 'load_current_location_started',
      context: {'requestPermissionIfNeeded': requestPermissionIfNeeded},
    );
    emit(state.copyWith(status: LocationFlowStatus.loading));

    final permissionStatus = await _permissionService.getPermissionStatus();

    switch (permissionStatus) {
      case LocationPermissionStatus.granted:
        break;
      case LocationPermissionStatus.denied:
        if (requestPermissionIfNeeded) {
          await requestPermission();
          return;
        }
        if (state.permissionDeniedCount >= 2) {
          _emitStableState(
            status: LocationFlowStatus.deniedForever,
            clearLocation: true,
            clearPlaceName: true,
            clearMessage: true,
            clearFailureCode: true,
            clearFailureUiKey: true,
          );
          return;
        }
        _emitStableState(
          status: LocationFlowStatus.permissionRequired,
          clearLocation: true,
          clearPlaceName: true,
          clearMessage: true,
          clearFailureCode: true,
          clearFailureUiKey: true,
        );
        return;
      case LocationPermissionStatus.deniedForever:
        _emitStableState(
          status: LocationFlowStatus.deniedForever,
          clearLocation: true,
          clearPlaceName: true,
          clearMessage: true,
          clearFailureCode: true,
          clearFailureUiKey: true,
        );
        return;
      case LocationPermissionStatus.restricted:
        _emitStableState(
          status: LocationFlowStatus.restricted,
          failureCode: CustomerErrorCatalog.locationPermissionRestricted.code,
          failureUiKey: CustomerErrorCatalog.locationPermissionRestricted.uiKey,
          clearLocation: true,
          clearPlaceName: true,
        );
        return;
      case LocationPermissionStatus.serviceDisabled:
        _emitStableState(
          status: LocationFlowStatus.serviceDisabled,
          clearLocation: true,
          clearPlaceName: true,
          clearMessage: true,
          clearFailureCode: true,
          clearFailureUiKey: true,
        );
        return;
    }

    final result = await _currentLocationDataSource.getCurrentLocation();

    await result.fold(
      (failure) async {
        _featureLogger?.warn(
          feature: 'location',
          action: 'load_current_location_failed',
          code: failure.code,
          context: {'uiKey': failure.uiKey},
          error: failure.cause,
          stackTrace: failure.stackTrace,
        );
        _emitStableState(
          status: LocationFlowStatus.error,
          message: failure.message,
          failureCode: failure.code,
          failureUiKey: failure.uiKey,
          clearLocation: true,
          clearPlaceName: true,
        );
      },
      (location) async {
        try {
          final resolution = await _placeResolver.resolvePlaceName(location);
          _featureLogger?.info(
            feature: 'location',
            action: 'load_current_location_succeeded',
            context: {
              'latitude': location.latitude,
              'longitude': location.longitude,
              'hasPlaceName': resolution.placeName?.isNotEmpty ?? false,
            },
          );

          _emitStableState(
            status: LocationFlowStatus.success,
            location: location,
            placeName: resolution.placeName,
            clearMessage: true,
            clearFailureCode: true,
            clearFailureUiKey: true,
          );
        } catch (error, stackTrace) {
          _errorHandler?.handle(error, stackTrace);
          _featureLogger?.warn(
            feature: 'location',
            action: 'resolve_place_name_failed',
            error: error,
            stackTrace: stackTrace,
          );

          _emitStableState(
            status: LocationFlowStatus.success,
            location: location,
            clearPlaceName: true,
            clearMessage: true,
            clearFailureCode: true,
            clearFailureUiKey: true,
          );
        }
      },
    );
  }

  Future<void> requestPermission() async {
    try {
      _featureLogger?.info(
        feature: 'location',
        action: 'request_permission_started',
      );
      emit(state.copyWith(status: LocationFlowStatus.requestingPermission));

      final result = await _permissionService.requestWhileInUsePermission();

      switch (result) {
        case LocationPermissionRequestResult.granted:
          emit(state.copyWith(permissionDeniedCount: 0));
          await loadCurrentLocation();
          return;
        case LocationPermissionRequestResult.denied:
          final nextDeniedCount = state.permissionDeniedCount + 1;
          if (nextDeniedCount >= 2) {
            _emitStableState(
              status: LocationFlowStatus.deniedForever,
              permissionDeniedCount: nextDeniedCount,
              clearLocation: true,
              clearPlaceName: true,
              clearMessage: true,
              clearFailureCode: true,
              clearFailureUiKey: true,
            );
            return;
          }
          _emitStableState(
            status: LocationFlowStatus.permissionRequired,
            permissionDeniedCount: nextDeniedCount,
            clearLocation: true,
            clearPlaceName: true,
            clearMessage: true,
            clearFailureCode: true,
            clearFailureUiKey: true,
          );
          return;
        case LocationPermissionRequestResult.deniedForever:
          _emitStableState(
            status: LocationFlowStatus.deniedForever,
            permissionDeniedCount: state.permissionDeniedCount + 1,
            clearLocation: true,
            clearPlaceName: true,
            clearMessage: true,
            clearFailureCode: true,
            clearFailureUiKey: true,
          );
          return;
        case LocationPermissionRequestResult.restricted:
          _emitStableState(
            status: LocationFlowStatus.restricted,
            failureCode: CustomerErrorCatalog.locationPermissionRestricted.code,
            failureUiKey:
                CustomerErrorCatalog.locationPermissionRestricted.uiKey,
            clearLocation: true,
            clearPlaceName: true,
          );
          return;
        case LocationPermissionRequestResult.serviceDisabled:
          _emitStableState(
            status: LocationFlowStatus.serviceDisabled,
            clearLocation: true,
            clearPlaceName: true,
            clearMessage: true,
            clearFailureCode: true,
            clearFailureUiKey: true,
          );
          return;
      }
    } catch (error, stackTrace) {
      _emitActionError(error, stackTrace);
    }
  }

  Future<void> openAppSettings() async {
    try {
      _featureLogger?.info(
        feature: 'location',
        action: 'open_app_settings_started',
      );
      await _flowRecoveryService.markPendingSettingsSync();
      final opened = await _permissionService.openAppSettings();
      if (!opened) {
        throw StateError('openAppSettings returned false');
      }
    } catch (error, stackTrace) {
      _emitActionError(error, stackTrace);
    }
  }

  Future<void> openLocationSettings() async {
    try {
      _featureLogger?.info(
        feature: 'location',
        action: 'open_location_settings_started',
      );
      await _flowRecoveryService.markPendingSettingsSync();
      final opened = await _permissionService.openLocationSettings();
      if (!opened) {
        throw StateError('openLocationSettings returned false');
      }
    } catch (error, stackTrace) {
      _emitActionError(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    _featureLogger?.info(feature: 'location', action: 'refresh_started');
    await loadCurrentLocation();
  }

  void useSavedLocation({
    required CurrentLocation location,
    required String placeName,
  }) {
    if (!location.hasValidCoordinates) {
      _emitStableState(
        status: LocationFlowStatus.error,
        failureCode: CustomerErrorCatalog.invalidCurrentLocation.code,
        failureUiKey: CustomerErrorCatalog.invalidCurrentLocation.uiKey,
        clearLocation: true,
        clearPlaceName: true,
      );
      return;
    }

    _featureLogger?.info(
      feature: 'location',
      action: 'use_saved_location',
      context: {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'hasPlaceName': placeName.trim().isNotEmpty,
      },
    );

    _emitStableState(
      status: LocationFlowStatus.success,
      location: location,
      placeName: placeName.trim().isEmpty ? null : placeName.trim(),
      clearMessage: true,
      clearFailureCode: true,
      clearFailureUiKey: true,
    );
  }

  @override
  Future<void> close() async {
    await _positionSubscription?.cancel();
    return super.close();
  }

  void _emitStableState({
    required LocationFlowStatus status,
    CurrentLocation? location,
    String? placeName,
    String? message,
    String? failureCode,
    String? failureUiKey,
    int? permissionDeniedCount,
    bool clearLocation = false,
    bool clearPlaceName = false,
    bool clearMessage = false,
    bool clearFailureCode = false,
    bool clearFailureUiKey = false,
  }) {
    emit(
      state.copyWith(
        status: status,
        location: location,
        placeName: placeName,
        message: message,
        failureCode: failureCode,
        failureUiKey: failureUiKey,
        lastSettledStatus: status,
        permissionDeniedCount: permissionDeniedCount,
        clearLocation: clearLocation,
        clearPlaceName: clearPlaceName,
        clearMessage: clearMessage,
        clearFailureCode: clearFailureCode,
        clearFailureUiKey: clearFailureUiKey,
      ),
    );
  }

  void _emitActionError(Object error, StackTrace stackTrace) {
    _errorHandler?.handle(error, stackTrace);
    _featureLogger?.error(
      feature: 'location',
      action: 'location_action_failed',
      code: CustomerErrorCatalog.locationActionFailed.code,
      context: {'uiKey': CustomerErrorCatalog.locationActionFailed.uiKey},
      error: error,
      stackTrace: stackTrace,
    );

    _emitStableState(
      status: LocationFlowStatus.error,
      failureCode: CustomerErrorCatalog.locationActionFailed.code,
      failureUiKey: CustomerErrorCatalog.locationActionFailed.uiKey,
      clearLocation: true,
      clearPlaceName: true,
    );
  }
}
