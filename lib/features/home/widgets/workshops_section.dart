import 'package:flutter/material.dart';

import '../../../core/location/location_state.dart';
import '../../workshops/domain/entities/workshop.dart';
import '../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../workshops/domain/services/workshop_search_location_resolver.dart';
import '../../workshops/presentation/widgets/workshops_carousel.dart';
import '../../workshops/presentation/workshop_empty_state_resolver.dart';

class WorkshopsSection extends StatelessWidget {
  const WorkshopsSection({
    super.key,
    required this.workshops,
    required this.locationState,
    required this.proximityFilter,
    required this.emptyStateResolver,
    required this.isLoading,
    required this.hasError,
  });

  static const _searchLocationResolver = WorkshopSearchLocationResolver();

  final List<Workshop> workshops;
  final LocationState locationState;
  final WorkshopProximityFilter proximityFilter;
  final WorkshopEmptyStateResolver emptyStateResolver;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No fue posible cargar los talleres en este momento.',
          style: TextStyle(color: Color(0xFF6B5F57)),
        ),
      );
    }

    final searchLocation = _searchLocationResolver.resolve(
      locationState.location,
    );
    final isUsingFallbackLocation = _searchLocationResolver.isUsingFallback(
      locationState.location,
    );
    final nearbyWorkshops = proximityFilter.filterNearby(
      workshops: workshops,
      currentLocation: searchLocation,
    );

    return Column(
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
        SizedBox(
          height: 320,
          child: WorkshopsCarousel(
            workshops: nearbyWorkshops,
            currentLocation: searchLocation,
            emptyMessage: emptyStateResolver.resolve(
              locationState,
              isUsingFallbackLocation: isUsingFallbackLocation,
            ),
          ),
        ),
      ],
    );
  }
}
