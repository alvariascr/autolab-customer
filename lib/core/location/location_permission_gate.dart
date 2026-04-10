import 'package:flutter/material.dart';

import '../di/app_injection.dart';
import 'location_permission_service.dart';

class LocationPermissionGate extends StatefulWidget {
  const LocationPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<LocationPermissionGate> createState() => _LocationPermissionGateState();
}

class _LocationPermissionGateState extends State<LocationPermissionGate> {
  static bool _hasRequestedInCurrentSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermissionIfNeeded();
    });
  }

  Future<void> _requestLocationPermissionIfNeeded() async {
    if (_hasRequestedInCurrentSession || !mounted) {
      return;
    }

    _hasRequestedInCurrentSession = true;

    final locationPermissionService = sl<LocationPermissionService>();

    try {
      final currentPermission = await locationPermissionService
          .checkPermission();
      if (currentPermission == LocationPermissionStatus.granted) {
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
            action: SnackBarAction(
              label: 'Configurar',
              onPressed: () {
                locationPermissionService.openAppSettings();
              },
            ),
          );
        case LocationPermissionRequestResult.serviceDisabled:
          _showMessage(
            'Activa la ubicacion del dispositivo para usar funciones basadas en tu posicion.',
          );
      }
    } catch (error, stackTrace) {
      debugPrint('Location permission request failed: $error\n$stackTrace');
    }
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
