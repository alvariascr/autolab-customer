import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/location/location_cubit.dart';
import '../../../core/location/location_state.dart';
import '../../../core/theme/autolab_customer.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/presentation/widgets/customer_notification_bell.dart';
import '../../products/domain/repositories/product_repository.dart';
import '../../profile/domain/entities/garage_vehicle.dart';
import '../../profile/presentation/helpers/garage_vehicle_display.dart';
import '../../profile/presentation/widgets/garage_vehicle_network_image.dart';
import '../../workshops/domain/entities/workshop.dart';
import '../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../workshops/domain/services/workshop_search_location_resolver.dart';
import '../../workshops/presentation/workshop_empty_state_resolver.dart';
import '../application/home_service_popularity_store.dart';
import '../application/recent_searches_store.dart';
import 'delivery_location_card.dart';
import 'search_bar_overlay.dart';
import 'workshops_section.dart';

part 'home_customer_vehicle_cards.dart';
part 'home_customer_header.dart';
part 'home_customer_service_categories.dart';
part 'home_customer_promotions.dart';
part 'home_customer_colors.dart';

typedef HomeServiceCategoryChanged =
    void Function(String? serviceKey, String? label);

class HomeCustomerContent extends StatelessWidget {
  const HomeCustomerContent({
    super.key,
    required this.workshops,
    this.fallbackWorkshops = const [],
    required this.isWorkshopsLoading,
    required this.showSearchBar,
    required this.searchController,
    required this.scrollController,
    required this.proximityFilter,
    required this.emptyStateResolver,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onSearchClose,
    required this.onViewAllWorkshopsTap,
    required this.onViewAllVehiclesTap,
    required this.onServiceCategoryChanged,
    this.activeVehicle,
    this.onSearchQueryChanged,
    this.workshopFailure,
    this.productRepository,
    this.recentSearchesStore,
    this.servicePopularityStore,
    this.selectedServiceKey,
    this.selectedServiceLabel,
    this.showCategoryNotFoundMessage = false,
    this.serviceFilterFailed = false,
    this.workshopsSectionKey,
  });

  final List<Workshop> workshops;
  final List<Workshop> fallbackWorkshops;
  final bool isWorkshopsLoading;
  final bool showSearchBar;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final WorkshopProximityFilter proximityFilter;
  final WorkshopEmptyStateResolver emptyStateResolver;
  final ValueChanged<LocationState> onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchClose;
  final VoidCallback onViewAllWorkshopsTap;
  final VoidCallback onViewAllVehiclesTap;
  final HomeServiceCategoryChanged onServiceCategoryChanged;
  final ProductRepository? productRepository;
  final RecentSearchesStore? recentSearchesStore;
  final HomeServicePopularityStore? servicePopularityStore;
  final String? selectedServiceKey;
  final String? selectedServiceLabel;
  final bool showCategoryNotFoundMessage;
  final bool serviceFilterFailed;
  final Key? workshopsSectionKey;
  final ValueChanged<String>? onSearchQueryChanged;
  final Failure? workshopFailure;
  final GarageVehicle? activeVehicle;

  static const _searchLocationResolver = WorkshopSearchLocationResolver();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _HomeColors.of(context);
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        final searchLocation = _searchLocationResolver.resolve(state.location);

        return ColoredBox(
          color: colors.background,
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    0,
                    AutolabCustomer.spacingSm,
                    0,
                    96 + bottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalMargin,
                            ),
                            child: _AutolabHomeHeader(
                              state: state,
                              onLocationTap: () => onLocationTap(state),
                              onNotificationTap: onNotificationTap,
                            ),
                          ),
                          const SizedBox(height: AutolabCustomer.spacingMd + 2),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalMargin,
                            ),
                            child: Text(
                              l10n.homeNeedsTitle,
                              style: AutolabCustomer.h2.copyWith(
                                color: colors.text,
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
                          const SizedBox(height: AutolabCustomer.spacingMd),
                          _ServiceCategories(
                            popularityStore: servicePopularityStore,
                            onCategoryChanged: onServiceCategoryChanged,
                            selectedServiceKey: selectedServiceKey,
                          ),
                          const SizedBox(height: AutolabCustomer.spacingMd),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalMargin,
                            ),
                            child: activeVehicle != null
                                ? _HomeActiveVehicleCard(
                                    vehicle: activeVehicle!,
                                    onViewAllTap: onViewAllVehiclesTap,
                                  )
                                : _HomeEmptyVehicleCard(
                                    onAddVehicleTap: onViewAllVehiclesTap,
                                  ),
                          ),
                          const SizedBox(height: AutolabCustomer.spacingScreen),
                          Column(
                            children: [
                              SizedBox(key: workshopsSectionKey, height: 12),
                              WorkshopsSection(
                                workshops: workshops,
                                fallbackWorkshops: fallbackWorkshops,
                                locationState: state,
                                proximityFilter: proximityFilter,
                                emptyStateResolver: emptyStateResolver,
                                isLoading: isWorkshopsLoading,
                                workshopFailure: workshopFailure,
                                onViewAllTap: onViewAllWorkshopsTap,
                                selectedServiceLabel: selectedServiceLabel,
                                selectedServiceKey: selectedServiceKey,
                                showCategoryNotFoundMessage:
                                    showCategoryNotFoundMessage,
                                serviceFilterFailed: serviceFilterFailed,
                                onClearServiceFilter:
                                    selectedServiceLabel == null
                                    ? null
                                    : () =>
                                          onServiceCategoryChanged(null, null),
                              ),
                            ],
                          ),
                          const SizedBox(height: AutolabCustomer.spacingScreen),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalMargin,
                            ),
                            child: Divider(
                              color: colors.divider,
                              height: 1,
                              thickness: 1,
                            ),
                          ),
                          const SizedBox(height: AutolabCustomer.spacingScreen),
                          const _PromotionsSection(),
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
                productRepository: productRepository,
                recentSearchesStore: recentSearchesStore,
              ),
            ],
          ),
        );
      },
    );
  }
}
