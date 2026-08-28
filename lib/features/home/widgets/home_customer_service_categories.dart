part of 'home_customer_content.dart';

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
