import 'package:flutter/material.dart';

import '../../../core/location/location_state.dart';
import '../location/location_feedback_mapper.dart';
import '../location/location_feedback_text.dart';

class DeliveryLocationCard extends StatelessWidget {
  const DeliveryLocationCard({
    super.key,
    required this.state,
    required this.onTap,
  });

  final LocationState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLoading = state.status == LocationFlowStatus.loading;
    final isRequestingPermission =
        state.status == LocationFlowStatus.requestingPermission;
    final isBusy = isLoading || isRequestingPermission;
    final showLoadingCopy = isLoading && state.lastSettledStatus == null;
    final feedback = mapLocationFeedback(state);
    final status = state.effectiveStatus;
    final title = _headlineFor(status, feedback, showLoadingCopy);
    final subtitle = _subtitleFor(status, feedback, showLoadingCopy);
    final label = _labelFor(status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                const SizedBox(width: 20, height: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3FA572),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF181411),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 1),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF181411),
                            size: 16,
                          ),
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B5F57),
                            fontSize: 10,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: isBusy
                      ? const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(LocationFlowStatus status) {
    return switch (status) {
      LocationFlowStatus.success => 'Entregar ahora',
      LocationFlowStatus.requestingPermission => 'Confirmando acceso',
      LocationFlowStatus.loading ||
      LocationFlowStatus.initial => 'Buscando cerca de ti',
      LocationFlowStatus.permissionRequired => 'Entregar ahora',
      LocationFlowStatus.deniedForever => 'Permiso de ubicacion',
      LocationFlowStatus.serviceDisabled => 'Ubicacion desactivada',
      LocationFlowStatus.restricted => 'Ubicacion restringida',
      LocationFlowStatus.error => 'No pudimos confirmar tu zona',
    };
  }

  String _headlineFor(
    LocationFlowStatus status,
    LocationFeedbackText feedback,
    bool isLoading,
  ) {
    if (isLoading) {
      return 'Buscando tu ubicacion actual';
    }

    return switch (status) {
      LocationFlowStatus.success => feedback.title.replaceFirst(
        'Entregando en ',
        '',
      ),
      LocationFlowStatus.permissionRequired => 'Elegir direccion',
      LocationFlowStatus.deniedForever => 'Abrir configuracion',
      LocationFlowStatus.serviceDisabled => 'Encender GPS',
      LocationFlowStatus.restricted => 'Ubicacion no disponible',
      LocationFlowStatus.requestingPermission =>
        'Confirma el acceso a tu ubicacion',
      LocationFlowStatus.error => 'No pudimos confirmar tu direccion',
      LocationFlowStatus.initial ||
      LocationFlowStatus.loading => 'Buscando tu ubicacion actual',
    };
  }

  String _subtitleFor(
    LocationFlowStatus status,
    LocationFeedbackText feedback,
    bool isLoading,
  ) {
    if (isLoading) {
      return 'Estamos consultando la ubicacion del dispositivo para mostrarte talleres cercanos.';
    }

    return switch (status) {
      LocationFlowStatus.success => '',
      LocationFlowStatus.permissionRequired =>
        'Usa tu ubicacion actual para descubrir talleres y servicios cercanos.',
      LocationFlowStatus.deniedForever =>
        'Necesitamos que habilites el permiso desde la configuracion del telefono.',
      LocationFlowStatus.serviceDisabled =>
        'Activa la ubicacion del dispositivo para ver resultados cercanos.',
      LocationFlowStatus.restricted => feedback.subtitle,
      LocationFlowStatus.requestingPermission =>
        'Estamos esperando tu respuesta para poder ubicar tu zona de entrega.',
      LocationFlowStatus.error => feedback.subtitle,
      LocationFlowStatus.initial || LocationFlowStatus.loading =>
        'Estamos consultando la ubicacion del dispositivo para mostrarte talleres cercanos.',
    };
  }
}
