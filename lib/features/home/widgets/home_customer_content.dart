import 'dart:io';

import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/location/location_cubit.dart';
import '../../../core/location/location_state.dart';
import '../../../core/theme/autolab_customer.dart';
import '../../../l10n/app_localizations.dart';
import '../../products/domain/repositories/product_repository.dart';
import '../../profile/domain/entities/garage_vehicle.dart';
import '../../profile/presentation/helpers/garage_vehicle_display.dart';
import '../../workshops/domain/entities/workshop.dart';
import '../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../workshops/domain/services/workshop_search_location_resolver.dart';
import '../../workshops/presentation/workshop_empty_state_resolver.dart';
import '../application/recent_searches_store.dart';
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
    required this.onViewAllWorkshopsTap,
    required this.onViewAllVehiclesTap,
    this.activeVehicle,
    this.activeVehicleImagePath,
    this.onSearchQueryChanged,
    this.workshopFailure,
    this.productRepository,
    this.recentSearchesStore,
  });

  final List<Workshop> workshops;
  final bool isWorkshopsLoading;
  final bool showSearchBar;
  final TextEditingController searchController;
  final WorkshopProximityFilter proximityFilter;
  final WorkshopEmptyStateResolver emptyStateResolver;
  final ValueChanged<LocationState> onLocationTap;
  final VoidCallback onSearchClose;
  final VoidCallback onViewAllWorkshopsTap;
  final VoidCallback onViewAllVehiclesTap;
  final ProductRepository? productRepository;
  final RecentSearchesStore? recentSearchesStore;
  final ValueChanged<String>? onSearchQueryChanged;
  final Failure? workshopFailure;
  final GarageVehicle? activeVehicle;
  final String? activeVehicleImagePath;

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
                          const _ServiceCategories(),
                          if (activeVehicle case final vehicle?) ...[
                            const SizedBox(height: AutolabCustomer.spacingMd),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalMargin,
                              ),
                              child: _HomeActiveVehicleCard(
                                vehicle: vehicle,
                                localImagePath: activeVehicleImagePath,
                                onViewAllTap: onViewAllVehiclesTap,
                              ),
                            ),
                          ],
                          const SizedBox(height: AutolabCustomer.spacingScreen),
                          WorkshopsSection(
                            workshops: workshops,
                            locationState: state,
                            proximityFilter: proximityFilter,
                            emptyStateResolver: emptyStateResolver,
                            isLoading: isWorkshopsLoading,
                            workshopFailure: workshopFailure,
                            onViewAllTap: onViewAllWorkshopsTap,
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

class _HomeActiveVehicleCard extends StatelessWidget {
  const _HomeActiveVehicleCard({
    required this.vehicle,
    required this.onViewAllTap,
    this.localImagePath,
  });

  final GarageVehicle vehicle;
  final String? localImagePath;
  final VoidCallback onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final colors = _HomeColors.of(context);
    final localImagePath = this.localImagePath;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            height: 42,
            child: localImagePath != null
                ? Image.file(
                    File(localImagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        _HomeVehicleNetworkImage(imageUrl: vehicle.imageUrl),
                  )
                : _HomeVehicleNetworkImage(imageUrl: vehicle.imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garageVehicleTitle(vehicle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  garageActiveVehicleSubtitle(vehicle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.caption.copyWith(color: colors.text),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AutolabCustomer.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)!.garageActiveVehicle,
                      style: AutolabCustomer.caption.copyWith(
                        color: colors.text,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewAllTap,
            style: TextButton.styleFrom(
              foregroundColor: AutolabCustomer.primary,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppLocalizations.of(context)!.vehiclesViewAllAction,
              style: AutolabCustomer.caption.copyWith(
                color: AutolabCustomer.primary,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeVehicleNetworkImage extends StatelessWidget {
  const _HomeVehicleNetworkImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return const Icon(
        Icons.directions_car_filled_rounded,
        color: AutolabCustomer.primary,
        size: 36,
      );
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.directions_car_filled_rounded,
        color: AutolabCustomer.primary,
        size: 36,
      ),
    );
  }
}

class _AutolabHomeHeader extends StatelessWidget {
  const _AutolabHomeHeader({required this.state, required this.onLocationTap});

  final LocationState state;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    final colors = _HomeColors.of(context);
    final logoWidth = AutolabCustomer.responsiveDouble(
      context,
      compact: 88,
      regular: 104,
      tablet: 124,
    );
    final notificationSize = AutolabCustomer.responsiveDouble(
      context,
      compact: AutolabCustomer.iconMd,
      regular: AutolabCustomer.iconLg - 4,
      tablet: AutolabCustomer.iconLg,
    );

    return Column(
      children: [
        Row(
          children: [
            _AutolabLogoMark(width: logoWidth, height: logoWidth * 0.37),
            const Spacer(),
            Icon(
              Icons.notifications_none_rounded,
              color: colors.text,
              size: notificationSize,
            ),
          ],
        ),
        const SizedBox(height: AutolabCustomer.spacingSm),
        DeliveryLocationCard(state: state, onTap: onLocationTap),
      ],
    );
  }
}

class _AutolabLogoMark extends StatelessWidget {
  const _AutolabLogoMark({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _AutolabLogoPainter()),
    );
  }
}

class _AutolabLogoPainter extends CustomPainter {
  static const _sourceWidth = 622.0;
  static const _sourceHeight = 224.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _sourceWidth;
    final dy = (size.height - (_sourceHeight * scale)) / 2;
    canvas
      ..save()
      ..translate(0, dy)
      ..scale(scale);

    final paint = Paint()..color = AutolabCustomer.primary;
    for (final polygon in _polygons) {
      final path = Path()..moveTo(polygon.first.dx, polygon.first.dy);
      for (final point in polygon.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  static const _polygons = [
    [
      Offset(503.87, 7.07),
      Offset(512.96, 35.05),
      Offset(542.39, 35.05),
      Offset(518.58, 52.35),
      Offset(527.68, 80.34),
      Offset(503.87, 63.04),
      Offset(480.07, 80.34),
      Offset(489.16, 52.35),
      Offset(465.35, 35.05),
      Offset(494.78, 35.05),
    ],
    [
      Offset(279.41, 7.07),
      Offset(404.43, 7.07),
      Offset(462.51, 109.9),
      Offset(542.39, 109.9),
      Offset(603.12, 216.93),
      Offset(397.95, 216.93),
    ],
    [
      Offset(18.88, 216.93),
      Offset(51.05, 160),
      Offset(22.67, 109.9),
      Offset(79.45, 109.74),
      Offset(137.46, 7.07),
      Offset(261.85, 7.07),
      Offset(380.35, 216.93),
      Offset(256, 216.93),
      Offset(199.66, 117.18),
      Offset(174.43, 161.84),
      Offset(205.94, 216.93),
    ],
  ];
}

class _ServiceCategories extends StatefulWidget {
  const _ServiceCategories();

  @override
  State<_ServiceCategories> createState() => _ServiceCategoriesState();
}

class _ServiceCategoriesState extends State<_ServiceCategories> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _HomeColors.of(context);
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);
    final items = [
      _ServiceCategory(
        l10n.homeServiceBalance,
        Icons.car_repair_outlined,
        assetIcon: 'assets/images/icons/balanceo.png',
      ),
      _ServiceCategory(
        l10n.homeServiceTow,
        Icons.local_shipping_outlined,
        assetIcon: 'assets/images/icons/grua.png',
      ),
      _ServiceCategory(
        l10n.homeServiceTires,
        Icons.tire_repair_outlined,
        assetIcon: 'assets/images/icons/llantas.png',
      ),
      _ServiceCategory(
        l10n.homeServiceGeneralReview,
        Icons.oil_barrel_outlined,
        assetIcon: 'assets/images/icons/revision_general.png',
      ),
      _ServiceCategory(
        l10n.homeServiceElectricMechanic,
        Icons.electric_car_outlined,
        assetIcon: 'assets/images/icons/mecanica_electrica.png',
      ),
      _ServiceCategory(
        l10n.homeServiceBattery,
        Icons.battery_unknown_outlined,
        assetIcon: 'assets/images/icons/bateria_de_coche.png',
      ),
    ];
    final itemWidth = AutolabCustomer.responsiveDouble(
      context,
      compact: 62,
      regular: 72,
      tablet: 84,
    );
    final iconSize = AutolabCustomer.responsiveDouble(
      context,
      compact: AutolabCustomer.iconLg,
      regular: AutolabCustomer.iconLg + 6,
      tablet: AutolabCustomer.iconLg + 10,
    );
    final listHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 78,
      regular: 86,
      tablet: 96,
    );
    final separatorWidth = AutolabCustomer.responsiveDouble(
      context,
      compact: AutolabCustomer.spacingSmd,
      regular: AutolabCustomer.spacingMd + 2,
      tablet: AutolabCustomer.spacingLg,
    );

    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: separatorWidth),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = _selectedIndex == index;
          final itemColor = isSelected
              ? AutolabCustomer.primary
              : AutolabCustomer.customerTextColor(context);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _selectedIndex = isSelected ? null : index;
              });
            },
            child: SizedBox(
              width: itemWidth,
              child: Column(
                children: [
                  const SizedBox(height: 1),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: item.assetIcon != null
                        ? ImageIcon(
                            AssetImage(item.assetIcon!),
                            key: ValueKey('${item.assetIcon}-$isSelected'),
                            color: itemColor,
                            size: iconSize,
                          )
                        : Icon(
                            item.icon,
                            key: ValueKey(isSelected),
                            color: itemColor,
                            size: iconSize,
                          ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingSm),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AutolabCustomer.caption.copyWith(
                      color: isSelected ? AutolabCustomer.primary : colors.text,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceCategory {
  const _ServiceCategory(this.label, this.icon, {this.assetIcon});

  final String label;
  final IconData icon;
  final String? assetIcon;
}

class _PromotionsSection extends StatelessWidget {
  const _PromotionsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _HomeColors.of(context);
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);
    final cardHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 140,
      regular: 160,
      tablet: 190,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homePromotionsComingSoon,
                  style: AutolabCustomer.h2.copyWith(
                    color: colors.text,
                    fontSize: AutolabCustomer.responsiveDouble(
                      context,
                      compact: 21,
                      regular: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AutolabCustomer.spacingSmd + 2),
          Container(
            height: cardHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: AutolabCustomer.primary,
                  size: AutolabCustomer.iconLg + 2,
                ),
                const SizedBox(height: AutolabCustomer.spacingSmd - 2),
                Text(
                  l10n.homePromotionsTitle,
                  style: AutolabCustomer.bodyLarge.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                Text(
                  l10n.homePromotionsSubtitle,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.caption.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AutolabCustomer.spacingMd + 2),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PromoDot(isActive: true),
              _PromoDot(isActive: false),
              _PromoDot(isActive: false),
              _PromoDot(isActive: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoDot extends StatelessWidget {
  const _PromoDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AutolabCustomer.primary
            : _HomeColors.of(context).inactiveDot,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HomeColors {
  const _HomeColors({
    required this.background,
    required this.text,
    required this.secondaryText,
    required this.surface,
    required this.divider,
    required this.inactiveDot,
  });

  final Color background;
  final Color text;
  final Color secondaryText;
  final Color surface;
  final Color divider;
  final Color inactiveDot;

  static _HomeColors of(BuildContext context) {
    return _HomeColors(
      background: AutolabCustomer.customerBackgroundColor(context),
      text: AutolabCustomer.customerTextColor(context),
      secondaryText: AutolabCustomer.customerSecondaryTextColor(context),
      surface: AutolabCustomer.customerSurfaceColor(context),
      divider: AutolabCustomer.customerDividerColor(context),
      inactiveDot: AutolabCustomer.customerElevatedSurfaceColor(context),
    );
  }
}
