import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/location/location_cubit.dart';
import '../../core/location/location_permission_gate.dart';
import '../../core/location/location_state.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../workshops/data/datasources/workshop_remote_data_source_impl.dart';
import '../workshops/data/repositories/workshop_repository_impl.dart';
import '../workshops/domain/entities/workshop.dart';
import '../workshops/domain/services/workshop_proximity_filter.dart';
import '../workshops/presentation/workshop_empty_state_resolver.dart';
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
  static const _workshopEmptyStateResolver = WorkshopEmptyStateResolver();

  late Future<List<Workshop>> _workshopsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationCubit>().loadCurrentLocation();
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

  Future<void> _handleLocationAction(LocationState state) async {
    final locationCubit = context.read<LocationCubit>();

    switch (state.status) {
      case LocationFlowStatus.permissionRequired:
        final shouldRequest = await _showLocationPermissionPrePrompt();
        if (shouldRequest == true && mounted) {
          await locationCubit.requestPermission();
        }
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
                    BlocBuilder<LocationCubit, LocationState>(
                      builder: (context, state) {
                        return _TopLocationBar(
                          state: state,
                          onPrimaryAction: () => _handleLocationAction(state),
                          onRefresh: () {
                            context.read<LocationCubit>().refresh();
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<LocationCubit, LocationState>(
                      builder: (context, state) {
                        return _WorkshopsSection(
                          workshopsFuture: _workshopsFuture,
                          locationState: state,
                          proximityFilter: _workshopProximityFilter,
                          emptyStateResolver: _workshopEmptyStateResolver,
                        );
                      },
                    ),
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
  });

  final LocationState state;
  final VoidCallback onPrimaryAction;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isLoading =
        state.status == LocationFlowStatus.initial ||
        state.status == LocationFlowStatus.loading ||
        state.status == LocationFlowStatus.requestingPermission;
    final feedback = mapLocationFeedback(
      placeName: state.placeName,
      fallbackMessage: state.message,
      stateType: _stateKey(state.status),
    );
    final title = _titleFor(state.status, feedback, isLoading);
    final subtitle = _subtitleFor(state.status, feedback, isLoading);

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
                if (state.showRefreshAction)
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

  String _stateKey(LocationFlowStatus status) {
    return switch (status) {
      LocationFlowStatus.success => 'success',
      LocationFlowStatus.permissionRequired => 'permissionRequired',
      LocationFlowStatus.deniedForever => 'deniedForever',
      LocationFlowStatus.serviceDisabled => 'serviceDisabled',
      LocationFlowStatus.restricted => 'restricted',
      LocationFlowStatus.error => 'error',
      LocationFlowStatus.requestingPermission => 'requestingPermission',
      LocationFlowStatus.initial || LocationFlowStatus.loading => 'loading',
    };
  }

  String _titleFor(
    LocationFlowStatus status,
    LocationFeedbackText feedback,
    bool isLoading,
  ) {
    if (!isLoading) {
      return feedback.title;
    }

    return switch (status) {
      LocationFlowStatus.requestingPermission => 'Solicitando permiso',
      LocationFlowStatus.initial ||
      LocationFlowStatus.loading => 'Buscando tu ubicación',
      _ => feedback.title,
    };
  }

  String _subtitleFor(
    LocationFlowStatus status,
    LocationFeedbackText feedback,
    bool isLoading,
  ) {
    if (!isLoading) {
      return feedback.subtitle;
    }

    return switch (status) {
      LocationFlowStatus.requestingPermission =>
        'Esperando tu respuesta para acceder a la ubicación.',
      LocationFlowStatus.initial ||
      LocationFlowStatus.loading => 'Consultando ubicación del dispositivo...',
      _ => feedback.subtitle,
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
              final nearbyWorkshops = proximityFilter.filterNearby(
                workshops: workshops,
                currentLocation: locationState.location,
              );

              return SizedBox(
                height: 320,
                child: WorkshopsCarousel(
                  workshops: nearbyWorkshops,
                  emptyMessage: emptyStateResolver.resolve(locationState),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
