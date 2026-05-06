import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/location/location_cubit.dart';
import '../../../core/location/location_state.dart';
import '../../workshops/domain/entities/workshop.dart';
import '../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../workshops/domain/services/workshop_search_location_resolver.dart';
import '../../workshops/presentation/workshop_empty_state_resolver.dart';
import 'delivery_location_card.dart';
import 'search_bar_overlay.dart';
import 'workshops_section.dart';

class HomeCustomerContent extends StatelessWidget {
  const HomeCustomerContent({
    super.key,
    required this.workshops,
    required this.isWorkshopsLoading,
    required this.showSearchBar,
    required this.searchController,
    required this.proximityFilter,
    required this.emptyStateResolver,
    required this.onLocationTap,
    required this.onSearchClose,
    this.onSearchQueryChanged,
    this.workshopFailure,
  });

  final List<Workshop> workshops;
  final bool isWorkshopsLoading;
  final bool showSearchBar;
  final TextEditingController searchController;
  final WorkshopProximityFilter proximityFilter;
  final WorkshopEmptyStateResolver emptyStateResolver;
  final ValueChanged<LocationState> onLocationTap;
  final VoidCallback onSearchClose;
  final ValueChanged<String>? onSearchQueryChanged;
  final Failure? workshopFailure;

  static const _searchLocationResolver = WorkshopSearchLocationResolver();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        final searchLocation = _searchLocationResolver.resolve(state.location);

        return Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DeliveryLocationCard(
                          state: state,
                          onTap: () => onLocationTap(state),
                        ),
                        const SizedBox(height: 20),
                        WorkshopsSection(
                          workshops: workshops,
                          locationState: state,
                          proximityFilter: proximityFilter,
                          emptyStateResolver: emptyStateResolver,
                          isLoading: isWorkshopsLoading,
                          workshopFailure: workshopFailure,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SearchBarOverlay(
              showSearchBar: showSearchBar,
              controller: searchController,
              workshops: workshops,
              currentLocation: searchLocation,
              isLoading: isWorkshopsLoading,
              workshopFailure: workshopFailure,
              onClose: onSearchClose,
              onQueryChanged: onSearchQueryChanged,
            ),
          ],
        );
      },
    );
  }
}
