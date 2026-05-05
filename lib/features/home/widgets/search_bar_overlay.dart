import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_injection.dart';
import '../../../core/location/current_location.dart';
import '../../../l10n/app_localizations.dart';
import '../../products/domain/entities/product.dart';
import '../../products/domain/repositories/product_repository.dart';
import '../../products/domain/services/product_search_filter.dart';
import '../../products/domain/services/workshop_product_search_grouper.dart';
import '../../products/presentation/widgets/product_image.dart';
import '../../products/presentation/widgets/product_price_text.dart';
import '../../workshops/domain/entities/workshop.dart';
import '../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../workshops/domain/services/workshop_text_search_filter.dart';
import '../../workshops/presentation/widgets/workshop_card.dart';
import '../../workshops/presentation/workshop_empty_state_resolver.dart';

class SearchBarOverlay extends StatefulWidget {
  const SearchBarOverlay({
    super.key,
    required this.showSearchBar,
    required this.controller,
    required this.workshops,
    required this.currentLocation,
    required this.isLoading,
    required this.workshopFailure,
    required this.onClose,
    this.onQueryChanged,
  });

  static const _textSearchFilter = WorkshopTextSearchFilter();
  static const _proximityFilter = WorkshopProximityFilter();
  static const _productSearchFilter = ProductSearchFilter();
  static const _productSearchGrouper = WorkshopProductSearchGrouper();

  final bool showSearchBar;
  final TextEditingController controller;
  final List<Workshop> workshops;
  final CurrentLocation? currentLocation;
  final bool isLoading;
  final Failure? workshopFailure;
  final VoidCallback onClose;
  final ValueChanged<String>? onQueryChanged;

  @override
  State<SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends State<SearchBarOverlay> {
  static const _maxRecentSearches = 6;
  static const _suggestedSearches = <String>[
    'Talleres',
    'Frenos',
    'Suspensión',
    'Escazú',
  ];

  final List<String> _recentSearches = <String>[];
  late final bool _hasProductRepository;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _hasProductRepository = sl.isRegistered<ProductRepository>();
    _productsFuture = _hasProductRepository
        ? _loadProducts()
        : Future.value(const <Product>[]);
  }

  Future<List<Product>> _loadProducts() async {
    final result = await sl<ProductRepository>().getActiveProducts();

    return result.fold((_) => const <Product>[], (products) => products);
  }

