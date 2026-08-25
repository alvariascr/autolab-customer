import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/favorite_inventory_items_repository.dart';
import '../../../products/presentation/widgets/product_image.dart';
import '../../../products/presentation/widgets/product_price_text.dart';
import '../../../workshops/domain/entities/workshop.dart';
import '../../../workshops/domain/repositories/favorite_workshops_repository.dart';
import '../widgets/customer_page_header.dart';

enum _FavoriteFilter { workshops, products, services }

class FavoriteWorkshopsPage extends StatefulWidget {
  const FavoriteWorkshopsPage({super.key});

  static const routePath = '/favorites';

  @override
  State<FavoriteWorkshopsPage> createState() => _FavoriteWorkshopsPageState();
}

class _FavoriteWorkshopsPageState extends State<FavoriteWorkshopsPage> {
  late Future<_FavoritesData> _favoritesFuture;
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
            CustomerPageHeader(
              title: l10n.garageFavorites,
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
                        _FavoritesFilterBar(
                          selectedFilter: _selectedFilter,
                          favorites: favorites,
                          onChanged: (filter) {
                            setState(() => _selectedFilter = filter);
                          },
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

  List<Widget> _favoriteItems(BuildContext context, _FavoritesData favorites) {
    final l10n = AppLocalizations.of(context)!;

    switch (_selectedFilter) {
      case _FavoriteFilter.workshops:
        if (favorites.workshops.isEmpty) {
          return [
            _FavoritesMessage(
              icon: Icons.favorite_border_rounded,
              title: l10n.favoritesEmptyTitle,
              message: l10n.favoritesEmptyMessage,
            ),
          ];
        }

        return favorites.workshops
            .map(
              (workshop) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AutolabCustomer.spacingSmd,
                ),
                child: _FavoriteWorkshopCard(
                  workshop: workshop,
                  onOpen: () => context.push('/workshops/${workshop.id}'),
                  onRemove: () => _removeWorkshopFavorite(workshop),
                ),
              ),
            )
            .toList(growable: false);
      case _FavoriteFilter.products:
        return _productFavorites(
          context,
          favorites.products,
          emptyTitle: l10n.favoritesProductsEmptyTitle,
          emptyMessage: l10n.favoritesProductsEmptyMessage,
          emptyIcon: Icons.inventory_2_outlined,
        );
      case _FavoriteFilter.services:
        return _productFavorites(
          context,
          favorites.services,
          emptyTitle: l10n.favoritesServicesEmptyTitle,
          emptyMessage: l10n.favoritesServicesEmptyMessage,
          emptyIcon: Icons.home_repair_service_outlined,
        );
    }
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
        label: l10n.favoritesWorkshopsFilter,
        count: favorites.workshops.length,
      ),
      _FavoriteFilterData(
        filter: _FavoriteFilter.products,
        label: l10n.favoritesProductsFilter,
        count: favorites.products.length,
      ),
      _FavoriteFilterData(
        filter: _FavoriteFilter.services,
        label: l10n.favoritesServicesFilter,
        count: favorites.services.length,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in filters) ...[
            _FavoritesFilterChip(
              label: '${item.label} (${item.count})',
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
    required this.label,
    required this.count,
  });

  final _FavoriteFilter filter;
  final String label;
  final int count;
}

class _FavoritesFilterChip extends StatelessWidget {
  const _FavoritesFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onSelected(),
      backgroundColor: AutolabCustomer.customerSoftSurfaceColor(context),
      selectedColor: AutolabCustomer.primary,
      side: BorderSide(color: AutolabCustomer.customerBorderColor(context)),
      labelStyle: AutolabCustomer.caption.copyWith(
        color: selected
            ? AutolabCustomer.white
            : AutolabCustomer.customerTextColor(context),
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusChip),
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

    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            border: Border.all(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AutolabCustomer.customerSoftSurfaceColor(
                  context,
                ),
                backgroundImage: workshop.avatarUrl.isNotEmpty
                    ? NetworkImage(workshop.avatarUrl)
                    : null,
                child: workshop.avatarUrl.isEmpty
                    ? const Icon(Icons.storefront_rounded)
                    : null,
              ),
              const SizedBox(width: AutolabCustomer.spacingSmd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    Text(
                      workshop.locationAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSm),
              IconButton(
                tooltip: l10n.workshopFavoriteRemoved,
                onPressed: onRemove,
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AutolabCustomer.primary,
                ),
              ),
            ],
          ),
        ),
      ),
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

    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            border: Border.all(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: ProductImage(
                  imageUrl: product.primaryImageUrl,
                  height: 68,
                  borderRadius: BorderRadius.circular(
                    AutolabCustomer.radiusChip,
                  ),
                  placeholderIconSize: AutolabCustomer.iconMd,
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSmd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.body.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    Text(
                      workshopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                      ),
                    ),
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    ProductPriceText(
                      price: product.sellingPrice,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSm),
              IconButton(
                tooltip: product.itemType.trim().toLowerCase() == 'service'
                    ? l10n.serviceFavoriteRemoved
                    : l10n.productFavoriteRemoved,
                onPressed: onRemove,
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AutolabCustomer.primary,
                ),
              ),
            ],
          ),
        ),
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
