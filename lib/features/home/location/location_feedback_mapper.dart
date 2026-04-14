import 'package:flutter/material.dart';

import 'location_feedback_text.dart';

LocationFeedbackText mapLocationFeedback({
  required String? placeName,
  required String? fallbackMessage,
  required String stateType,
}) {
  switch (stateType) {
    case 'success':
      return LocationFeedbackText(
        title: placeName != null && placeName.trim().isNotEmpty
            ? 'Entregando en ${_compactPlaceName(placeName)}'
            : 'Ubicación detectada',
        subtitle: 'Mostraremos talleres y servicios cercanos.',
        primaryActionLabel: 'Usar ubicación',
        leadingIcon: Icons.location_on_outlined,
        showRefreshAction: true,
      );
    case 'permissionRequired':
      return const LocationFeedbackText(
        title: 'Usa tu ubicación',
        subtitle: 'Actívala para ver opciones cercanas.',
        primaryActionLabel: 'Activar',
        leadingIcon: Icons.location_searching_outlined,
        showRefreshAction: false,
      );
    case 'deniedForever':
      return const LocationFeedbackText(
        title: 'Ubicación bloqueada',
        subtitle: 'Actívala desde configuración.',
        primaryActionLabel: 'Configuración',
        leadingIcon: Icons.location_off_outlined,
        showRefreshAction: false,
      );
    case 'serviceDisabled':
      return const LocationFeedbackText(
        title: 'Activa tu ubicación',
        subtitle: 'Enciende tu ubicación para continuar.',
        primaryActionLabel: 'Encender GPS',
        leadingIcon: Icons.gps_off_outlined,
        showRefreshAction: false,
      );
    case 'restricted':
      return const LocationFeedbackText(
        title: 'Ubicación restringida',
        subtitle: 'La ubicación no está disponible en este dispositivo.',
        primaryActionLabel: 'Entendido',
        leadingIcon: Icons.info_outline,
        showRefreshAction: false,
      );
    case 'requestingPermission':
      return const LocationFeedbackText(
        title: 'Solicitando permiso',
        subtitle: 'Esperando tu respuesta para acceder a la ubicación.',
        primaryActionLabel: 'Esperando...',
        leadingIcon: Icons.location_searching_outlined,
        showRefreshAction: false,
      );
    default:
      return LocationFeedbackText(
        title: 'No pudimos ubicarte',
        subtitle: fallbackMessage ?? 'Intenta de nuevo en unos segundos.',
        primaryActionLabel: 'Reintentar',
        leadingIcon: Icons.error_outline,
        showRefreshAction: true,
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
