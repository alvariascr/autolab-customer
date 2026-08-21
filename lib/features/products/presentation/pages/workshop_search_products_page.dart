import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/router/build_context_navigation.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/domain/home_service_inventory_matcher.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/services/product_search_filter.dart';
import '../widgets/product_image.dart';
import '../widgets/product_price_text.dart';

enum _ProductSortOption { relevance, lowestPrice, highestPrice, name }

class WorkshopSearchProductsPage extends StatefulWidget {
  const WorkshopSearchProductsPage({
    super.key,
    required this.workshopId,
    required this.query,
    this.serviceKey,
  });

  final String workshopId;
  final String query;
  final String? serviceKey;

  @override
  State<WorkshopSearchProductsPage> createState() =>
      _WorkshopSearchProductsPageState();
}

class _WorkshopSearchProductsPageState
    extends State<WorkshopSearchProductsPage> {
  static const _searchFilter = ProductSearchFilter();
  static const _homeServiceMatcher = HomeServiceInventoryMatcher();

  late final TextEditingController _controller;
  late Future<List<Product>> _productsFuture;
  _ProductSortOption _sortOption = _ProductSortOption.relevance;
  String? _selectedBrand;
  String? _selectedCategory;
  String? _selectedType;
  bool _onlyAvailable = false;
  late bool _useInitialServiceFilter;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _useInitialServiceFilter = widget.serviceKey?.trim().isNotEmpty ?? false;
    _productsFuture = _loadProducts();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Product>> _loadProducts() async {
    final result = await sl<ProductRepository>().getActiveProductsByWorkshop(
      widget.workshopId,
    );

    return result.fold((_) => const <Product>[], (products) => products);
  }

  List<Product> _applyFilters(List<Product> products) {
    final query = _controller.text.trim();
    final serviceKey = widget.serviceKey?.trim();
    final shouldFilterByService =
        _useInitialServiceFilter && serviceKey != null && serviceKey.isNotEmpty;
    final matchingProducts = shouldFilterByService
        ? products
              .where(
                (product) =>
                    _homeServiceMatcher.matchesProduct(serviceKey, product),
              )
              .toList()
        : query.isEmpty
        ? products
        : _searchFilter.filter(products: products, query: query);

    final filtered = matchingProducts.where((product) {
      if (_onlyAvailable && (product.currentStock ?? 0) <= 0) {
        return false;
      }

      if (_selectedBrand != null && product.brandName != _selectedBrand) {
        return false;
      }

      if (_selectedCategory != null &&
          product.categoryName != _selectedCategory) {
        return false;
      }

      if (_selectedType != null && product.itemType != _selectedType) {
        return false;
      }

      return true;
    }).toList();

    switch (_sortOption) {
      case _ProductSortOption.relevance:
        return filtered;
      case _ProductSortOption.lowestPrice:
        filtered.sort(
          (left, right) => (left.sellingPrice ?? double.infinity).compareTo(
            right.sellingPrice ?? double.infinity,
          ),
        );
        return filtered;
      case _ProductSortOption.highestPrice:
        filtered.sort(
          (left, right) =>
              (right.sellingPrice ?? -1).compareTo(left.sellingPrice ?? -1),
        );
        return filtered;
      case _ProductSortOption.name:
        filtered.sort((left, right) => left.name.compareTo(right.name));
        return filtered;
    }
  }

  List<String> _filterValues(
    List<Product> products,
    String Function(Product product) selector,
  ) {
    final values = products
        .map(selector)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return values;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final products = snapshot.data ?? const <Product>[];
            final visibleProducts = _applyFilters(products);
            final visibleProductCount = visibleProducts.length;

            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: _SearchHeader(
                    controller: _controller,
                    onChanged: (_) =>
                        setState(() => _useInitialServiceFilter = false),
                    onBackTap: _returnToWorkshop,
                    onWorkshopTap: _returnToWorkshop,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _FilterChips(
                    sortOption: _sortOption,
                    selectedBrand: _selectedBrand,
                    selectedCategory: _selectedCategory,
                    selectedType: _selectedType,
                    onlyAvailable: _onlyAvailable,
                    brands: _filterValues(
                      products,
                      (product) => product.brandName,
                    ),
                    categories: _filterValues(
                      products,
                      (product) => product.categoryName,
                    ),
                    types: _filterValues(
                      products,
                      (product) => product.itemType,
                    ),
                    onSortChanged: (value) {
                      setState(() => _sortOption = value);
                    },
                    onBrandChanged: (value) {
                      setState(() => _selectedBrand = value);
                    },
                    onCategoryChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                    onTypeChanged: (value) {
                      setState(() => _selectedType = value);
                    },
                    onAvailabilityChanged: (value) {
                      setState(() => _onlyAvailable = value);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.workshopSearchProductsResultsCount(
                        visibleProductCount,
                      ),
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (visibleProductCount == 0)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyProductsMessage(),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      0,
                      22,
                      56 + MediaQuery.paddingOf(context).bottom,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 34,
                            crossAxisSpacing: 18,
                            mainAxisExtent: 320,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _SearchProductTile(
                          product: visibleProducts[index],
                        );
                      }, childCount: visibleProductCount),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _returnToWorkshop() {
    context.popOrGo('/workshops/${widget.workshopId}');
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.onChanged,
    required this.onBackTap,
    required this.onWorkshopTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackTap;
  final VoidCallback onWorkshopTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: onBackTap,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.workshopSearchProductsClearTooltip,
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(Icons.cancel_rounded),
                      ),
                filled: true,
                fillColor: AutolabCustomer.customerSurfaceColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                hintText: l10n.workshopSearchProductsHint,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              style: AutolabCustomer.bodyLarge.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AutolabCustomer.customerSurfaceColor(context),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: l10n.workshopSearchProductsViewWorkshopTooltip,
              onPressed: onWorkshopTap,
              icon: const Icon(Icons.storefront_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.sortOption,
    required this.selectedBrand,
    required this.selectedCategory,
    required this.selectedType,
    required this.onlyAvailable,
    required this.brands,
    required this.categories,
    required this.types,
    required this.onSortChanged,
    required this.onBrandChanged,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onAvailabilityChanged,
  });

  final _ProductSortOption sortOption;
  final String? selectedBrand;
  final String? selectedCategory;
  final String? selectedType;
  final bool onlyAvailable;
  final List<String> brands;
  final List<String> categories;
  final List<String> types;
  final ValueChanged<_ProductSortOption> onSortChanged;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<bool> onAvailabilityChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        children: [
          _MenuChip<_ProductSortOption>(
            label: l10n.workshopSearchProductsSortLabel,
            value: sortOption,
            options: {
              _ProductSortOption.relevance:
                  l10n.workshopSearchProductsSortRelevance,
              _ProductSortOption.lowestPrice:
                  l10n.workshopSearchProductsSortLowestPrice,
              _ProductSortOption.highestPrice:
                  l10n.workshopSearchProductsSortHighestPrice,
              _ProductSortOption.name: l10n.workshopSearchProductsSortName,
            },
            onSelected: onSortChanged,
          ),
          const SizedBox(width: 10),
          _MenuChip<String?>(
            label: selectedBrand ?? l10n.workshopSearchProductsBrandLabel,
            value: selectedBrand,
            options: {
              null: l10n.workshopSearchProductsAllOption,
              for (final brand in brands) brand: brand,
            },
            onSelected: onBrandChanged,
          ),
          const SizedBox(width: 10),
          _MenuChip<String?>(
            label: selectedCategory ?? l10n.workshopSearchProductsCategoryLabel,
            value: selectedCategory,
            options: {
              null: l10n.workshopSearchProductsAllOption,
              for (final category in categories) category: category,
            },
            onSelected: onCategoryChanged,
          ),
          const SizedBox(width: 10),
          _MenuChip<String?>(
            label: selectedType == null
                ? l10n.workshopSearchProductsTypeLabel
                : _formatType(l10n, selectedType!),
            value: selectedType,
            options: {
              null: l10n.workshopSearchProductsAllTypesOption,
              for (final type in types) type: _formatType(l10n, type),
            },
            onSelected: onTypeChanged,
          ),
          const SizedBox(width: 10),
          FilterChip(
            label: Text(l10n.workshopSearchProductsAvailableLabel),
            selected: onlyAvailable,
            onSelected: onAvailabilityChanged,
            backgroundColor: AutolabCustomer.customerSurfaceColor(context),
            selectedColor: AutolabCustomer.successSoftBackground,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            labelStyle: AutolabCustomer.body.copyWith(
              color: onlyAvailable
                  ? AutolabCustomer.successText
                  : AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatType(AppLocalizations l10n, String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'service') {
      return l10n.workshopSearchProductsServiceType;
    }

    if (normalized == 'product') {
      return l10n.workshopSearchProductsProductType;
    }

    if (normalized == 'part') {
      return l10n.workshopSearchProductsPartType;
    }

    if (normalized == 'supply') {
      return l10n.workshopSearchProductsSupplyType;
    }

    if (normalized.isEmpty) {
      return l10n.workshopSearchProductsEmptyType;
    }

    return normalized[0].toUpperCase() + normalized.substring(1);
  }
}

class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) {
        return options.entries.map((entry) {
          return PopupMenuItem<T>(value: entry.key, child: Text(entry.value));
        }).toList();
      },
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
        backgroundColor: AutolabCustomer.customerSurfaceColor(context),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: AutolabCustomer.body.copyWith(
          color: AutolabCustomer.customerTextColor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SearchProductTile extends StatelessWidget {
  const _SearchProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final hasStock = (product.currentStock ?? 0) > 0;
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        context.push(
          '/workshops/${product.workshopId}/products/${product.id}',
          extra: product,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProductImage(
                imageUrl: product.primaryImageUrl,
                height: 152,
                borderRadius: BorderRadius.circular(14),
                placeholderIconSize: 44,
              ),
              Positioned(
                right: -2,
                bottom: -14,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AutolabCustomer.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AutolabCustomer.shadowBlackStrong,
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, size: 31),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ProductPriceText(
            price: product.sellingPrice,
            style: AutolabCustomer.h3.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            product.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AutolabCustomer.bodyLarge.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          if (hasStock)
            _StockBadge(label: l10n.workshopSearchProductsStockAvailable)
          else if (product.requiresAppointment)
            _StockBadge(label: l10n.workshopSearchProductsRequiresAppointment),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.successSoftBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AutolabCustomer.caption.copyWith(
            color: AutolabCustomer.successText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmptyProductsMessage extends StatelessWidget {
  const _EmptyProductsMessage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          l10n.workshopSearchProductsEmpty,
          textAlign: TextAlign.center,
          style: AutolabCustomer.body.copyWith(
            color: AutolabCustomer.customerSecondaryTextColor(context),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
