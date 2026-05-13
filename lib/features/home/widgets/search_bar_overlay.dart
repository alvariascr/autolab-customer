import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/current_location.dart';
import '../../../l10n/app_localizations.dart';
import '../../products/domain/entities/product.dart';
import '../../products/domain/repositories/product_repository.dart';
import '../../products/domain/services/workshop_product_search_grouper.dart';
import '../../products/presentation/widgets/product_image.dart';
import '../../products/presentation/widgets/product_price_text.dart';
import '../../workshops/domain/entities/workshop.dart';
import '../../workshops/presentation/widgets/workshop_card.dart';
import '../../workshops/presentation/workshop_empty_state_resolver.dart';
import '../application/recent_searches_store.dart';
import '../application/search_overlay_cubit.dart';
import '../application/search_overlay_state.dart';

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
    this.productRepository,
    this.recentSearchesStore,
  });

  final bool showSearchBar;
  final TextEditingController controller;
  final List<Workshop> workshops;
  final CurrentLocation? currentLocation;
  final bool isLoading;
  final Failure? workshopFailure;
  final VoidCallback onClose;
  final ValueChanged<String>? onQueryChanged;
  final ProductRepository? productRepository;
  final RecentSearchesStore? recentSearchesStore;

  @override
  State<SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends State<SearchBarOverlay> {
  late final SearchOverlayCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SearchOverlayCubit(
      productRepository: widget.productRepository,
      recentSearchesStore: widget.recentSearchesStore,
    );
    widget.controller.addListener(_handleControllerChanged);
    unawaited(
      _cubit.initialize(
        query: widget.controller.text,
        workshops: widget.workshops,
        currentLocation: widget.currentLocation,
        isLoadingWorkshops: widget.isLoading,
        workshopFailure: widget.workshopFailure,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SearchBarOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _handleControllerChanged();
    }

    if (oldWidget.workshops != widget.workshops ||
        oldWidget.currentLocation != widget.currentLocation ||
        oldWidget.isLoading != widget.isLoading ||
        oldWidget.workshopFailure != widget.workshopFailure) {
      _cubit.updateSearchContext(
        workshops: widget.workshops,
        currentLocation: widget.currentLocation,
        isLoadingWorkshops: widget.isLoading,
        workshopFailure: widget.workshopFailure,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _cubit.close();
    super.dispose();
  }

  void _handleControllerChanged() {
    final query = widget.controller.text;

    _cubit.onQueryChanged(query);
    widget.onQueryChanged?.call(query);
  }

  void _selectRecentSearch(String query) {
    widget.controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return BlocProvider<SearchOverlayCubit>.value(
      value: _cubit,
      child: AnimatedPositioned(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        top: widget.showSearchBar ? 0 : screenHeight,
        left: 0,
        right: 0,
        bottom: widget.showSearchBar ? 0 : -screenHeight,
        child: IgnorePointer(
          ignoring: !widget.showSearchBar,
          child: TickerMode(
            enabled: widget.showSearchBar,
            child: widget.showSearchBar
                ? _SearchOverlayContent(
                    controller: widget.controller,
                    autofocus: widget.showSearchBar,
                    onBack: () {
                      FocusScope.of(context).unfocus();
                      unawaited(_cubit.commitSearch(widget.controller.text));
                      widget.controller.clear();
                      widget.onClose();
                    },
                    onClear: () {
                      unawaited(_cubit.commitSearch(widget.controller.text));
                      widget.controller.clear();
                    },
                    onRecentSearchSelected: _selectRecentSearch,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _SearchOverlayContent extends StatelessWidget {
  const _SearchOverlayContent({
    required this.controller,
    required this.autofocus,
    required this.onBack,
    required this.onClear,
    required this.onRecentSearchSelected,
  });

  final TextEditingController controller;
  final bool autofocus;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final ValueChanged<String> onRecentSearchSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE9EEF2),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: _SearchOverlayField(
                controller: controller,
                autofocus: autofocus,
                onSubmitted: context.read<SearchOverlayCubit>().commitSearch,
                onBack: onBack,
                onClear: onClear,
              ),
            ),
            Expanded(
              child: BlocBuilder<SearchOverlayCubit, SearchOverlayState>(
                builder: (context, state) {
                  if (!state.hasQuery) {
                    return _RecentSearches(
                      recentSearches: state.recentSearches,
                      onSelected: onRecentSearchSelected,
                    );
                  }

                  return _WorkshopSearchResults(
                    workshops: state.workshopResults,
                    productResults: state.productResults,
                    query: state.query,
                    currentLocation: state.currentLocation,
                    isLoading: state.isLoading,
                    failure: state.workshopFailure,
                    onSearchCommitted: context
                        .read<SearchOverlayCubit>()
                        .commitSearch,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchOverlayField extends StatelessWidget {
  const _SearchOverlayField({
    required this.controller,
    required this.autofocus,
    required this.onSubmitted,
    required this.onBack,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          elevation: 8,
          shadowColor: const Color(0x24000000),
          child: SizedBox(
            height: 52,
            child: TextField(
              key: const ValueKey('workshop-search-overlay-field'),
              controller: controller,
              autofocus: autofocus,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: l10n.searchBarHint,
                hintStyle: const TextStyle(
                  color: Color(0xFF6D757C),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                prefixIcon: IconButton(
                  key: const ValueKey('workshop-search-close-button'),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF5F676D),
                  ),
                ),
                suffixIcon: value.text.trim().isEmpty
                    ? const Icon(Icons.search_rounded, color: Color(0xFF5F676D))
                    : IconButton(
                        key: const ValueKey('workshop-search-clear-button'),
                        tooltip: l10n.workshopSearchClearTooltip,
                        onPressed: onClear,
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: Color(0xFF9AA1A8),
                        ),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        );
      },
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
    required this.onSelected,
  });

  final List<String> recentSearches;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (recentSearches.isEmpty) {
      return _SearchEmptyMessage(message: l10n.workshopSearchStartMessage);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          l10n.workshopSearchRecentTitle,
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
          children: recentSearches.map((query) {
            return ActionChip(
              key: ValueKey('recent-search-$query'),
              avatar: const Icon(Icons.history_rounded, size: 17),
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
