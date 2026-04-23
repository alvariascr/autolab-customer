import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/app_injection.dart';
import '../../core/location/location_cubit.dart';
import '../../core/location/location_state.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/navigation_handler.dart';
import '../navigation/widgets/custom_bottom_navbar.dart';
import '../workshops/domain/entities/workshop.dart';
import '../workshops/domain/repositories/workshop_repository.dart';
import '../workshops/domain/services/workshop_proximity_filter.dart';
import '../workshops/presentation/workshop_empty_state_resolver.dart';
import 'location/location_ui_presenter.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final sheetCopy = LocationUiPresenter.sheet(state, l10n);

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
                  Text(
                    sheetCopy.title,
                    style: const TextStyle(
                      color: Color(0xFF181411),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sheetCopy.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B5F57),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LocationOptionTile(
                    icon: Icons.my_location_outlined,
                    title: sheetCopy.currentLocationTitle,
                    subtitle: sheetCopy.currentLocationSubtitle,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _handleLocationAction(state);
                    },
                  ),
                  const SizedBox(height: 10),
                  LocationOptionTile(
                    icon: Icons.search_rounded,
                    title: sheetCopy.writeAddressTitle,
                    subtitle: sheetCopy.writeAddressSubtitle,
                  ),
                  const SizedBox(height: 10),
                  LocationOptionTile(
                    icon: Icons.home_outlined,
                    title: sheetCopy.homeTitle,
                    subtitle: sheetCopy.savedAddressSubtitle,
                  ),
                  const SizedBox(height: 10),
                  LocationOptionTile(
                    icon: Icons.work_outline_rounded,
                    title: sheetCopy.workTitle,
                    subtitle: sheetCopy.savedAddressSubtitle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
