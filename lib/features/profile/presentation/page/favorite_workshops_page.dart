import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/favorite_inventory_items_repository.dart';
import '../../../products/presentation/widgets/product_image.dart';
import '../../../workshops/domain/entities/workshop.dart';
import '../../../workshops/domain/repositories/favorite_workshops_repository.dart';

enum _FavoriteFilter { all, workshops, services, products }

class FavoriteWorkshopsPage extends StatefulWidget {
  const FavoriteWorkshopsPage({super.key});

  static const routePath = '/favorites';

  @override
  State<FavoriteWorkshopsPage> createState() => _FavoriteWorkshopsPageState();
}

class _FavoriteWorkshopsPageState extends State<FavoriteWorkshopsPage> {
  late Future<_FavoritesData> _favoritesFuture;
  final TextEditingController _searchController = TextEditingController();
  _FavoriteFilter _selectedFilter = _FavoriteFilter.workshops;

  FavoriteWorkshopsRepository get _workshopsRepository =>
      sl<FavoriteWorkshopsRepository>();

  FavoriteInventoryItemsRepository get _itemsRepository =>
      sl<FavoriteInventoryItemsRepository>();

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_FavoritesData> _loadFavorites() async {
    final results = await Future.wait([
      _workshopsRepository.getFavoriteWorkshops(),
      _itemsRepository.getFavoriteProducts(),
      _itemsRepository.getFavoriteServices(),
    ]);

    return _FavoritesData(
      workshops: results[0] as List<Workshop>,
      products: results[1] as List<Product>,
      services: results[2] as List<Product>,
    );
  }

  void _reload() {
    setState(() {
      _favoritesFuture = _loadFavorites();
    });
  }

  void _showAllFavorites() {
    setState(() => _selectedFilter = _FavoriteFilter.all);
  }

