import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart' show Either, Right;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/app_injection.dart';
import '../../core/location/location_cubit.dart';
import '../../core/location/location_state.dart';
import '../../core/theme/autolab_customer.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/navigation_handler.dart';
import '../navigation/widgets/custom_bottom_navbar.dart';
import '../notifications/presentation/pages/notifications_page.dart';
import '../products/domain/repositories/product_repository.dart';
import '../profile/application/active_garage_vehicle_loader.dart';
import '../profile/application/garage_vehicle_controller.dart';
import '../profile/domain/entities/garage_vehicle.dart';
import '../profile/domain/usecases/get_default_garage_vehicle.dart';
import '../workshops/application/workshop_discovery_query_store.dart';
import '../workshops/domain/entities/workshop.dart';
import '../workshops/domain/repositories/workshop_repository.dart';
import '../workshops/domain/services/workshop_proximity_filter.dart';
import '../workshops/presentation/workshop_empty_state_resolver.dart';
import 'application/home_service_filter_cubit.dart';
import 'application/home_service_filter_state.dart';
import 'application/home_service_popularity_store.dart';
import 'application/recent_searches_store.dart';
import 'location/location_ui_presenter.dart';
import 'widgets/home_customer_content.dart';
import 'widgets/location_option_tile.dart';

class HomeCustomerController {
  _HomeCustomerPageState? _state;

  void openSearch() => _state?._openSearchFromNavigation();

  void closeSearch() => _state?._closeSearchFromNavigation();

  void _attach(_HomeCustomerPageState state) {
    _state = state;
  }

  void _detach(_HomeCustomerPageState state) {
    if (_state == state) {
      _state = null;
    }
  }
}

class HomeCustomerPage extends StatefulWidget {
  const HomeCustomerPage({
    super.key,
    this.initialIndex = 0,
    this.initialShowSearchBar = false,
    this.showBottomNavigation = true,
    this.controller,
    this.onSearchClosed,
  });

  final int initialIndex;
  final bool initialShowSearchBar;
  final bool showBottomNavigation;
  final HomeCustomerController? controller;
  final VoidCallback? onSearchClosed;

  @override
  State<HomeCustomerPage> createState() => _HomeCustomerPageState();
}

