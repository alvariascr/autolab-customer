import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/location/location_cubit.dart';
import '../../../../core/location/location_state.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
import '../../../workshops/domain/entities/workshop.dart';
import '../../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../../workshops/domain/services/workshop_search_location_resolver.dart';
import '../../../workshops/presentation/widgets/nearby_workshops_map.dart';
import '../../../workshops/presentation/workshop_empty_state_resolver.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.workshops});

  final List<Workshop> workshops;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _proximityFilter = WorkshopProximityFilter();
  static const _searchLocationResolver = WorkshopSearchLocationResolver();
  static const _emptyStateResolver = WorkshopEmptyStateResolver();

  int _currentIndex = 1;

  void _handleBottomNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });

    NavigationHandler.handle(context, index, workshops: widget.workshops);
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
        title: const Text(
          'Mapa',
          style: TextStyle(
            color: Color(0xFF181411),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              final searchLocation = _searchLocationResolver.resolve(
                state.location,
              );
              final isUsingFallbackLocation = _searchLocationResolver
                  .isUsingFallback(state.location);
              final nearbyWorkshops = _proximityFilter.filterNearby(
                workshops: widget.workshops,
                currentLocation: searchLocation,
              );
              final emptyMessage = _emptyStateResolver.resolve(
                state,
                isUsingFallbackLocation: isUsingFallbackLocation,
              );

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
                      child: NearbyWorkshopsMap(
                        workshops: nearbyWorkshops,
                        currentLocation: searchLocation,
                        emptyMessage: emptyMessage,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _MapTopPill(
                      label: nearbyWorkshops.isEmpty
                          ? 'Sin talleres'
                          : nearbyWorkshops.length == 1
                          ? '1 taller cercano'
                          : '${nearbyWorkshops.length} talleres cercanos',
                      dark: true,
                    ),
                  ),
                  const Positioned(
                    top: 14,
                    right: 14,
                    child: _MapTopPill(
                      label: 'Explorar mapa',
                      icon: Icons.map_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavigation,
      ),
    );
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
