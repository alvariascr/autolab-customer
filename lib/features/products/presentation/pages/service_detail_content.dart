import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/router/build_context_navigation.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_additional_products_by_workshop.dart';
import '../widgets/product_image.dart';
import '../widgets/product_price_text.dart';

class ServiceDetailContent extends StatefulWidget {
  const ServiceDetailContent({super.key, required this.service});

  final Product service;

  @override
  State<ServiceDetailContent> createState() => _ServiceDetailContentState();
}

class _ServiceDetailContentState extends State<ServiceDetailContent> {
  Future<List<Product>>? _relatedProductsFuture;
  final Map<String, int> _selectedQuantities = {};
  bool _includeProducts = false;
  bool _isFavorite = false;

  Future<List<Product>> _loadRelatedProducts() async {
    final result = await sl<GetAdditionalProductsByWorkshop>()(
      widget.service.workshopId,
    );

    return result.fold(
      (failure) => throw StateError(failure.toString()),
      (products) => products,
    );
  }

  void _ensureRelatedProductsLoaded() {
    _relatedProductsFuture ??= _loadRelatedProducts();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final l10n = AppLocalizations.of(context)!;
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);
    final maxWidth = AutolabCustomer.isTabletWidth(context) ? 720.0 : 560.0;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ServiceHero(
              service: service,
              isFavorite: _isFavorite,
              onFavoriteTap: () {
                setState(() => _isFavorite = !_isFavorite);
              },
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
                        service.name,
                        textAlign: TextAlign.center,
                        style: AutolabCustomer.h3.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      Text(
                        service.workshopName.trim().isEmpty
                            ? l10n.serviceDetailWorkshopFallback
                            : service.workshopName.trim(),
                        textAlign: TextAlign.center,
                        style: AutolabCustomer.caption.copyWith(
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      ProductPriceText(
                        price: service.sellingPrice,
                        style: AutolabCustomer.bodyLarge.copyWith(
                          color: AutolabCustomer.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingSmd),
                      const Divider(),
                      const SizedBox(height: AutolabCustomer.spacingSm),
                      Text(
                        l10n.serviceDetailDescriptionTitle,
                        style: AutolabCustomer.bodyLarge.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingSm),
                      Text(
                        service.description.trim().isEmpty
                            ? l10n.serviceDetailDescriptionFallback
                            : service.description.trim(),
                        textAlign: TextAlign.center,
                        style: AutolabCustomer.caption.copyWith(
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingLg),
                      const Divider(),
                      const SizedBox(height: AutolabCustomer.spacingSm),
                      _AdditionalProductsHeader(
                        value: _includeProducts,
                        onChanged: (value) {
                          setState(() {
                            _includeProducts = value;
                            if (value) {
                              _ensureRelatedProductsLoaded();
                            }
                            if (!value) {
                              _selectedQuantities.clear();
                            }
                          });
                        },
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: _includeProducts
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: AutolabCustomer.spacingSmd,
                                ),
                                child: _RelatedProductsList(
                                  future: _relatedProductsFuture!,
                                  quantities: _selectedQuantities,
                                  onQuantityChanged: _changeQuantity,
                                ),
                              )
                            : const SizedBox.shrink(),
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
                          style: AutolabCustomer.primaryButton,
                          onPressed: () {
                            context.push(
                              '/workshops/${service.workshopId}/appointments/new',
                            );
                          },
                          icon: const Icon(Icons.event_available_outlined),
                          label: Text(
                            l10n.serviceDetailScheduleAction,
                            style: AutolabCustomer.bodyLarge.copyWith(
                              color: AutolabCustomer.white,
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

  void _changeQuantity(Product product, int delta) {
    setState(() {
      final currentQuantity = _selectedQuantities[product.id] ?? 0;
      final nextQuantity = (currentQuantity + delta).clamp(0, 99);

      if (nextQuantity == 0) {
        _selectedQuantities.remove(product.id);
      } else {
        _selectedQuantities[product.id] = nextQuantity;
      }
    });
  }
}

class _ServiceHero extends StatelessWidget {
  const _ServiceHero({
    required this.service,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final Product service;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final heroHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 238,
      regular: 270,
      tablet: 340,
    );
    final avatarSize = AutolabCustomer.responsiveDouble(
      context,
      compact: 76,
      regular: 88,
      tablet: 104,
    );

    return SizedBox(
      height: heroHeight + avatarSize / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ProductImage(
            imageUrl: service.primaryImageUrl,
            height: heroHeight,
            placeholderIconSize: AutolabCustomer.iconLg * 1.5,
          ),
          Positioned(
            left: AutolabCustomer.spacingMd,
            top: MediaQuery.paddingOf(context).top + AutolabCustomer.spacingSm,
            child: _HeroActionButton(
              icon: Icons.arrow_back_rounded,
              onTap: () {
                context.popOrGo(
                  service.workshopId.isEmpty
                      ? '/home-customer'
                      : '/workshops/${service.workshopId}',
                );
              },
            ),
          ),
          Positioned(
            right: AutolabCustomer.spacingMd,
            top: MediaQuery.paddingOf(context).top + AutolabCustomer.spacingSm,
            child: _HeroActionButton(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              foregroundColor: AutolabCustomer.primary,
              onTap: onFavoriteTap,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: heroHeight - avatarSize / 2,
            child: Center(
              child: _WorkshopAvatar(service: service, size: avatarSize),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.onTap,
    this.foregroundColor = AutolabCustomer.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.secondary.withValues(alpha: 0.62),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: foregroundColor,
            size: AutolabCustomer.iconMd,
          ),
        ),
      ),
    );
  }
}

class _WorkshopAvatar extends StatelessWidget {
  const _WorkshopAvatar({required this.service, required this.size});

  final Product service;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = service.workshopAvatarUrl.trim();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerBackgroundColor(context),
        shape: BoxShape.circle,
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: CircleAvatar(
        backgroundColor: AutolabCustomer.customerSurfaceColor(context),
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty
            ? Icon(
                Icons.storefront_rounded,
                color: AutolabCustomer.primary,
                size: size * 0.4,
              )
            : null,
      ),
    );
  }
}

class _AdditionalProductsHeader extends StatelessWidget {
  const _AdditionalProductsHeader({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.serviceDetailAdditionalProductsTitle,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingXs),
              Text(
                l10n.appointmentProductsSwitchLabel,
                style: AutolabCustomer.label.copyWith(
                  color: AutolabCustomer.primary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AutolabCustomer.white,
          activeTrackColor: AutolabCustomer.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RelatedProductsList extends StatelessWidget {
  const _RelatedProductsList({
    required this.future,
    required this.quantities,
    required this.onQuantityChanged,
  });

  final Future<List<Product>> future;
  final Map<String, int> quantities;
  final void Function(Product product, int delta) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<Product>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AutolabCustomer.spacingLg),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _ProductsMessage(
            icon: Icons.error_outline_rounded,
            message: l10n.serviceDetailProductsLoadError,
          );
        }

        final products = snapshot.data ?? const <Product>[];
        if (products.isEmpty) {
          return _ProductsMessage(
            icon: Icons.inventory_2_outlined,
            message: l10n.serviceDetailProductsEmpty,
          );
        }

        return Column(
          children: [
            for (var index = 0; index < products.length; index++) ...[
              _RelatedProductTile(
                product: products[index],
                quantity: quantities[products[index].id] ?? 0,
                onQuantityChanged: (delta) =>
                    onQuantityChanged(products[index], delta),
              ),
              if (index < products.length - 1)
                const SizedBox(height: AutolabCustomer.spacingSm),
            ],
          ],
        );
      },
    );
  }
}

class _RelatedProductTile extends StatelessWidget {
  const _RelatedProductTile({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;

    return Container(
      padding: const EdgeInsets.all(AutolabCustomer.spacingSm),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusInput),
        border: Border.all(
          color: selected
              ? AutolabCustomer.primary
              : AutolabCustomer.customerBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 62,
            child: ProductImage(
              imageUrl: product.primaryImageUrl,
              height: 62,
              borderRadius: BorderRadius.circular(AutolabCustomer.radiusChip),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                Text(
                  product.effectiveDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.label.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                ProductPriceText(
                  price: product.sellingPrice,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutolabCustomer.spacingSm),
          if (!selected)
            IconButton(
              tooltip: AppLocalizations.of(
                context,
              )!.serviceDetailAddProductAction,
              onPressed: () => onQuantityChanged(1),
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: AutolabCustomer.customerSecondaryTextColor(context),
            )
          else
            _QuantityControl(
              quantity: quantity,
              onQuantityChanged: onQuantityChanged,
            ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onQuantityChanged,
  });

  final int quantity;
  final ValueChanged<int> onQuantityChanged;

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
          _QuantityButton(
            icon: Icons.remove_rounded,
            onTap: () => onQuantityChanged(-1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AutolabCustomer.spacingSm,
            ),
            child: Text(
              '$quantity',
              style: AutolabCustomer.label.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add_rounded,
            onTap: () => onQuantityChanged(1),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusModal),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingXs),
        child: Icon(icon, color: AutolabCustomer.primary, size: 14),
      ),
    );
  }
}

class _ProductsMessage extends StatelessWidget {
  const _ProductsMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusInput),
      ),
      child: Row(
        children: [
          Icon(icon, color: AutolabCustomer.primary),
          const SizedBox(width: AutolabCustomer.spacingSm),
          Expanded(
            child: Text(
              message,
              style: AutolabCustomer.caption.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
