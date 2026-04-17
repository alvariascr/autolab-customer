import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/location/location_cubit.dart';
import '../../core/location/location_state.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../workshops/data/datasources/workshop_remote_data_source_impl.dart';
import '../workshops/data/repositories/workshop_repository_impl.dart';
import '../workshops/domain/entities/workshop.dart';
import '../workshops/domain/services/workshop_proximity_filter.dart';
import '../workshops/domain/services/workshop_search_location_resolver.dart';
import '../workshops/presentation/workshop_empty_state_resolver.dart';
import '../workshops/presentation/widgets/nearby_workshops_map.dart';
import '../workshops/presentation/widgets/workshops_carousel.dart';
import 'location/location_feedback_mapper.dart';
import 'location/location_feedback_text.dart';

class HomeCustomerPage extends StatefulWidget {
  const HomeCustomerPage({super.key});

  @override
  State<HomeCustomerPage> createState() => _HomeCustomerPageState();
}

class _HomeCustomerPageState extends State<HomeCustomerPage>
    with WidgetsBindingObserver {
  static const _workshopProximityFilter = WorkshopProximityFilter();
  static const _workshopSearchLocationResolver =
      WorkshopSearchLocationResolver();
  static const _workshopEmptyStateResolver = WorkshopEmptyStateResolver();

  late Future<List<Workshop>> _workshopsFuture;
  bool _didTriggerInitialLocationLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialLocationLoad();
    });
    _workshopsFuture = _loadWorkshops();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_didTriggerInitialLocationLoad) {
        _triggerInitialLocationLoad();
        return;
      }
      context.read<LocationCubit>().refresh();
    }
  }

  Future<List<Workshop>> _loadWorkshops() async {
    try {
      final client = Supabase.instance.client;
      final dataSource = WorkshopRemoteDataSourceImpl(client);
      final repository = WorkshopRepositoryImpl(remoteDataSource: dataSource);
      return await repository.getWorkshops();
    } catch (_) {
      return const <Workshop>[];
    }
  }

  void _triggerInitialLocationLoad() {
    if (_didTriggerInitialLocationLoad || !mounted) {
      return;
    }

    _didTriggerInitialLocationLoad = true;

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }

      context.read<LocationCubit>().initialize();
    });
  }

  Future<void> _handleLocationAction(LocationState state) async {
    final locationCubit = context.read<LocationCubit>();
    final actionStatus = state.effectiveStatus;

    switch (actionStatus) {
      case LocationFlowStatus.permissionRequired:
        await locationCubit.requestPermission();
        return;
      case LocationFlowStatus.requestingPermission:
        return;
      case LocationFlowStatus.deniedForever:
        await locationCubit.openAppSettings();
        return;
      case LocationFlowStatus.serviceDisabled:
        await locationCubit.openLocationSettings();
        return;
      case LocationFlowStatus.restricted:
        await locationCubit.refresh();
        return;
      case LocationFlowStatus.success:
      case LocationFlowStatus.error:
      case LocationFlowStatus.initial:
      case LocationFlowStatus.loading:
        await locationCubit.refresh();
        return;
    }
  }

  Future<void> _showLocationOptions(LocationState state) async {
    final actionStatus = state.effectiveStatus;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona dónde entregar',
                    style: TextStyle(
                      color: Color(0xFF181411),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Puedes usar tu ubicación actual o elegir una dirección guardada más adelante.',
                    style: TextStyle(
                      color: Color(0xFF6B5F57),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _LocationOptionTile(
                    icon: Icons.my_location_outlined,
                    title: _useCurrentLocationLabelFor(actionStatus),
                    subtitle: _useCurrentLocationSubtitleFor(actionStatus),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _handleLocationAction(state);
                    },
                  ),
                  const SizedBox(height: 10),
                  const _LocationOptionTile(
                    icon: Icons.search_rounded,
                    title: 'Escribir dirección',
                    subtitle: 'Lo conectamos en el siguiente paso del home.',
                  ),
                  const SizedBox(height: 10),
                  const _LocationOptionTile(
                    icon: Icons.home_outlined,
                    title: 'Casa',
                    subtitle:
                        'Próximamente podrás guardar tus direcciones favoritas.',
                  ),
                  const SizedBox(height: 10),
                  const _LocationOptionTile(
                    icon: Icons.work_outline_rounded,
                    title: 'Trabajo',
                    subtitle:
                        'Próximamente podrás guardar tus direcciones favoritas.',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _useCurrentLocationLabelFor(LocationFlowStatus status) {
    return switch (status) {
      LocationFlowStatus.success => 'Actualizar ubicación actual',
      LocationFlowStatus.deniedForever => 'Abrir configuración',
      LocationFlowStatus.serviceDisabled => 'Encender GPS',
      LocationFlowStatus.requestingPermission => 'Esperando permiso',
      _ => 'Usar ubicación actual',
    };
  }

  String _useCurrentLocationSubtitleFor(LocationFlowStatus status) {
    return switch (status) {
      LocationFlowStatus.success =>
        'Volver a consultar tu ubicación para actualizar los resultados.',
      LocationFlowStatus.deniedForever =>
        'Habilita el permiso de ubicación desde la configuración del teléfono.',
      LocationFlowStatus.serviceDisabled =>
        'Activa la ubicación del dispositivo para ver talleres cercanos.',
      LocationFlowStatus.requestingPermission =>
        'Estamos esperando tu respuesta para acceder a la ubicación.',
      _ => 'Usa el GPS del teléfono para ver talleres y servicios cerca de ti.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4EF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 46,
        leadingWidth: 52,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            icon: const Icon(Icons.logout, color: Color(0xFF181411), size: 20),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<LocationCubit, LocationState>(
                    builder: (context, state) {
                      return _DeliveryLocationCard(
                        state: state,
                        onTap: () => _showLocationOptions(state),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  BlocBuilder<LocationCubit, LocationState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          _WorkshopsSection(
                            workshopsFuture: _workshopsFuture,
                            locationState: state,
                            proximityFilter: _workshopProximityFilter,
                            emptyStateResolver: _workshopEmptyStateResolver,
                          ),
                          const SizedBox(height: 24),
                          _NearbyWorkshopsMapSection(
                            workshopsFuture: _workshopsFuture,
                            locationState: state,
                            proximityFilter: _workshopProximityFilter,
                            emptyStateResolver: _workshopEmptyStateResolver,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryLocationCard extends StatelessWidget {
  const _DeliveryLocationCard({required this.state, required this.onTap});

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
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isBusy ? null : onTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
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
                        mainAxisSize: MainAxisSize.min,
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
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: isBusy
                ? const Padding(
                    padding: EdgeInsets.only(top: 8, right: 2),
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
    );
  }

  String _labelFor(LocationFlowStatus status) {
    return switch (status) {
      LocationFlowStatus.success => 'Entregar ahora',
      LocationFlowStatus.requestingPermission => 'Confirmando acceso',
      LocationFlowStatus.loading ||
      LocationFlowStatus.initial => 'Buscando cerca de ti',
      LocationFlowStatus.permissionRequired => 'Entregar ahora',
      LocationFlowStatus.deniedForever => 'Permiso de ubicación',
      LocationFlowStatus.serviceDisabled => 'Ubicación desactivada',
      LocationFlowStatus.restricted => 'Ubicación restringida',
      LocationFlowStatus.error => 'No pudimos confirmar tu zona',
    };
  }

  String _headlineFor(
    LocationFlowStatus status,
    LocationFeedbackText feedback,
    bool isLoading,
  ) {
    if (isLoading) {
      return 'Buscando tu ubicación actual';
    }

    return switch (status) {
      LocationFlowStatus.success => feedback.title.replaceFirst(
        'Entregando en ',
        '',
      ),
      LocationFlowStatus.permissionRequired => 'Elegir dirección',
      LocationFlowStatus.deniedForever => 'Abrir configuración',
      LocationFlowStatus.serviceDisabled => 'Encender GPS',
      LocationFlowStatus.restricted => 'Ubicación no disponible',
      LocationFlowStatus.requestingPermission =>
        'Confirma el acceso a tu ubicación',
      LocationFlowStatus.error => 'No pudimos confirmar tu dirección',
      LocationFlowStatus.initial ||
      LocationFlowStatus.loading => 'Buscando tu ubicación actual',
    };
  }

  String _subtitleFor(
    LocationFlowStatus status,
    LocationFeedbackText feedback,
    bool isLoading,
  ) {
    if (isLoading) {
      return 'Estamos consultando la ubicación del dispositivo para mostrarte talleres cercanos.';
    }

    return switch (status) {
      LocationFlowStatus.success => '',
      LocationFlowStatus.permissionRequired =>
        'Usa tu ubicación actual para descubrir talleres y servicios cercanos.',
      LocationFlowStatus.deniedForever =>
        'Necesitamos que habilites el permiso desde la configuración del teléfono.',
      LocationFlowStatus.serviceDisabled =>
        'Activa la ubicación del dispositivo para ver resultados cercanos.',
      LocationFlowStatus.restricted => feedback.subtitle,
      LocationFlowStatus.requestingPermission =>
        'Estamos esperando tu respuesta para poder ubicar tu zona de entrega.',
      LocationFlowStatus.error => feedback.subtitle,
      LocationFlowStatus.initial || LocationFlowStatus.loading =>
        'Estamos consultando la ubicación del dispositivo para mostrarte talleres cercanos.',
    };
  }
}

class _WorkshopsSection extends StatelessWidget {
  const _WorkshopsSection({
    required this.workshopsFuture,
    required this.locationState,
    required this.proximityFilter,
    required this.emptyStateResolver,
  });

  final Future<List<Workshop>> workshopsFuture;
  final LocationState locationState;
  final WorkshopProximityFilter proximityFilter;
  final WorkshopEmptyStateResolver emptyStateResolver;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Talleres cercanos',
            style: TextStyle(
              color: Color(0xFF181411),
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explora opciones cercanas sin salir del home.',
            style: TextStyle(
              color: Color(0xFF6B5F57),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Workshop>>(
            future: workshopsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No fue posible cargar los talleres en este momento.',
                    style: TextStyle(color: Color(0xFF6B5F57)),
                  ),
                );
              }

              final workshops = snapshot.data ?? const <Workshop>[];
              final searchLocation = _HomeCustomerPageState
                  ._workshopSearchLocationResolver
                  .resolve(locationState.location);
              final isUsingFallbackLocation = _HomeCustomerPageState
                  ._workshopSearchLocationResolver
                  .isUsingFallback(locationState.location);
              final nearbyWorkshops = proximityFilter.filterNearby(
                workshops: workshops,
                currentLocation: searchLocation,
              );

              return SizedBox(
                height: 320,
                child: WorkshopsCarousel(
                  workshops: nearbyWorkshops,
                  currentLocation: searchLocation,
                  emptyMessage: emptyStateResolver.resolve(
                    locationState,
                    isUsingFallbackLocation: isUsingFallbackLocation,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LocationOptionTile extends StatelessWidget {
  const _LocationOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: const Color(0xFFF8F4EF),
      borderRadius: BorderRadius.circular(20),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: enabled ? const Color(0xFF181411) : const Color(0xFF9B8E84),
            size: 19,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? const Color(0xFF181411) : const Color(0xFF7D6F66),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled ? const Color(0xFF6B5F57) : const Color(0xFF9B8E84),
            fontSize: 12,
            height: 1.35,
          ),
        ),
        trailing: Icon(
          enabled ? Icons.arrow_forward_ios_rounded : Icons.schedule_rounded,
          size: enabled ? 14 : 16,
          color: enabled ? const Color(0xFF6B5F57) : const Color(0xFF9B8E84),
        ),
      ),
    );
  }
}

class _NearbyWorkshopsMapSection extends StatelessWidget {
  const _NearbyWorkshopsMapSection({
    required this.workshopsFuture,
    required this.locationState,
    required this.proximityFilter,
    required this.emptyStateResolver,
  });

  final Future<List<Workshop>> workshopsFuture;
  final LocationState locationState;
  final WorkshopProximityFilter proximityFilter;
  final WorkshopEmptyStateResolver emptyStateResolver;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mapa de talleres cercanos',
            style: TextStyle(
              color: Color(0xFF181411),
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ubica en el mapa las opciones disponibles cerca de ti.',
            style: TextStyle(
              color: Color(0xFF6B5F57),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Workshop>>(
            future: workshopsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No fue posible cargar el mapa de talleres en este momento.',
                    style: TextStyle(color: Color(0xFF6B5F57)),
                  ),
                );
              }

              final workshops = snapshot.data ?? const <Workshop>[];
              final searchLocation = _HomeCustomerPageState
                  ._workshopSearchLocationResolver
                  .resolve(locationState.location);
              final isUsingFallbackLocation = _HomeCustomerPageState
                  ._workshopSearchLocationResolver
                  .isUsingFallback(locationState.location);
              final nearbyWorkshops = proximityFilter.filterNearby(
                workshops: workshops,
                currentLocation: searchLocation,
              );
              final emptyMessage = emptyStateResolver.resolve(
                locationState,
                isUsingFallbackLocation: isUsingFallbackLocation,
              );

              return SizedBox(
                height: 320,
                child: NearbyWorkshopsMap(
                  workshops: nearbyWorkshops,
                  currentLocation: searchLocation,
                  emptyMessage: emptyMessage,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
