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
import '../../workshops/domain/entities/workshop.dart';
import '../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../workshops/domain/services/workshop_search_location_resolver.dart';
import '../../workshops/presentation/workshop_empty_state_resolver.dart';
import '../application/home_service_popularity_store.dart';
import '../application/recent_searches_store.dart';
import 'delivery_location_card.dart';
import 'search_bar_overlay.dart';
import 'workshops_section.dart';

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

class _HomeEmptyVehicleCard extends StatelessWidget {
  const _HomeEmptyVehicleCard({required this.onAddVehicleTap});

  final VoidCallback onAddVehicleTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _HomeColors.of(context);

    return Material(
      color: AutolabCustomer.customerSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      child: InkWell(
        onTap: onAddVehicleTap,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AutolabCustomer.customerSoftSurfaceColor(context),
                  borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                ),
                child: const Icon(
                  Icons.directions_car_filled_outlined,
                  color: AutolabCustomer.primary,
                  size: AutolabCustomer.iconSm,
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSmd),
              Expanded(
                child: Text(
                  l10n.homeActivateVehicleMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSm),
              Text(
                l10n.vehiclesAddAction,
                style: AutolabCustomer.caption.copyWith(
                  color: AutolabCustomer.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeActiveVehicleCard extends StatelessWidget {
  const _HomeActiveVehicleCard({
    required this.vehicle,
    required this.onViewAllTap,
  });

  final GarageVehicle vehicle;
  final VoidCallback onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final colors = _HomeColors.of(context);
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
            child: _HomeVehicleNetworkImage(imageUrl: vehicle.imageUrl),
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
  const _AutolabHomeHeader({
    required this.state,
    required this.onLocationTap,
    required this.onNotificationTap,
  });

  final LocationState state;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final logoWidth = AutolabCustomer.responsiveDouble(
      context,
      compact: 88,
      regular: 104,
      tablet: 124,
    );
    return Column(
      children: [
        Row(
          children: [
            _AutolabLogoMark(width: logoWidth, height: logoWidth * 0.37),
            const Spacer(),
            CustomerNotificationBell(onTap: onNotificationTap),
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
  const _ServiceCategories({
    this.popularityStore,
    required this.onCategoryChanged,
    this.selectedServiceKey,
  });

  final HomeServicePopularityStore? popularityStore;
  final HomeServiceCategoryChanged onCategoryChanged;
  final String? selectedServiceKey;

  @override
  State<_ServiceCategories> createState() => _ServiceCategoriesState();
}

class _ServiceCategoriesState extends State<_ServiceCategories> {
  static const _tapCooldown = Duration(seconds: 1);

  Map<String, int> _clickCounts = const {};
  final Map<String, DateTime> _lastTapByService = {};
  Locale? _itemsLocale;
  List<_ServiceCategory> _defaultItems = const [];
  List<_ServiceCategory> _sortedItems = const [];

  @override
  void initState() {
    super.initState();
    _loadClickCounts();
  }

  @override
  void didUpdateWidget(covariant _ServiceCategories oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.popularityStore != widget.popularityStore) {
      _loadClickCounts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_itemsLocale == locale) return;

    _itemsLocale = locale;
    _defaultItems = _buildDefaultItems(AppLocalizations.of(context)!);
    _sortItems();
  }

  Future<void> _loadClickCounts() async {
    final store = widget.popularityStore;
    if (store == null) return;

    try {
      final clickCounts = await store.loadClickCounts();
      if (!mounted) return;
      setState(() {
        _clickCounts = clickCounts;
        _sortItems();
      });
    } catch (_) {
      // Popularity is optional; the original order remains as fallback.
    }
  }

  Future<void> _recordClick(String serviceKey) async {
    final store = widget.popularityStore;
    if (store == null) return;

    try {
      await store.recordClick(serviceKey);
    } catch (_) {
      // A tracking failure must never prevent the customer from using the home.
    }
  }

  bool _acceptTap(String serviceKey) {
    final now = DateTime.now();
    final lastTap = _lastTapByService[serviceKey];
    if (lastTap != null && now.difference(lastTap) < _tapCooldown) {
      return false;
    }

    _lastTapByService[serviceKey] = now;
    return true;
  }

  void _sortItems() {
    _sortedItems = sortByServicePopularity<_ServiceCategory>(
      items: _defaultItems,
      serviceKeyOf: (item) => item.serviceKey,
      clickCounts: _clickCounts,
    );
  }

  List<_ServiceCategory> _buildDefaultItems(AppLocalizations l10n) {
    return [
      _ServiceCategory(l10n.homeServiceInspection, 'inspeccion'),
      _ServiceCategory(l10n.homeServiceOilChange, 'cambio_aceite'),
      _ServiceCategory(l10n.homeServiceTireChange, 'cambio_llanta'),
      _ServiceCategory(l10n.homeServiceBalance, 'balanceo'),
      _ServiceCategory(l10n.homeServiceAlignment, 'alineamiento'),
      _ServiceCategory(l10n.homeServicePunctureRepair, 'reparacion_llanta'),
      _ServiceCategory(l10n.homeServiceDetailing, 'estetica_automotriz'),
      _ServiceCategory(l10n.homeServiceElectrical, 'electrico'),
      _ServiceCategory(l10n.homeServiceInstallation, 'instalacion'),
      _ServiceCategory(l10n.homeServiceAirConditioning, 'aire_acondicionado'),
      _ServiceCategory(l10n.homeServiceTow, 'grua'),
      _ServiceCategory(l10n.homeServiceTires, 'llantas'),
      _ServiceCategory(l10n.homeServiceOils, 'aceites'),
      _ServiceCategory(l10n.homeServiceParts, 'repuestos'),
      _ServiceCategory(l10n.homeServiceCoolant, 'coolant'),
      _ServiceCategory(l10n.homeServiceCarWashProduct, 'producto_auto_lavado'),
      _ServiceCategory(l10n.homeServiceLights, 'luces'),
      _ServiceCategory(l10n.homeServiceBatteries, 'baterias'),
      _ServiceCategory(l10n.homeServiceFluids, 'liquidos'),
      _ServiceCategory(l10n.homeServiceLubricants, 'lubricantes'),
      _ServiceCategory(l10n.homeServiceChemicals, 'quimicos'),
      _ServiceCategory(l10n.homeServiceAdditives, 'aditivos'),
      _ServiceCategory(l10n.homeServiceGreases, 'grasas'),
      _ServiceCategory(l10n.homeServiceFilters, 'filtros'),
      _ServiceCategory(l10n.homeServiceTechnology, 'tecnologia'),
      _ServiceCategory(l10n.homeServiceRims, 'aros'),
      _ServiceCategory(l10n.homeServiceRacks, 'racks'),
      _ServiceCategory(l10n.homeServiceFloorMats, 'alfombras'),
      _ServiceCategory(l10n.homeServiceWipers, 'escobillas'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _HomeColors.of(context);
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);
    final items = _sortedItems;
    final itemWidth = AutolabCustomer.responsiveDouble(
      context,
      compact: 82,
      regular: 92,
      tablet: 104,
    );
    final iconSize = AutolabCustomer.responsiveDouble(
      context,
      compact: AutolabCustomer.iconLg,
      regular: AutolabCustomer.iconLg + 6,
      tablet: AutolabCustomer.iconLg + 10,
    );
    final listHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 104,
      regular: 110,
      tablet: 118,
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
          final isSelected = widget.selectedServiceKey == item.serviceKey;
          final effectiveIconSize = item.serviceKey == 'electrico'
              ? iconSize * 1.18
              : iconSize;
          final itemColor = isSelected
              ? AutolabCustomer.primary
              : AutolabCustomer.customerTextColor(context);

          return GestureDetector(
            key: ValueKey('home-service-${item.serviceKey}'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_acceptTap(item.serviceKey)) return;
              final selectedServiceKey = isSelected ? null : item.serviceKey;
              unawaited(_recordClick(item.serviceKey));
              widget.onCategoryChanged(
                selectedServiceKey,
                selectedServiceKey == null ? null : item.label,
              );
            },
            child: SizedBox(
              width: itemWidth,
              child: Column(
                children: [
                  const SizedBox(height: 1),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: SvgPicture.asset(
                      item.assetIcon,
                      key: ValueKey('${item.assetIcon}-$isSelected'),
                      width: effectiveIconSize,
                      height: effectiveIconSize,
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingSm),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    softWrap: true,
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
  const _ServiceCategory(this.label, String assetName)
    : serviceKey = assetName,
      assetIcon = 'assets/images/icons/$assetName.svg';

  final String label;
  final String serviceKey;
  final String assetIcon;
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
