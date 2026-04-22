import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/app_injection.dart';
import '../../core/location/location_cubit.dart';
import '../../core/location/location_state.dart';
import '../navigation/navigation_handler.dart';
import '../navigation/widgets/custom_bottom_navbar.dart';
import '../workshops/domain/entities/workshop.dart';
import '../workshops/domain/repositories/workshop_repository.dart';
import '../workshops/domain/services/workshop_proximity_filter.dart';
import '../workshops/presentation/workshop_empty_state_resolver.dart';
import 'widgets/home_customer_content.dart';
import 'widgets/location_option_tile.dart';

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
  final TextEditingController _searchController = TextEditingController();

  int _currentIndex = 0;
  bool _showSearchBar = false;
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
    _searchController.dispose();
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
      if (!sl.isRegistered<WorkshopRepository>()) {
        return const <Workshop>[];
      }

      return await sl<WorkshopRepository>().getWorkshops();
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
                    'Selecciona donde entregar',
                    style: TextStyle(
                      color: Color(0xFF181411),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Puedes usar tu ubicacion actual o elegir una direccion guardada mas adelante.',
                    style: TextStyle(
                      color: Color(0xFF6B5F57),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LocationOptionTile(
                    icon: Icons.my_location_outlined,
                    title: _useCurrentLocationLabelFor(actionStatus),
                    subtitle: _useCurrentLocationSubtitleFor(actionStatus),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _handleLocationAction(state);
                    },
                  ),
                  const SizedBox(height: 10),
                  const LocationOptionTile(
                    icon: Icons.search_rounded,
                    title: 'Escribir direccion',
                    subtitle: 'Lo conectamos en el siguiente paso del home.',
                  ),
                  const SizedBox(height: 10),
                  const LocationOptionTile(
                    icon: Icons.home_outlined,
                    title: 'Casa',
                    subtitle:
                        'Proximamente podras guardar tus direcciones favoritas.',
                  ),
                  const SizedBox(height: 10),
                  const LocationOptionTile(
                    icon: Icons.work_outline_rounded,
                    title: 'Trabajo',
                    subtitle:
                        'Proximamente podras guardar tus direcciones favoritas.',
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
      LocationFlowStatus.success => 'Actualizar ubicacion actual',
      LocationFlowStatus.deniedForever => 'Abrir configuracion',
      LocationFlowStatus.serviceDisabled => 'Encender GPS',
      LocationFlowStatus.requestingPermission => 'Esperando permiso',
      _ => 'Usar ubicacion actual',
    };
  }

  String _useCurrentLocationSubtitleFor(LocationFlowStatus status) {
    return switch (status) {
      LocationFlowStatus.success =>
        'Volver a consultar tu ubicacion para actualizar los resultados.',
      LocationFlowStatus.deniedForever =>
        'Habilita el permiso de ubicacion desde la configuracion del telefono.',
      LocationFlowStatus.serviceDisabled =>
        'Activa la ubicacion del dispositivo para ver talleres cercanos.',
      LocationFlowStatus.requestingPermission =>
        'Estamos esperando tu respuesta para acceder a la ubicacion.',
      _ => 'Usa el GPS del telefono para ver talleres y servicios cerca de ti.',
    };
  }

  void _handleBottomNavigation(int index) {
    if (index == 2) {
      setState(() {
        _currentIndex = 2;
        _showSearchBar = !_showSearchBar;
      });
      return;
    }

    setState(() {
      _currentIndex = index;
      _showSearchBar = false;
    });

    NavigationHandler.handle(context, index);
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
      ),
      body: FutureBuilder<List<Workshop>>(
        future: _workshopsFuture,
        builder: (context, snapshot) {
          return HomeCustomerContent(
            workshops: snapshot.data ?? const <Workshop>[],
            isWorkshopsLoading:
                snapshot.connectionState == ConnectionState.waiting,
            hasWorkshopsError: snapshot.hasError,
            showSearchBar: _showSearchBar,
            searchController: _searchController,
            proximityFilter: _workshopProximityFilter,
            emptyStateResolver: _workshopEmptyStateResolver,
            onLocationTap: _showLocationOptions,
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavigation,
      ),
    );
  }
}
