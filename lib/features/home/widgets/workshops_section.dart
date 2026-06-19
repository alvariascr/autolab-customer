import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';

import '../../../core/location/location_state.dart';
import '../../../core/theme/autolab_customer.dart';
import '../../../l10n/app_localizations.dart';
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
    required this.workshopFailure,
  });

  static const _searchLocationResolver = WorkshopSearchLocationResolver();

  final List<Workshop> workshops;
  final LocationState locationState;
  final WorkshopProximityFilter proximityFilter;
  final WorkshopEmptyStateResolver emptyStateResolver;
  final bool isLoading;
  final Failure? workshopFailure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = AutolabCustomer.customerTextColor(context);
    final secondaryTextColor = AutolabCustomer.customerSecondaryTextColor(
      context,
    );
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);
    final carouselHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 270,
      regular: 300,
      tablet: 340,
    );

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AutolabCustomer.spacingLg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (workshopFailure != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AutolabCustomer.spacingLg,
        ),
        child: Text(
          emptyStateResolver.resolveLoadError(workshopFailure!, l10n),
          style: AutolabCustomer.body.copyWith(color: secondaryTextColor),
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
    final emptyMessage = emptyStateResolver.resolve(
      locationState,
      l10n: l10n,
      isUsingFallbackLocation: isUsingFallbackLocation,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.workshopsSectionTitle,
                  style: AutolabCustomer.h2.copyWith(
                    color: textColor,
                    fontSize: AutolabCustomer.responsiveDouble(
                      context,
                      compact: 21,
                      regular: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              Text(
                'Ver todos',
                style: AutolabCustomer.body.copyWith(
                  color: AutolabCustomer.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingSmd + 2),
        SizedBox(
          height: carouselHeight,
          child: WorkshopsCarousel(
            workshops: nearbyWorkshops,
            currentLocation: searchLocation,
            emptyMessage: emptyMessage,
            height: carouselHeight,
          ),
        ),
      ],
    );
  }
}