  Future<void> _removeWorkshopFavorite(Workshop workshop) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _workshopsRepository.removeFavoriteWorkshop(workshop.id);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.workshopFavoriteRemoved)));
      _reload();
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.workshopFavoriteError)));
    }
  }

  Future<void> _removeItemFavorite(Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final removedMessage = product.itemType.trim().toLowerCase() == 'service'
        ? l10n.serviceFavoriteRemoved
        : l10n.productFavoriteRemoved;

    try {
      await _itemsRepository.removeFavoriteInventoryItem(product.id);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(removedMessage)));
      _reload();
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.inventoryFavoriteError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _FavoritesHeader(
              title: l10n.garageFavorites,
              showAllLabel: l10n.favoritesShowAllAction,
              onShowAll: _showAllFavorites,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            Expanded(
              child: FutureBuilder<_FavoritesData>(
                future: _favoritesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _FavoritesMessage(
                      icon: Icons.error_outline_rounded,
                      title: l10n.favoritesLoadErrorTitle,
                      message: l10n.myAppointmentsRetryMessage,
                      actionLabel: l10n.myAppointmentsRetryAction,
                      onAction: _reload,
                    );
                  }

                  final favorites = snapshot.data ?? _FavoritesData.empty;
                  final visibleCount = _visibleFavoriteCount(favorites);

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    color: AutolabCustomer.primary,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        AutolabCustomer.responsiveScreenMargin(context),
                        AutolabCustomer.spacingSmd,
                        AutolabCustomer.responsiveScreenMargin(context),
                        AutolabCustomer.spacingXl +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      children: [
                        _FavoritesSearchField(
                          controller: _searchController,
                          hintText: l10n.favoritesSearchHint,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AutolabCustomer.spacingSmd),
                        _FavoritesFilterBar(
                          selectedFilter: _selectedFilter,
                          favorites: favorites,
                          onChanged: (filter) {
                            setState(() => _selectedFilter = filter);
                          },
                        ),
                        const SizedBox(height: AutolabCustomer.spacingSmd),
                        Text(
                          l10n.favoritesCount(visibleCount),
                          style: AutolabCustomer.body.copyWith(
                            color: AutolabCustomer.customerSecondaryTextColor(
                              context,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AutolabCustomer.spacingSmd),
                        ..._favoriteItems(context, favorites),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _visibleFavoriteCount(_FavoritesData favorites) {
    return switch (_selectedFilter) {
      _FavoriteFilter.all =>
        _filteredWorkshops(favorites.workshops).length +
            _filteredProducts(favorites.services).length +
            _filteredProducts(favorites.products).length,
      _FavoriteFilter.workshops => _filteredWorkshops(
        favorites.workshops,
      ).length,
      _FavoriteFilter.services => _filteredProducts(favorites.services).length,
      _FavoriteFilter.products => _filteredProducts(favorites.products).length,
    };
  }

  List<Widget> _favoriteItems(BuildContext context, _FavoritesData favorites) {
    final l10n = AppLocalizations.of(context)!;

    switch (_selectedFilter) {
      case _FavoriteFilter.all:
        final items = [
          ..._workshopFavoriteCards(
            context,
            _filteredWorkshops(favorites.workshops),
          ),
          ..._productFavoriteCards(
            context,
            _filteredProducts(favorites.services),
          ),
          ..._productFavoriteCards(
            context,
            _filteredProducts(favorites.products),
          ),
        ];

        if (items.isEmpty) {
          return [
            _FavoritesMessage(
              icon: Icons.favorite_border_rounded,
              title: l10n.favoritesEmptyTitle,
              message: l10n.favoritesEmptyMessage,
            ),
          ];
        }

        return items;
      case _FavoriteFilter.workshops:
        final workshops = _filteredWorkshops(favorites.workshops);
        if (workshops.isEmpty) {
          return [
            _FavoritesMessage(
              icon: Icons.favorite_border_rounded,
              title: l10n.favoritesEmptyTitle,
              message: l10n.favoritesEmptyMessage,
            ),
          ];
        }

        return _workshopFavoriteCards(context, workshops);
      case _FavoriteFilter.services:
        return _productFavorites(
          context,
          _filteredProducts(favorites.services),
          emptyTitle: l10n.favoritesServicesEmptyTitle,
          emptyMessage: l10n.favoritesServicesEmptyMessage,
          emptyIcon: Icons.home_repair_service_outlined,
        );
      case _FavoriteFilter.products:
        return _productFavorites(
          context,
          _filteredProducts(favorites.products),
          emptyTitle: l10n.favoritesProductsEmptyTitle,
          emptyMessage: l10n.favoritesProductsEmptyMessage,
          emptyIcon: Icons.inventory_2_outlined,
        );
    }
  }

  List<Widget> _workshopFavoriteCards(
    BuildContext context,
    List<Workshop> workshops,
  ) {
    return workshops
        .map(
          (workshop) => Padding(
            padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingSmd),
            child: _FavoriteWorkshopCard(
              workshop: workshop,
              onOpen: () => context.push('/workshops/${workshop.id}'),
              onRemove: () => _removeWorkshopFavorite(workshop),
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _productFavorites(
    BuildContext context,
    List<Product> products, {
    required String emptyTitle,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (products.isEmpty) {
      return [
        _FavoritesMessage(
          icon: emptyIcon,
          title: emptyTitle,
          message: emptyMessage,
        ),
      ];
    }

    return _productFavoriteCards(context, products);
  }

  List<Widget> _productFavoriteCards(
    BuildContext context,
    List<Product> products,
  ) {
    return products
        .map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingSmd),
            child: _FavoriteProductCard(
              product: product,
              onOpen: () {
                context.push(
                  '/workshops/${product.workshopId}/products/${product.id}',
                  extra: product,
                );
              },
              onRemove: () => _removeItemFavorite(product),
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Workshop> _filteredWorkshops(List<Workshop> workshops) {
    final query = _normalizedSearchQuery;
    if (query.isEmpty) {
      return workshops;
    }

    return workshops
        .where((workshop) => _matchesWorkshop(workshop, query))
        .toList(growable: false);
  }

  List<Product> _filteredProducts(List<Product> products) {
    final query = _normalizedSearchQuery;
    if (query.isEmpty) {
      return products;
    }

    return products
        .where((product) => _matchesProduct(product, query))
        .toList(growable: false);
  }

  bool _matchesWorkshop(Workshop workshop, String query) {
    return _normalize(workshop.name).contains(query) ||
        _normalize(workshop.locationAddress).contains(query) ||
        _normalize(workshop.description).contains(query);
  }

  bool _matchesProduct(Product product, String query) {
    return _normalize(product.name).contains(query) ||
        _normalize(product.effectiveDescription).contains(query) ||
        _normalize(product.workshopName).contains(query);
  }

  String get _normalizedSearchQuery => _normalize(_searchController.text);

  String _normalize(String value) => value.trim().toLowerCase();
}

class _FavoritesData {
  const _FavoritesData({
    required this.workshops,
    required this.products,
    required this.services,
  });

  static const empty = _FavoritesData(
    workshops: [],
    products: [],
    services: [],
  );

  final List<Workshop> workshops;
  final List<Product> products;
  final List<Product> services;
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({
    required this.title,
    required this.showAllLabel,
    required this.onShowAll,
    required this.onBack,
  });

  final String title;
  final String showAllLabel;
  final VoidCallback onShowAll;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AutolabCustomer.responsiveScreenMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AutolabCustomer.spacingSm,
        horizontalPadding,
        AutolabCustomer.spacingSm,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _FavoritesBackButton(onPressed: onBack),
              ),
              const AutolabLogoMark(width: 96, height: 36),
            ],
          ),
          const SizedBox(height: AutolabCustomer.spacingLg),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AutolabCustomer.h2.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onShowAll,
                style: TextButton.styleFrom(
                  foregroundColor: AutolabCustomer.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AutolabCustomer.spacingSm,
                  ),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  showAllLabel,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavoritesBackButton extends StatelessWidget {
  const _FavoritesBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 36,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AutolabCustomer.customerSecondaryTextColor(context),
            size: AutolabCustomer.iconSm,
          ),
        ),
      ),
    );
  }
}

class _FavoritesSearchField extends StatelessWidget {
  const _FavoritesSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AutolabCustomer.body.copyWith(
        color: AutolabCustomer.customerTextColor(context),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AutolabCustomer.body.copyWith(
          color: AutolabCustomer.customerHintColor(context),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AutolabCustomer.customerSecondaryTextColor(context),
        ),
        filled: true,
        fillColor: AutolabCustomer.customerSoftSurfaceColor(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AutolabCustomer.spacingMd,
          vertical: AutolabCustomer.spacingSmd,
        ),
        border: _searchBorder(context),
        enabledBorder: _searchBorder(context),
        focusedBorder: _searchBorder(context, color: AutolabCustomer.primary),
      ),
    );
  }

  OutlineInputBorder _searchBorder(BuildContext context, {Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusInput),
      borderSide: BorderSide(
        color: color ?? AutolabCustomer.customerBorderColor(context),
      ),
    );
  }
}