  void _saveRecentSearch(String value) {
    final query = value.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() {
      _recentSearches.removeWhere(
        (item) => item.toLowerCase() == query.toLowerCase(),
      );
      _recentSearches.insert(0, query);

      if (_recentSearches.length > _maxRecentSearches) {
        _recentSearches.removeRange(_maxRecentSearches, _recentSearches.length);
      }
    });
  }

  void _selectRecentSearch(String query) {
    widget.controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    widget.onQueryChanged?.call(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      top: widget.showSearchBar ? 0 : MediaQuery.sizeOf(context).height,
      left: 0,
      right: 0,
      bottom: widget.showSearchBar ? 0 : -MediaQuery.sizeOf(context).height,
      child: IgnorePointer(
        ignoring: !widget.showSearchBar,
        child: Material(
          color: const Color(0xFFF8F4EF),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('workshop-search-close-button'),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          _saveRecentSearch(widget.controller.text);
                          widget.controller.clear();
                          widget.onQueryChanged?.call('');
                          widget.onClose();
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: widget.controller,
                          builder: (context, value, child) {
                            return TextField(
                              key: const ValueKey(
                                'workshop-search-overlay-field',
                              ),
                              controller: widget.controller,
                              autofocus: widget.showSearchBar,
                              textInputAction: TextInputAction.search,
                              onChanged: widget.onQueryChanged,
                              onSubmitted: _saveRecentSearch,
                              decoration: InputDecoration(
                                hintText: l10n.searchBarHint,
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: value.text.isEmpty
                                    ? null
                                    : IconButton(
                                        key: const ValueKey(
                                          'workshop-search-clear-button',
                                        ),
                                        tooltip:
                                            l10n.workshopSearchClearTooltip,
                                        onPressed: () {
                                          _saveRecentSearch(value.text);
                                          widget.controller.clear();
                                          widget.onQueryChanged?.call('');
                                        },
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l10n.workshopSearchTitle,
                    style: const TextStyle(
                      color: Color(0xFF181411),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, child) {
                      final query = value.text.trim();

                      if (query.isEmpty) {
                        return _RecentSearches(
                          recentSearches: _recentSearches,
                          suggestedSearches: _suggestedSearches,
                          onSelected: _selectRecentSearch,
                        );
                      }

                      final searchableWorkshops = widget.currentLocation == null
                          ? widget.workshops
                          : SearchBarOverlay._proximityFilter.filterNearby(
                              workshops: widget.workshops,
                              currentLocation: widget.currentLocation,
                            );
                      final workshopResults = SearchBarOverlay._textSearchFilter
                          .filter(workshops: searchableWorkshops, query: query);

                      if (!_hasProductRepository) {
                        return _WorkshopSearchResults(
                          workshops: workshopResults,
                          productResults: const [],
                          query: query,
                          currentLocation: widget.currentLocation,
                          isLoading: widget.isLoading,
                          failure: widget.workshopFailure,
                          onSearchCommitted: _saveRecentSearch,
                        );
                      }

                      return FutureBuilder<List<Product>>(
                        future: _productsFuture,
                        builder: (context, snapshot) {
                          final products = snapshot.data ?? const <Product>[];
                          final matchingProducts = SearchBarOverlay
                              ._productSearchFilter
                              .filter(products: products, query: query);
                          final productResults = SearchBarOverlay
                              ._productSearchGrouper
                              .group(
                                products: matchingProducts,
                                workshops: searchableWorkshops,
                              );

                          return _WorkshopSearchResults(
                            workshops: workshopResults,
                            productResults: productResults,
                            query: query,
                            currentLocation: widget.currentLocation,
                            isLoading:
                                widget.isLoading ||
                                snapshot.connectionState ==
                                    ConnectionState.waiting,
                            failure: widget.workshopFailure,
                            onSearchCommitted: _saveRecentSearch,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkshopSearchResults extends StatelessWidget {
  const _WorkshopSearchResults({
    required this.workshops,
    required this.productResults,
    required this.query,
    required this.currentLocation,
    required this.isLoading,
    required this.failure,
    required this.onSearchCommitted,
  });

  final List<Workshop> workshops;
  final List<WorkshopProductSearchResult> productResults;
  final String query;
  final CurrentLocation? currentLocation;
  final bool isLoading;
  final Failure? failure;
  final ValueChanged<String> onSearchCommitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (failure != null) {
      return _SearchEmptyMessage(
        message: _SearchBarOverlayFailureResolver.resolve(failure!, l10n),
      );
    }

    if (productResults.isEmpty && workshops.isEmpty) {
      return _SearchEmptyMessage(
        message: query.isEmpty
            ? l10n.workshopSearchStartMessage
            : l10n.workshopSearchNoResults,
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      itemCount: productResults.length + workshops.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index < productResults.length) {
          final result = productResults[index];

          return _WorkshopProductResultCard(
            result: result,
            query: query,
            referenceLocation: currentLocation,
            onSearchCommitted: onSearchCommitted,
          );
        }

        final workshopIndex = index - productResults.length;
        final workshop = workshops[workshopIndex];

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            onSearchCommitted(query);
            _showWorkshopDetails(context, workshop);
          },
          child: WorkshopCard(
            workshop: workshop,
            referenceLocation: currentLocation,
            compact: true,
          ),
        );
      },
    );
  }

  void _showWorkshopDetails(BuildContext context, Workshop workshop) {
    context.push('/workshops/${workshop.id}');
  }
}

class _WorkshopProductResultCard extends StatelessWidget {
  const _WorkshopProductResultCard({
    required this.result,
    required this.query,
    required this.referenceLocation,
    required this.onSearchCommitted,
  });

  final WorkshopProductSearchResult result;
  final String query;
  final CurrentLocation? referenceLocation;
  final ValueChanged<String> onSearchCommitted;

  @override
  Widget build(BuildContext context) {
    final workshop = result.workshop;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          onSearchCommitted(query);
          context.push(
            '/search/workshops/${workshop.id}/products?query=${Uri.encodeComponent(query)}',
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFF8F4EF),
                    backgroundImage: workshop.avatarUrl.trim().isNotEmpty
                        ? NetworkImage(workshop.avatarUrl)
                        : null,
                    child: workshop.avatarUrl.trim().isEmpty
                        ? const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFF9B3D24),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workshop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF181411),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _WorkshopResultMeta(workshop: workshop),
                        const SizedBox(height: 6),
                        Text(
                          '${result.count} resultado${result.count == 1 ? '' : 's'} para "$query"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B5F57),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 206,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: result.products.take(8).length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = result.products[index];

                    return _SearchProductPreview(product: product);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkshopResultMeta extends StatelessWidget {
  const _WorkshopResultMeta({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final locationLabel = workshop.locationAddress.trim();
    final deliveryLabel = workshop.offersHomeService
        ? 'A domicilio'
        : 'En taller';

    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 16,
          color: Color(0xFF9B3D24),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            locationLabel.isEmpty
                ? deliveryLabel
                : '$locationLabel - $deliveryLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B5F57),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchProductPreview extends StatelessWidget {
  const _SearchProductPreview({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProductImage(
                imageUrl: product.primaryImageUrl,
                height: 112,
                borderRadius: BorderRadius.circular(14),
              ),
              Positioned(
                right: 6,
                bottom: -12,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF181411),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ProductPriceText(
            price: product.sellingPrice,
            style: const TextStyle(
              color: Color(0xFF181411),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3A332E),
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.recentSearches,
    required this.suggestedSearches,
    required this.onSelected,
  });

  final List<String> recentSearches;
  final List<String> suggestedSearches;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final hasRecentSearches = recentSearches.isNotEmpty;
    final chips = hasRecentSearches ? recentSearches : suggestedSearches;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          hasRecentSearches
              ? l10n.workshopSearchRecentTitle
              : l10n.workshopSearchSuggestedTitle,
          style: const TextStyle(
            color: Color(0xFF181411),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.map((query) {
            return ActionChip(
              key: ValueKey(
                hasRecentSearches
                    ? 'recent-search-$query'
                    : 'suggested-search-$query',
              ),
              avatar: Icon(
                hasRecentSearches
                    ? Icons.history_rounded
                    : Icons.search_rounded,
                size: 17,
              ),
              label: Text(query),
              onPressed: () => onSelected(query),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE9DDD2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF181411),
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SearchEmptyMessage extends StatelessWidget {
  const _SearchEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B5F57),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _SearchBarOverlayFailureResolver {
  const _SearchBarOverlayFailureResolver._();

  static const _resolver = WorkshopEmptyStateResolver();

  static String resolve(Failure failure, AppLocalizations l10n) {
    return _resolver.resolveLoadError(failure, l10n);
  }
}
