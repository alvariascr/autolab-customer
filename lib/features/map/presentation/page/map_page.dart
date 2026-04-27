import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/location/location_cubit.dart';
import '../../../../core/location/location_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
import '../../../workshops/presentation/widgets/nearby_workshops_map.dart';
import '../../../workshops/presentation/workshop_empty_state_resolver.dart';
import '../cubit/map_cubit.dart';
import '../cubit/map_state.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<MapCubit>()
            ..loadWorkshops(context.read<LocationCubit>().state.location),
      child: const _MapPageView(),
    );
  }
}

class _MapPageView extends StatefulWidget {
  const _MapPageView();

  @override
  State<_MapPageView> createState() => _MapPageViewState();
}

class _MapPageViewState extends State<_MapPageView> {
  static const _emptyStateResolver = WorkshopEmptyStateResolver();

  int _currentIndex = 1;

  void _handleBottomNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });

    NavigationHandler.handle(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4EF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 46,
        leadingWidth: 52,
        title: Text(
          l10n.mapPageTitle,
          style: const TextStyle(
            color: Color(0xFF181411),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: BlocListener<LocationCubit, LocationState>(
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
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x16000000),
                                  blurRadius: 30,
                                  offset: Offset(0, 14),
                                ),
                              ],
                            ),
                            child: _MapBody(
                              state: mapState,
                              emptyMessage: emptyMessage,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: _MapTopPill(
                            label: _labelFor(workshopsCount, mapState, l10n),
                            dark: true,
                          ),
                        ),
                        Positioned(
                          top: 14,
                          right: 14,
                          child: _MapTopPill(
                            label: l10n.mapTopPillExplore,
                            icon: Icons.map_outlined,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavigation,
      ),
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
      MapLoaded(:final workshops, :final currentLocation) => NearbyWorkshopsMap(
        workshops: workshops,
        currentLocation: currentLocation,
        emptyMessage: emptyMessage,
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

class _MapTopPill extends StatelessWidget {
  const _MapTopPill({required this.label, this.icon, this.dark = false});

  final String label;
  final IconData? icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final background = dark ? const Color(0xFF181411) : Colors.white;
    final foreground = dark ? Colors.white : const Color(0xFF181411);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background.withValues(alpha: dark ? 0.94 : 0.9),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
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
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