class _FavoritesFilterBar extends StatelessWidget {
  const _FavoritesFilterBar({
    required this.selectedFilter,
    required this.favorites,
    required this.onChanged,
  });

  final _FavoriteFilter selectedFilter;
  final _FavoritesData favorites;
  final ValueChanged<_FavoriteFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = [
      _FavoriteFilterData(
        filter: _FavoriteFilter.workshops,
        icon: Icons.garage_outlined,
        label: l10n.favoritesWorkshopsFilter,
        count: favorites.workshops.length,
      ),
      _FavoriteFilterData(
        filter: _FavoriteFilter.services,
        icon: Icons.handyman_outlined,
        label: l10n.favoritesServicesFilter,
        count: favorites.services.length,
      ),
      _FavoriteFilterData(
        filter: _FavoriteFilter.products,
        icon: Icons.sell_outlined,
        label: l10n.favoritesProductsFilter,
        count: favorites.products.length,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in filters) ...[
            _FavoritesFilterChip(
              icon: item.icon,
              label: item.label,
              count: item.count,
              selected: selectedFilter == item.filter,
              onSelected: () => onChanged(item.filter),
            ),
            const SizedBox(width: AutolabCustomer.spacingSm),
          ],
        ],
      ),
    );
  }
}

class _FavoriteFilterData {
  const _FavoriteFilterData({
    required this.filter,
    required this.icon,
    required this.label,
    required this.count,
  });

  final _FavoriteFilter filter;
  final IconData icon;
  final String label;
  final int count;
}

class _FavoritesFilterChip extends StatelessWidget {
  const _FavoritesFilterChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? AutolabCustomer.primary
        : AutolabCustomer.customerSecondaryTextColor(context);

