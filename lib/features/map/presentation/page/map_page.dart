import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/location/location_cubit.dart';
import '../../../../core/location/location_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
import '../../../workshops/application/workshop_discovery_query_store.dart';
import '../../../workshops/presentation/widgets/nearby_workshops_map.dart';
import '../../../workshops/presentation/workshop_empty_state_resolver.dart';
import '../cubit/map_cubit.dart';
import '../cubit/map_state.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<MapCubit>()
            ..loadWorkshops(context.read<LocationCubit>().state.location),
      child: _MapPageView(showBottomNavigation: showBottomNavigation),
    );
  }
}

class _MapPageView extends StatefulWidget {
  const _MapPageView({required this.showBottomNavigation});

  final bool showBottomNavigation;

  @override
  State<_MapPageView> createState() => _MapPageViewState();
}

class _MapPageViewState extends State<_MapPageView> {
  static const _emptyStateResolver = WorkshopEmptyStateResolver();

  late final WorkshopDiscoveryQueryStore _queryStore;
  late final TextEditingController _searchController;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _queryStore = sl<WorkshopDiscoveryQueryStore>();
    _searchController = TextEditingController(text: _queryStore.query);
    _queryStore.addListener(_syncSearchFromStore);
  }

  @override
  void dispose() {
    _queryStore.removeListener(_syncSearchFromStore);
    _searchController.dispose();
    super.dispose();
  }

  void _syncSearchFromStore() {
    final query = _queryStore.query;
    if (_searchController.text == query) {
      return;
    }

    _searchController.text = query;
  }

  void _updateSearchQuery(String value) {
    _queryStore.setQuery(value);
  }

  void _clearSearchQuery() {
    _searchController.clear();
    _queryStore.clear();
  }

  void _handleBottomNavigation(int index) {
    if (index == 2) {
      NavigationHandler.handle(context, index);
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    NavigationHandler.handle(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFE9EEF2),
      extendBody: true,
      body: BlocListener<LocationCubit, LocationState>(
        listenWhen: (previous, current) =>
            previous.location != current.location ||
            previous.effectiveStatus != current.effectiveStatus,
        listener: (context, state) {
          context.read<MapCubit>().loadWorkshops(state.location);
        },
        child: BlocBuilder<LocationCubit, LocationState>(
          builder: (context, locationState) {
            return BlocBuilder<MapCubit, MapState>(
              builder: (context, mapState) {
                final emptyMessage = switch (mapState) {
                  MapLoaded(:final isUsingFallbackLocation) =>
                    _emptyStateResolver.resolve(
                      locationState,
                      l10n: l10n,
                      isUsingFallbackLocation: isUsingFallbackLocation,
                    ),
                  _ => _emptyStateResolver.resolve(
                    locationState,
                    l10n: l10n,
                    isUsingFallbackLocation: false,
                  ),
                };

                final workshopsCount = switch (mapState) {
                  MapLoaded(:final workshops) => workshops.length,
                  _ => 0,
                };

                return Stack(
                  children: [
                    Positioned.fill(
                      child: _MapBody(
                        state: mapState,
                        emptyMessage: emptyMessage,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: _MapDiscoveryOverlay(
                          countLabel: _labelFor(workshopsCount, mapState, l10n),
                          controller: _searchController,
                          onChanged: _updateSearchQuery,
                          onClear: _clearSearchQuery,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: widget.showBottomNavigation
          ? CustomBottomNavbar(
              currentIndex: _currentIndex,
              onTap: _handleBottomNavigation,
            )
          : null,
    );
  }

  String _labelFor(
    int workshopsCount,
    MapState mapState,
    AppLocalizations l10n,
  ) {
    return switch (mapState) {
      MapLoading() || MapInitial() => l10n.mapTopPillLoadingWorkshops,
      MapError() => l10n.mapTopPillNoWorkshops,
      MapLoaded() when workshopsCount == 0 => l10n.mapTopPillNoWorkshops,
      MapLoaded() when workshopsCount == 1 => l10n.mapTopPillOneWorkshopNearby,
      MapLoaded() => l10n.mapTopPillWorkshopsNearby(workshopsCount),
    };
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({required this.state, required this.emptyMessage});

  static const _emptyStateResolver = WorkshopEmptyStateResolver();

  final MapState state;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      MapInitial() ||
      MapLoading() => const Center(child: CircularProgressIndicator()),
      MapError(:final code, :final uiKey, :final message) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _messageFor(
              code: code,
              uiKey: uiKey,
              message: message,
              l10n: AppLocalizations.of(context)!,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B5F57)),
          ),
        ),
      ),
      MapLoaded(
        :final workshops,
        :final currentLocation,
        :final query,
        :final productResults,
        :final isLoadingProductResults,
      ) =>
        NearbyWorkshopsMap(
          workshops: workshops,
          currentLocation: currentLocation,
          emptyMessage: emptyMessage,
          query: query,
          productResults: productResults,
          isLoadingProductResults: isLoadingProductResults,
        ),
    };
  }

  String _messageFor({
    required String code,
    required String? uiKey,
    required String? message,
    required AppLocalizations l10n,
  }) {
    final failure = Failure(message ?? code, code: code, uiKey: uiKey);

    return _emptyStateResolver.resolveLoadError(failure, l10n);
  }
}

class _MapDiscoveryOverlay extends StatelessWidget {
  const _MapDiscoveryOverlay({
    required this.countLabel,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final String countLabel;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          _MapSearchBar(
            controller: controller,
            onChanged: onChanged,
            onClear: onClear,
          ),
          const SizedBox(height: 12),
          const _MapFilterChips(),
          const SizedBox(height: 14),
          _MapTopPill(label: countLabel),
        ],
      ),
    );
  }
}

class _MapSearchBar extends StatelessWidget {
  const _MapSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          elevation: 8,
          shadowColor: const Color(0x24000000),
          child: SizedBox(
            height: 52,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.mapSearchHint,
                hintStyle: const TextStyle(
                  color: Color(0xFF6D757C),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF5F676D),
                ),
                suffixIcon: value.text.trim().isEmpty
                    ? IconButton(
                        tooltip: l10n.mapSearchFiltersTooltip,
                        onPressed: () {},
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF181411),
                        ),
                      )
                    : IconButton(
                        tooltip: l10n.mapSearchClearTooltip,
                        onPressed: onClear,
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: Color(0xFF9AA1A8),
                        ),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapFilterChips extends StatelessWidget {
  const _MapFilterChips();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChipPill(
            icon: Icons.local_offer_outlined,
            label: l10n.mapFilterOffers,
          ),
          const SizedBox(width: 10),
          _FilterChipPill(
            icon: Icons.build_circle_outlined,
            label: l10n.mapFilterService,
          ),
          const SizedBox(width: 10),
          _FilterChipPill(
            icon: Icons.star_rounded,
            label: l10n.mapFilterTopRated,
          ),
        ],
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF181411)),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF181411),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTopPill extends StatelessWidget {
  const _MapTopPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF181411),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
