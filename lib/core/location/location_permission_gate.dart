import 'package:flutter/material.dart';

import '../di/app_injection.dart';
import 'location_permission_service.dart';

class LocationPermissionGate extends StatefulWidget {
  const LocationPermissionGate({
    super.key,
    required this.child,
    this.autoRequest = true,
  });

  final Widget child;
  final bool autoRequest;

  @override
  State<LocationPermissionGate> createState() => _LocationPermissionGateState();
}

class _LocationPermissionGateState extends State<LocationPermissionGate> {
  static bool _hasRequestedInCurrentSession = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestLocationPermissionIfNeeded();
      });
    }
  }

  Future<void> _requestLocationPermissionIfNeeded() async {
    if (_hasRequestedInCurrentSession || !mounted) {
      return;
    }

    _hasRequestedInCurrentSession = true;

    final locationPermissionService = sl<LocationPermissionService>();

    try {
      final currentPermissionStatus = await locationPermissionService
          .getPermissionStatus();
      if (currentPermissionStatus == LocationPermissionStatus.granted) {
        return;
      }

      final result = await locationPermissionService
          .requestWhileInUsePermission();

      if (!mounted) {
        return;
      }

      switch (result) {
        case LocationPermissionRequestResult.granted:
        case LocationPermissionRequestResult.denied:
          return;
        case LocationPermissionRequestResult.deniedForever:
          _showMessage(
            'La ubicacion fue denegada permanentemente. Actívala desde la configuración de la app.',
          );
        case LocationPermissionRequestResult.serviceDisabled:
          _showMessage(
            'Activa la ubicacion del dispositivo para usar funciones basadas en tu posicion.',
          );
        case LocationPermissionRequestResult.restricted:
          _showMessage(
            'La ubicacion esta restringida por el sistema operativo en este dispositivo.',
          );
      }
    } catch (_) {
      // Ignore permission prompt failures so home rendering is never blocked.
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