    return Material(
      color: selected
          ? AutolabCustomer.primary.withValues(alpha: 0.10)
          : AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusButton),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusButton),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AutolabCustomer.spacingMd,
            vertical: AutolabCustomer.spacingSmd,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusButton),
            border: Border.all(
              color: selected
                  ? AutolabCustomer.primary
                  : AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foregroundColor, size: AutolabCustomer.iconSm),
              const SizedBox(width: AutolabCustomer.spacingSm),
              Text(
                '$label ($count)',
                style: AutolabCustomer.caption.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteWorkshopCard extends StatelessWidget {
  const _FavoriteWorkshopCard({
    required this.workshop,
    required this.onOpen,
    required this.onRemove,
  });

  final Workshop workshop;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final address = workshop.locationAddress.trim();
    final description = workshop.description.trim();
    final imageUrl = workshop.coverUrl.trim().isNotEmpty
        ? workshop.coverUrl.trim()
        : workshop.avatarUrl.trim();

    return _FavoriteCardShell(
      onTap: onOpen,
      image: _FavoriteNetworkImage(imageUrl: imageUrl),
      title: workshop.name,
      subtitle: address.isNotEmpty ? address : description,
      meta: description.isNotEmpty && address.isNotEmpty ? description : null,
      metaIcon: Icons.info_outline_rounded,
      removeTooltip: l10n.workshopFavoriteRemoved,
      onRemove: onRemove,
      subtitleIcon: Icons.location_on_outlined,
    );
  }
}

class _FavoriteProductCard extends StatelessWidget {
  const _FavoriteProductCard({
    required this.product,
    required this.onOpen,
    required this.onRemove,
  });

  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workshopName = product.workshopName.trim().isEmpty
        ? l10n.serviceDetailWorkshopFallback
        : product.workshopName.trim();

    return _FavoriteCardShell(
      onTap: onOpen,
      image: ProductImage(
        imageUrl: product.primaryImageUrl,
        height: _FavoriteCardShell.imageSize,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusInput),
        placeholderIconSize: AutolabCustomer.iconLg,
      ),
      title: product.name,
      subtitle: product.effectiveDescription,
      meta: workshopName,
      metaIcon: Icons.garage_outlined,
      removeTooltip: product.itemType.trim().toLowerCase() == 'service'
          ? l10n.serviceFavoriteRemoved
          : l10n.productFavoriteRemoved,
      onRemove: onRemove,
      subtitleIcon: Icons.info_outline_rounded,
    );
  }
}

class _FavoriteCardShell extends StatelessWidget {
  const _FavoriteCardShell({
    required this.onTap,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.removeTooltip,
    required this.onRemove,
    this.meta,
    this.metaIcon,
    this.subtitleIcon,
  });

  static const double imageSize = 96;

  final VoidCallback onTap;
  final Widget image;
  final String title;
  final String subtitle;
  final String? meta;
  final IconData? metaIcon;
  final String removeTooltip;
  final VoidCallback onRemove;
  final IconData? subtitleIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        child: Ink(
          padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            border: Border.all(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Row(
            children: [
              SizedBox.square(dimension: imageSize, child: image),
              const SizedBox(width: AutolabCustomer.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: AutolabCustomer.spacingSm),
                      _FavoriteMetaLine(
                        icon: subtitleIcon,
                        text: subtitle,
                        maxLines: 2,
                      ),
                    ],
                    if (meta != null && meta!.trim().isNotEmpty) ...[
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      _FavoriteMetaLine(
                        icon: metaIcon,
                        text: meta!,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSm),
              IconButton(
                tooltip: removeTooltip,
                onPressed: onRemove,
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AutolabCustomer.primary,
                  size: AutolabCustomer.iconLg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteMetaLine extends StatelessWidget {
  const _FavoriteMetaLine({required this.text, this.icon, this.maxLines = 1});

  final String text;
  final IconData? icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: AutolabCustomer.customerSecondaryTextColor(context),
            size: AutolabCustomer.iconSm,
          ),
          const SizedBox(width: AutolabCustomer.spacingXs),
        ],
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteNetworkImage extends StatelessWidget {
  const _FavoriteNetworkImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AutolabCustomer.radiusInput);

    if (imageUrl.isEmpty) {
      return _FavoriteImageFallback(borderRadius: borderRadius);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        imageUrl,
        width: _FavoriteCardShell.imageSize,
        height: _FavoriteCardShell.imageSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _FavoriteImageFallback(borderRadius: borderRadius);
        },
      ),
    );
  }
}

class _FavoriteImageFallback extends StatelessWidget {
  const _FavoriteImageFallback({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.garage_outlined,
        color: AutolabCustomer.primary,
        size: AutolabCustomer.iconLg,
      ),
    );
  }
}

class _FavoritesMessage extends StatelessWidget {
  const _FavoritesMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AutolabCustomer.primary, size: 58),
            const SizedBox(height: AutolabCustomer.spacingMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AutolabCustomer.h3.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AutolabCustomer.spacingLg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AutolabCustomer.primary,
                  foregroundColor: AutolabCustomer.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
