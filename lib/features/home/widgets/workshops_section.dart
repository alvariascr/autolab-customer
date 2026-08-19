import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_state.dart';
import '../../../core/theme/autolab_customer.dart';
import '../../../l10n/app_localizations.dart';
import '../../workshops/domain/entities/workshop.dart';
import '../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../workshops/domain/services/workshop_search_location_resolver.dart';
import '../../workshops/presentation/widgets/workshop_card.dart';
import '../../workshops/presentation/widgets/workshops_carousel.dart';
import '../../workshops/presentation/workshop_empty_state_resolver.dart';

class WorkshopsSection extends StatelessWidget {
  const WorkshopsSection({
    super.key,
    required this.workshops,
    this.fallbackWorkshops = const [],
    required this.locationState,
    required this.proximityFilter,
    required this.emptyStateResolver,
    required this.isLoading,
    required this.workshopFailure,
    required this.onViewAllTap,
    this.selectedServiceLabel,
    this.selectedServiceKey,
    this.showCategoryNotFoundMessage = false,
    this.serviceFilterFailed = false,
    this.onClearServiceFilter,
  });

  static const _searchLocationResolver = WorkshopSearchLocationResolver();

  final List<Workshop> workshops;
  final List<Workshop> fallbackWorkshops;
  final LocationState locationState;
  final WorkshopProximityFilter proximityFilter;
  final WorkshopEmptyStateResolver emptyStateResolver;
  final bool isLoading;
  final Failure? workshopFailure;
  final VoidCallback onViewAllTap;
  final String? selectedServiceLabel;
  final String? selectedServiceKey;
  final bool showCategoryNotFoundMessage;
  final bool serviceFilterFailed;
  final VoidCallback? onClearServiceFilter;

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
    final serviceLabel = selectedServiceLabel;
    final isUsingFallbackLocation = _searchLocationResolver.isUsingFallback(
      locationState.location,
    );
    final nearbyWorkshops = proximityFilter.filterNearby(
      workshops: workshops,
      currentLocation: searchLocation,
    );
    final shouldUseNearbyFallback =
        serviceLabel != null &&
        (serviceFilterFailed || nearbyWorkshops.isEmpty);
    final displayedWorkshops = shouldUseNearbyFallback
        ? proximityFilter.filterNearby(
            workshops: fallbackWorkshops.isEmpty
                ? workshops
                : fallbackWorkshops,
            currentLocation: searchLocation,
          )
        : nearbyWorkshops;
    final shouldShowCategoryMessage =
        serviceFilterFailed ||
        showCategoryNotFoundMessage ||
        shouldUseNearbyFallback;
    final emptyMessage = emptyStateResolver.resolve(
      locationState,
      l10n: l10n,
      isUsingFallbackLocation: isUsingFallbackLocation,
    );
    final effectiveEmptyMessage = serviceLabel == null
        ? emptyMessage
        : l10n.homeFilteredWorkshopsEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  serviceLabel == null
                      ? l10n.workshopsSectionTitle
                      : shouldShowCategoryMessage
                      ? l10n.homeNearbyWorkshopsFallbackTitle
                      : l10n.homeFilteredWorkshopsTitle(serviceLabel),
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
              TextButton(
                onPressed: onClearServiceFilter ?? onViewAllTap,
                style: TextButton.styleFrom(
                  foregroundColor: AutolabCustomer.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  onClearServiceFilter == null
                      ? l10n.workshopsSectionViewAll
                      : l10n.homeClearServiceFilter,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingSmd + 2),
        if (serviceLabel == null)
          SizedBox(
            height: carouselHeight,
            child: WorkshopsCarousel(
              workshops: nearbyWorkshops,
              currentLocation: searchLocation,
              emptyMessage: effectiveEmptyMessage,
              height: carouselHeight,
            ),
          )
        else ...[
          if (shouldShowCategoryMessage) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AutolabCustomer.spacingSmd,
                  vertical: AutolabCustomer.spacingSmd,
                ),
                decoration: BoxDecoration(
                  color: AutolabCustomer.customerSoftSurfaceColor(context),
                  borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AutolabCustomer.primary,
                      size: AutolabCustomer.iconSm,
                    ),
                    const SizedBox(width: AutolabCustomer.spacingSm),
                    Expanded(
                      child: Text(
                        serviceFilterFailed
                            ? l10n.homeServiceFilterLoadError
                            : l10n.homeFilteredWorkshopsEmpty,
                        style: AutolabCustomer.caption.copyWith(
                          color: textColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingSmd),
          ],
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
            child: Text(
              l10n.homeWorkshopResultsCount(displayedWorkshops.length),
              style: AutolabCustomer.body.copyWith(
                color: secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AutolabCustomer.spacingSm),
          if (displayedWorkshops.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalMargin,
                vertical: AutolabCustomer.spacingLg,
              ),
              child: Center(
                child: Text(
                  effectiveEmptyMessage,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.body.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
              child: Column(
                children: displayedWorkshops.map((workshop) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AutolabCustomer.spacingSm,
                    ),
                    child: InkWell(
                      key: ValueKey('home-service-workshop-${workshop.id}'),
                      borderRadius: BorderRadius.circular(
                        AutolabCustomer.radiusCard + 2,
                      ),
                      onTap: () {
                        if (shouldUseNearbyFallback) {
                          context.push('/workshops/${workshop.id}');
                          return;
                        }

                        final query = Uri.encodeQueryComponent(serviceLabel);
                        final serviceKey = Uri.encodeQueryComponent(
                          selectedServiceKey ?? '',
                        );
                        context.push(
                          '/search/workshops/${workshop.id}/products?query=$query&serviceKey=$serviceKey',
                        );
                      },
                      child: WorkshopCard(
                        workshop: workshop,
                        referenceLocation: searchLocation,
                        compact: true,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }
}
