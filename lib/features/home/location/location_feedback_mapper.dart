import 'package:flutter/material.dart';

import '../../../core/location/location_state.dart';
import 'location_feedback_text.dart';

LocationFeedbackText mapLocationFeedback(LocationState state) {
  final effectiveStatus = state.effectiveStatus;

  switch (effectiveStatus) {
    case LocationFlowStatus.success:
      return LocationFeedbackText(
        title: state.placeName != null && state.placeName!.trim().isNotEmpty
            ? 'Entregando en ${_compactPlaceName(state.placeName!)}'
            : 'Ubicación detectada',
        subtitle: 'Mostraremos talleres y servicios cercanos.',
        primaryActionLabel: 'Usar ubicación',
        leadingIcon: Icons.location_on_outlined,
      );
    case LocationFlowStatus.permissionRequired:
      return const LocationFeedbackText(
        title: 'Usa tu ubicación',
        subtitle: 'Actívala para ver opciones cercanas.',
        primaryActionLabel: 'Activar',
        leadingIcon: Icons.location_searching_outlined,
      );
    case LocationFlowStatus.deniedForever:
      return const LocationFeedbackText(
        title: 'Ubicación bloqueada',
        subtitle: 'Actívala desde configuración.',
        primaryActionLabel: 'Configuración',
        leadingIcon: Icons.location_off_outlined,
      );
    case LocationFlowStatus.serviceDisabled:
      return const LocationFeedbackText(
        title: 'Activa tu ubicación',
        subtitle: 'Enciende tu ubicación para continuar.',
        primaryActionLabel: 'Encender GPS',
        leadingIcon: Icons.gps_off_outlined,
      );
    case LocationFlowStatus.restricted:
      return LocationFeedbackText(
        title: 'Ubicación restringida',
        subtitle:
            state.message ??
            'La ubicación no está disponible en este dispositivo.',
        primaryActionLabel: 'Entendido',
        leadingIcon: Icons.info_outline,
      );
    case LocationFlowStatus.requestingPermission:
      return const LocationFeedbackText(
        title: 'Solicitando permiso',
        subtitle: 'Esperando tu respuesta para acceder a la ubicación.',
        primaryActionLabel: 'Esperando...',
        leadingIcon: Icons.location_searching_outlined,
      );
    case LocationFlowStatus.error:
      return LocationFeedbackText(
        title: 'No pudimos ubicarte',
        subtitle: state.message ?? 'Intenta de nuevo en unos segundos.',
        primaryActionLabel: 'Reintentar',
        leadingIcon: Icons.error_outline,
      );
    case LocationFlowStatus.initial:
    case LocationFlowStatus.loading:
      return const LocationFeedbackText(
        title: 'Buscando tu ubicación',
        subtitle: 'Consultando ubicación del dispositivo...',
        primaryActionLabel: 'Cargando...',
        leadingIcon: Icons.location_searching_outlined,
      );
  }
}

String _compactPlaceName(String value) {
  final parts = value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.length >= 2) {
    return '${parts[0]}, ${parts[1]}';
  }

  return value;
}
