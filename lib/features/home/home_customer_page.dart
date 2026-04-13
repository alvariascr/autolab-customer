import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/app_injection.dart';
import '../../core/location/current_location.dart';
import '../../core/location/current_location_data_source.dart';
import '../../core/location/location_permission_gate.dart';
import '../../core/location/location_permission_service.dart';
import '../../core/location/location_place_resolver.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import 'location/location_feedback_text.dart';
import 'location/location_feedback_mapper.dart';

class HomeCustomerPage extends StatefulWidget {
  const HomeCustomerPage({super.key});

  @override
  State<HomeCustomerPage> createState() => _HomeCustomerPageState();
}

class _HomeCustomerPageState extends State<HomeCustomerPage>
    with WidgetsBindingObserver {
  late Future<_LocationCardState> _locationFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationFuture = _loadCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLocation();
    }
  }

  void _refreshLocation() {
    if (!mounted) {
      return;
    }

    setState(() {
      _locationFuture = _loadCurrentLocation();
    });
  }

  Future<_LocationCardState> _loadCurrentLocation() async {
    final permissionService = sl<LocationPermissionService>();
    final permissionStatus = await permissionService.getPermissionStatus();

    switch (permissionStatus) {
      case LocationPermissionStatus.granted:
        break;
      case LocationPermissionStatus.denied:
        return const _LocationCardState.permissionRequired();
      case LocationPermissionStatus.deniedForever:
        return const _LocationCardState.deniedForever();
      case LocationPermissionStatus.restricted:
        return const _LocationCardState.restricted();
      case LocationPermissionStatus.serviceDisabled:
        return const _LocationCardState.serviceDisabled();
    }

    final result = await sl<CurrentLocationDataSource>().getCurrentLocation();

    return await result.fold(
      (failure) async =>
          _LocationCardState.error(_mapLocationFailureMessage(failure)),
      (location) async {
        try {
          final resolution = await sl<LocationPlaceResolver>().resolvePlaceName(
            location,
          );

          return _LocationCardState.success(
            location,
            placeName: resolution.placeName,
          );
        } catch (error, stackTrace) {
          if (CoreDI.instance.isRegistered<GlobalErrorHandler>()) {
            CoreDI.get<GlobalErrorHandler>().handle(error, stackTrace);
          }

          return _LocationCardState.success(location);
        }
      },
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

  Future<void> _handleLocationAction(_LocationCardState state) async {
    final permissionService = sl<LocationPermissionService>();

    try {
      switch (state.type) {
        case _LocationCardStateType.permissionRequired:
          final shouldRequest = await _showLocationPermissionPrePrompt();
          if (shouldRequest != true || !mounted) {
            return;
          }

          final result = await permissionService.requestWhileInUsePermission();
          if (!mounted) {
            return;
          }

          switch (result) {
            case LocationPermissionRequestResult.granted:
            case LocationPermissionRequestResult.denied:
            case LocationPermissionRequestResult.deniedForever:
            case LocationPermissionRequestResult.restricted:
            case LocationPermissionRequestResult.serviceDisabled:
              _refreshLocation();
              return;
          }
        case _LocationCardStateType.deniedForever:
          await permissionService.openAppSettings();
          return;
        case _LocationCardStateType.serviceDisabled:
          await permissionService.openLocationSettings();
          return;
        case _LocationCardStateType.restricted:
          _refreshLocation();
          return;
        case _LocationCardStateType.success:
        case _LocationCardStateType.error:
          _refreshLocation();
          return;
      }
    } catch (error, stackTrace) {
      if (CoreDI.instance.isRegistered<GlobalErrorHandler>()) {
        CoreDI.get<GlobalErrorHandler>().handle(error, stackTrace);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _locationFuture = Future.value(
          const _LocationCardState.error(
            'No fue posible completar la acción de ubicación. Intenta nuevamente.',
          ),
        );
      });
    }
  }

  Future<bool?> _showLocationPermissionPrePrompt() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Usa tu ubicación'),
          content: const Text(
            'Activa tu ubicación para mostrar talleres, servicios y opciones cercanas a ti.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LocationPermissionGate(
      autoRequest: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F4EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F4EF),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 20,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Autolab Repuestos',
                style: TextStyle(
                  color: Color(0xFF181411),
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Encuentra talleres y servicios cercanos.',
                style: TextStyle(color: Color(0xFF6B5F57), fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
              },
              icon: const Icon(Icons.logout, color: Color(0xFF181411)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<_LocationCardState>(
                      future: _locationFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const _TopLocationBar.loading();
                        }

                        final state =
                            snapshot.data ??
                            const _LocationCardState.error(
                              'No fue posible consultar la ubicacion actual.',
                            );

                        return _TopLocationBar(
                          state: state,
                          onPrimaryAction: () => _handleLocationAction(state),
                          onRefresh: _refreshLocation,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const _HomePlaceholder(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopLocationBar extends StatelessWidget {
  const _TopLocationBar({
    required this.state,
    required this.onPrimaryAction,
    required this.onRefresh,
  }) : isLoading = false;

  const _TopLocationBar.loading()
    : state = null,
      onPrimaryAction = _noop,
      onRefresh = _noop,
      isLoading = true;

  final _LocationCardState? state;
  final VoidCallback onPrimaryAction;
  final VoidCallback onRefresh;
  final bool isLoading;

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final effectiveState =
        state ??
        const _LocationCardState.error(
          'No fue posible consultar la ubicacion actual.',
        );
    final feedback = effectiveState.feedback;
    final title = isLoading ? 'Buscando tu ubicación' : feedback.title;
    final subtitle = isLoading
        ? 'Consultando ubicación del dispositivo...'
        : feedback.subtitle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9DDD2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLoading
                  ? Icons.location_searching_outlined
                  : feedback.leadingIcon,
              size: 18,
              color: const Color(0xFF9B3D24),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF181411),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B5F57),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (feedback.showRefreshAction)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: onRefresh,
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EAFE),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          size: 16,
                          color: Color(0xFF5B3CC4),
                        ),
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: onPrimaryAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF181411),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(feedback.primaryActionLabel),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9DDD2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explora talleres cerca de ti',
            style: TextStyle(
              color: Color(0xFF181411),
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Este espacio queda libre para integrar carruseles, listados y resultados dinámicos sin mezclar contenido demo dentro del home.',
            style: TextStyle(
              color: Color(0xFF6B5F57),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCardState {
  const _LocationCardState.success(this.location, {this.placeName})
    : message = null,
      type = _LocationCardStateType.success;

  const _LocationCardState.error(this.message)
    : location = null,
      placeName = null,
      type = _LocationCardStateType.error;

  const _LocationCardState.permissionRequired()
    : location = null,
      placeName = null,
      message = null,
      type = _LocationCardStateType.permissionRequired;

  const _LocationCardState.deniedForever()
    : location = null,
      placeName = null,
      message = null,
      type = _LocationCardStateType.deniedForever;

  const _LocationCardState.serviceDisabled()
    : location = null,
      placeName = null,
      message = null,
      type = _LocationCardStateType.serviceDisabled;

  const _LocationCardState.restricted()
    : location = null,
      placeName = null,
      message = null,
      type = _LocationCardStateType.restricted;

  final CurrentLocation? location;
  final String? placeName;
  final String? message;
  final _LocationCardStateType type;

  String get _stateKey {
    return switch (type) {
      _LocationCardStateType.success => 'success',
      _LocationCardStateType.permissionRequired => 'permissionRequired',
      _LocationCardStateType.deniedForever => 'deniedForever',
      _LocationCardStateType.serviceDisabled => 'serviceDisabled',
      _LocationCardStateType.restricted => 'restricted',
      _LocationCardStateType.error => 'error',
    };
  }

  LocationFeedbackText get feedback => mapLocationFeedback(
    placeName: placeName,
    fallbackMessage: message,
    stateType: _stateKey,
  );
}

enum _LocationCardStateType {
  success,
  permissionRequired,
  deniedForever,
  serviceDisabled,
  restricted,
  error,
}