class _HomeCustomerPageState extends State<HomeCustomerPage>
    with WidgetsBindingObserver {
  static const _workshopProximityFilter = WorkshopProximityFilter();
  static const _workshopEmptyStateResolver = WorkshopEmptyStateResolver();
  late final Future<Either<Failure, List<Workshop>>> _workshopsFuture;
  late final HomeServiceFilterCubit _homeServiceFilterCubit;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _homeScrollController = ScrollController();
  WorkshopDiscoveryQueryStore? _queryStore;
  GarageVehicleController? _garageVehicleController;
  GarageVehicle? _activeVehicle;
  final GlobalKey _workshopsSectionKey = GlobalKey();
  int _activeVehicleLoadGeneration = 0;

  int _currentIndex = 0;
  bool _showSearchBar = false;
  bool _didTriggerInitialLocationLoad = false;

  @override
  void initState() {
    super.initState();
    _homeServiceFilterCubit = sl<HomeServiceFilterCubit>();
    if (sl.isRegistered<GarageVehicleController>()) {
      _garageVehicleController = sl<GarageVehicleController>()
        ..addListener(_onGarageVehiclesChanged);
      unawaited(_loadActiveVehicle());
    }
    widget.controller?._attach(this);
    _currentIndex = widget.initialIndex;
    _showSearchBar = widget.initialShowSearchBar;
    _queryStore = sl.isRegistered<WorkshopDiscoveryQueryStore>()
        ? sl<WorkshopDiscoveryQueryStore>()
        : null;
    if (widget.initialShowSearchBar) {
      _searchController.text = _queryStore?.query ?? '';
    } else {
      _queryStore?.clear();
    }
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialLocationLoad();
    });
    _workshopsFuture = _loadWorkshops();
  }

  @override
  void didUpdateWidget(covariant HomeCustomerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    _garageVehicleController?.removeListener(_onGarageVehiclesChanged);
    widget.controller?._detach(this);
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _homeScrollController.dispose();
    unawaited(_homeServiceFilterCubit.close());
    super.dispose();
  }

  void _onGarageVehiclesChanged() {
    unawaited(_loadActiveVehicle());
  }

  Future<void> _loadActiveVehicle() async {
    final generation = ++_activeVehicleLoadGeneration;
    try {
      final activeVehicle = await loadActiveGarageVehicle(
        sl<GetDefaultGarageVehicle>(),
      );
      if (!mounted || generation != _activeVehicleLoadGeneration) return;

      setState(() {
        _activeVehicle = activeVehicle;
      });
    } catch (_) {
      // The home page remains usable if the optional vehicle cannot be loaded.
    }
  }

  Future<void> _openVehiclesPage() async {
    await context.push('/vehicles');
  }

  Future<void> _handleHomeServiceCategoryChanged(
    String? serviceKey,
    String? label,
  ) async {
    if (serviceKey == null || label == null) {
      _homeServiceFilterCubit.clear();
      await WidgetsBinding.instance.endOfFrame;
      if (_homeScrollController.hasClients) {
        await _homeScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    await _homeServiceFilterCubit.select(
      serviceKey: serviceKey,
      serviceLabel: label,
    );

    if (!mounted || _homeServiceFilterCubit.state.serviceKey != serviceKey) {
      return;
    }
    final sectionContext = _workshopsSectionKey.currentContext;
    if (sectionContext == null || !sectionContext.mounted) return;
    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0,
    );
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

  Future<Either<Failure, List<Workshop>>> _loadWorkshops() async {
    if (!sl.isRegistered<WorkshopRepository>()) {
      return const Right(<Workshop>[]);
    }

    return sl<WorkshopRepository>().getWorkshops();
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

      final locationCubit = context.read<LocationCubit>();
      final locationState = locationCubit.state;
      if (locationState.status == LocationFlowStatus.loading) {
        return;
      }

      // Splash preloading should not replace the Home initialization flow.
      locationCubit.initialize();
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
      backgroundColor: AutolabCustomer.customerElevatedSurfaceColor(context),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AutolabCustomer.radiusModal),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AutolabCustomer.spacingScreen,
                AutolabCustomer.spacingSm,
                AutolabCustomer.spacingScreen,
                AutolabCustomer.spacingLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sheetCopy.title,
                    style: AutolabCustomer.bodyLarge.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingSm - 2),
                  Text(
                    sheetCopy.subtitle,
                    style: AutolabCustomer.caption.copyWith(
                      color: AutolabCustomer.customerSecondaryTextColor(
                        context,
                      ),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingMd + 2),
                  LocationOptionTile(
                    icon: Icons.my_location_outlined,
                    title: sheetCopy.currentLocationTitle,
                    subtitle: sheetCopy.currentLocationSubtitle,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _handleLocationAction(state);
                    },
                  ),
                  const SizedBox(height: AutolabCustomer.spacingSm + 2),
                  LocationOptionTile(
                    icon: Icons.search_rounded,
                    title: sheetCopy.writeAddressTitle,
                    subtitle: sheetCopy.writeAddressSubtitle,
                  ),
                  const SizedBox(height: AutolabCustomer.spacingSm + 2),
                  LocationOptionTile(
                    icon: Icons.home_outlined,
                    title: sheetCopy.homeTitle,
                    subtitle: sheetCopy.savedAddressSubtitle,
                  ),
                  const SizedBox(height: AutolabCustomer.spacingSm + 2),
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
      _openSearchFromNavigation();
      return;
    }

    if (!widget.showBottomNavigation && index == 1) {
      context.go('/home-customer?tab=map');
      return;
    }

    setState(() {
      _currentIndex = index;
      _showSearchBar = false;
    });

    NavigationHandler.handle(context, index);
  }

  void _openSearchFromNavigation() {
    _queryStore?.setQuery(_searchController.text);
    setState(() {
      _currentIndex = 2;
      _showSearchBar = true;
    });
  }

  void _closeSearch() {
    _queryStore?.clear();
    _closeSearchFromNavigation();
    widget.onSearchClosed?.call();
  }

  void _closeSearchFromNavigation() {
    setState(() {
      _currentIndex = 0;
      _showSearchBar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      extendBody: true,
      body: BlocBuilder<HomeServiceFilterCubit, HomeServiceFilterState>(
        bloc: _homeServiceFilterCubit,
        builder: (context, filterState) {
          return FutureBuilder<Either<Failure, List<Workshop>>>(
            future: _workshopsFuture,
            builder: (context, snapshot) {
              final workshopsResult = snapshot.data;
              final workshops =
                  workshopsResult?.fold(
                    (_) => const <Workshop>[],
                    (items) => items,
                  ) ??
                  const <Workshop>[];
              final workshopFailure = workshopsResult?.fold(
                (failure) => failure,
                (_) => null,
              );
              final matchingWorkshopIds =
                  filterState.status == HomeServiceFilterStatus.success
                  ? filterState.matchingWorkshopIds.toSet()
                  : null;
              final visibleWorkshops =
                  matchingWorkshopIds == null || filterState.hasNoMatches
                  ? workshops
                  : workshops
                        .where(
                          (workshop) =>
                              matchingWorkshopIds.contains(workshop.id),
                        )
                        .toList(growable: false);

              return HomeCustomerContent(
                activeVehicle: _activeVehicle,
                workshops: visibleWorkshops,
                fallbackWorkshops: workshops,
                isWorkshopsLoading:
                    snapshot.connectionState == ConnectionState.waiting ||
                    filterState.isLoading,
                showSearchBar: _showSearchBar,
                searchController: _searchController,
                scrollController: _homeScrollController,
                proximityFilter: _workshopProximityFilter,
                emptyStateResolver: _workshopEmptyStateResolver,
                onLocationTap: _showLocationOptions,
                onNotificationTap: () =>
                    context.push(NotificationsPage.routePath),
                onSearchClose: _closeSearch,
                onViewAllWorkshopsTap: () => _handleBottomNavigation(1),
                onViewAllVehiclesTap: _openVehiclesPage,
                onServiceCategoryChanged: _handleHomeServiceCategoryChanged,
                selectedServiceKey: filterState.serviceKey,
                selectedServiceLabel: filterState.serviceLabel,
                showCategoryNotFoundMessage: filterState.hasNoMatches,
                serviceFilterFailed: filterState.hasFailed,
                workshopsSectionKey: _workshopsSectionKey,
                productRepository: sl.isRegistered<ProductRepository>()
                    ? sl<ProductRepository>()
                    : null,
                recentSearchesStore: sl.isRegistered<RecentSearchesStore>()
                    ? sl<RecentSearchesStore>()
                    : null,
                servicePopularityStore:
                    sl.isRegistered<HomeServicePopularityStore>()
                    ? sl<HomeServicePopularityStore>()
                    : null,
                onSearchQueryChanged: _queryStore?.setQuery,
                workshopFailure: workshopFailure,
              );
            },
          );
        },
      ),
      bottomNavigationBar: widget.showBottomNavigation
          ? CustomBottomNavbar(
              currentIndex: _currentIndex,
              onTap: _handleBottomNavigation,
            )
          : null,
    );
  }
}
