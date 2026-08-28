import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/application/cart_cubit.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/favorite_inventory_items_repository.dart';
import '../widgets/product_price_text.dart';
import 'product_detail_hero.dart';

class PhysicalProductDetailContent extends StatefulWidget {
  const PhysicalProductDetailContent({
    super.key,
    required this.product,
    required this.favoriteRepository,
  });

  final Product product;
  final FavoriteInventoryItemsRepository favoriteRepository;

  @override
  State<PhysicalProductDetailContent> createState() =>
      _PhysicalProductDetailContentState();
}

class _PhysicalProductDetailContentState
    extends State<PhysicalProductDetailContent> {
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;
  int _quantity = 1;

  int get _availableStock => widget.product.currentStock?.clamp(0, 9999) ?? 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFavoriteStatus());
  }

  @override
  void didUpdateWidget(covariant PhysicalProductDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      unawaited(_loadFavoriteStatus());
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFavorite = await widget.favoriteRepository
          .isFavoriteInventoryItem(widget.product.id);
      if (!mounted) return;
      setState(() => _isFavorite = isFavorite);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final previousValue = _isFavorite;

    setState(() {
      _isFavorite = !previousValue;
      _isFavoriteLoading = true;
    });

    try {
      final nextValue = await widget.favoriteRepository
          .toggleFavoriteInventoryItem(
            widget.product.id,
            itemType: widget.product.itemType,
          );
      if (!mounted) return;
      setState(() {
        _isFavorite = nextValue;
        _isFavoriteLoading = false;
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              nextValue
                  ? l10n.productFavoriteAdded
                  : l10n.productFavoriteRemoved,
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFavorite = previousValue;
        _isFavoriteLoading = false;
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.inventoryFavoriteError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final l10n = AppLocalizations.of(context)!;
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);
    final maxWidth = AutolabCustomer.isTabletWidth(context) ? 720.0 : 560.0;
    final hasStock = _availableStock > 0;
    final productTypeLabel = _localizedItemTypeLabel(product.itemType, l10n);

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ProductDetailHero(
              product: product,
              isFavorite: _isFavorite,
              onFavoriteTap: () => unawaited(_toggleFavorite()),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalMargin,
              0,
              horizontalMargin,
              AutolabCustomer.spacingLg,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      Text(
                        product.name,
                        textAlign: TextAlign.center,
                        style: AutolabCustomer.h3.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      Text(
                        product.workshopName.trim().isEmpty
                            ? l10n.serviceDetailWorkshopFallback
                            : product.workshopName.trim(),
                        textAlign: TextAlign.center,
                        style: AutolabCustomer.caption.copyWith(
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      ProductPriceText(
                        price: product.sellingPrice,
                        style: AutolabCustomer.bodyLarge.copyWith(
                          color: AutolabCustomer.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingMd),
                      _PurchaseSummary(
                        availableStock: _availableStock,
                        typeLabel: productTypeLabel,
                      ),
                      const SizedBox(height: AutolabCustomer.spacingLg),
                      _ProductInfoCard(product: product),
                      const SizedBox(height: AutolabCustomer.spacingLg),
                      _QuantityCard(
                        quantity: hasStock ? _quantity : 0,
                        onDecrease: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        onIncrease: _quantity < _availableStock
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                      const SizedBox(height: AutolabCustomer.spacingLg),
                      SizedBox(
                        width: double.infinity,
                        height: AutolabCustomer.responsiveDouble(
                          context,
                          compact: 50,
                          regular: 54,
                          tablet: 58,
                        ),
                        child: ElevatedButton.icon(
                          style: AutolabCustomer.primaryButton.copyWith(
                            backgroundColor: const WidgetStatePropertyAll(
                              AutolabCustomer.primary,
                            ),
                            foregroundColor: const WidgetStatePropertyAll(
                              AutolabCustomer.white,
                            ),
                          ),
                          onPressed: hasStock
                              ? () async {
                                  final addStatus = await context
                                      .read<CartCubit>()
                                      .addProductAndPersist(
                                        product,
                                        quantity: _quantity,
                                      );
                                  if (!context.mounted) return;

                                  if (!addStatus.wasAdded) {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    messenger
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _cartAddStatusMessage(
                                              addStatus,
                                              l10n,
                                            ),
                                          ),
                                        ),
                                      );
                                    return;
                                  }

                                  context.go('/home-customer?tab=cart');
                                }
                              : null,
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: Text(
                            l10n.productDetailBuyAction,
                            style: AutolabCustomer.bodyLarge.copyWith(
                              color: AutolabCustomer.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingSm),
                      SizedBox(
                        width: double.infinity,
                        height: AutolabCustomer.responsiveDouble(
                          context,
                          compact: 46,
                          regular: 50,
                          tablet: 54,
                        ),
                        child: OutlinedButton.icon(
                          style: AutolabCustomer.secondaryButton.copyWith(
                            foregroundColor: WidgetStatePropertyAll(
                              AutolabCustomer.customerTextColor(context),
                            ),
                          ),
                          onPressed: hasStock
                              ? () async {
                                  final router = GoRouter.of(context);
                                  final addStatus = await context
                                      .read<CartCubit>()
                                      .addProductAndPersist(
                                        product,
                                        quantity: _quantity,
                                      );
                                  if (!context.mounted) return;

                                  if (!addStatus.wasAdded) {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    messenger
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _cartAddStatusMessage(
                                              addStatus,
                                              l10n,
                                            ),
                                          ),
                                        ),
                                      );
                                    return;
                                  }

                                  final workshopId = product.workshopId.trim();
                                  router.go(
                                    workshopId.isEmpty
                                        ? '/home-customer'
                                        : '/workshops/$workshopId?section=products&cartAdded=true',
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: Text(
                            l10n.productDetailAddToCartAction,
                            style: AutolabCustomer.body.copyWith(
                              color: AutolabCustomer.customerTextColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _localizedItemTypeLabel(String itemType, AppLocalizations l10n) {
    switch (itemType.trim().toLowerCase()) {
      case 'product':
        return l10n.productDetailTypeFallback;
      case 'service':
        return l10n.mapFilterService;
      default:
        return l10n.productDetailTypeFallback;
    }
  }

  String _cartAddStatusMessage(
    CartAddProductStatus status,
    AppLocalizations l10n,
  ) {
    return switch (status) {
      CartAddProductStatus.stockLimitReached =>
        l10n.productDetailStockLimitReached,
      CartAddProductStatus.invalidProduct =>
        l10n.productDetailCartInvalidProduct,
      CartAddProductStatus.added => l10n.productDetailAddedToCartMessage,
    };
  }
}

class _PurchaseSummary extends StatelessWidget {
  const _PurchaseSummary({
    required this.availableStock,
    required this.typeLabel,
  });

  final int availableStock;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: AutolabCustomer.primary,
                  size: AutolabCustomer.iconMd,
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                Text(
                  '$availableStock',
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.bodyLarge.copyWith(
                    color: availableStock > 0
                        ? AutolabCustomer.customerTextColor(context)
                        : AutolabCustomer.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                Text(
                  l10n.productDetailAvailableLabel,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 72,
            color: AutolabCustomer.customerDividerColor(context),
          ),
          Expanded(
            child: Column(
              children: [
                const Icon(
                  Icons.category_outlined,
                  color: AutolabCustomer.primary,
                  size: AutolabCustomer.iconMd,
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                Text(
                  typeLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.bodyLarge.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                Text(
                  l10n.productDetailTypeLabel,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityCard extends StatelessWidget {
  const _QuantityCard({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.productDetailQuantityLabel,
              style: AutolabCustomer.bodyLarge.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantitySelector(
            quantity: quantity,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AutolabCustomer.primary),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusModal),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(icon: Icons.remove_rounded, onTap: onDecrease),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AutolabCustomer.spacingSmd,
            ),
            child: Text(
              '$quantity',
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityButton(icon: Icons.add_rounded, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusModal),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingSm),
        child: Icon(
          icon,
          color: enabled
              ? AutolabCustomer.primary
              : AutolabCustomer.customerDisabledTextColor(context),
          size: AutolabCustomer.iconXs,
        ),
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = product.categoryName.trim();
    final brand = product.brandName.trim();
    final description = product.description.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AutolabCustomer.primary,
                size: AutolabCustomer.iconSm,
              ),
              const SizedBox(width: AutolabCustomer.spacingSm),
              Text(
                l10n.productDetailInfoTitle,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AutolabCustomer.spacingMd),
          _InfoRow(
            icon: Icons.category_outlined,
            label: l10n.productDetailCategoryLabel,
            value: category.isEmpty ? l10n.productDetailNotAvailable : category,
          ),
          Divider(
            height: AutolabCustomer.spacingLg,
            color: AutolabCustomer.customerDividerColor(context),
          ),
          _InfoRow(
            icon: Icons.sell_outlined,
            label: l10n.productDetailBrandLabel,
            value: brand.isEmpty ? l10n.productDetailNotAvailable : brand,
          ),
          Divider(
            height: AutolabCustomer.spacingLg,
            color: AutolabCustomer.customerDividerColor(context),
          ),
          _InfoRow(
            icon: Icons.description_outlined,
            label: l10n.serviceDetailDescriptionTitle,
            value: description.isEmpty
                ? l10n.productDetailDescriptionFallback
                : description,
            allowWrap: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.allowWrap = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: allowWrap
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AutolabCustomer.primary,
          size: AutolabCustomer.iconXs,
        ),
        const SizedBox(width: AutolabCustomer.spacingSm),
        Expanded(
          child: Text(
            label,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: AutolabCustomer.spacingSm),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: allowWrap ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
