import '../../../core/location/location_state.dart';

class WorkshopEmptyStateResolver {
  const WorkshopEmptyStateResolver();

  String resolve(
    LocationState locationState, {
    bool isUsingFallbackLocation = false,
  }) {
    return switch (locationState.status) {
      LocationFlowStatus.initial ||
      LocationFlowStatus.loading ||
      LocationFlowStatus.requestingPermission =>
        'Buscando talleres cercanos...',
      LocationFlowStatus.permissionRequired ||
      LocationFlowStatus.deniedForever ||
      LocationFlowStatus.serviceDisabled ||
      LocationFlowStatus.restricted =>
        'Activa tu ubicación para ver talleres cercanos.',
      LocationFlowStatus.error =>
        locationState.message ??
            'No pudimos obtener tu ubicación para buscar talleres cercanos.',
      LocationFlowStatus.success =>
        'No encontramos talleres cercanos a tu ubicación actual.',
    };
  }
}
