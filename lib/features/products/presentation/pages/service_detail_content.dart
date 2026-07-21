import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/router/build_context_navigation.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../workshops/application/appointment_state.dart';
import '../../../workshops/presentation/pages/workshop_appointment_page.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_additional_products_by_workshop.dart';
import '../widgets/product_image.dart';
import '../widgets/product_price_text.dart';
import 'product_detail_hero.dart';

class ServiceDetailContent extends StatefulWidget {
  const ServiceDetailContent({super.key, required this.service});

  final Product service;

  @override
  State<ServiceDetailContent> createState() => _ServiceDetailContentState();
}

class _ServiceDetailContentState extends State<ServiceDetailContent> {
  Future<List<Product>>? _relatedProductsFuture;
  List<Product>? _loadedRelatedProducts;
  Object? _relatedProductsError;
  final Map<String, int> _selectedQuantities = {};
  bool _includeProducts = false;
  bool _showProductsStep = false;
  bool _isFavorite = false;

  Future<List<Product>> _loadRelatedProducts() async {
    final result = await sl<GetAdditionalProductsByWorkshop>()(
      widget.service.workshopId,
    );

    final products = result.fold(
      (failure) => throw StateError(failure.toString()),
      (products) => products,
    );
    return products;
  }

  void _ensureRelatedProductsLoaded() {
    if (_loadedRelatedProducts != null || _relatedProductsFuture != null) {
      return;
    }

    setState(() {
      _relatedProductsError = null;
      _relatedProductsFuture = _loadRelatedProducts();
    });

    _relatedProductsFuture!.then<void>(
      (products) {
        if (!mounted) {
          return;
        }

        setState(() {
          _loadedRelatedProducts = products;
          _relatedProductsFuture = null;
        });
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _relatedProductsError = error;
          _relatedProductsFuture = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final l10n = AppLocalizations.of(context)!;
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);
    final maxWidth = AutolabCustomer.isTabletWidth(context) ? 720.0 : 560.0;
    final workshopId = service.workshopId.trim();
    final safePadding = MediaQuery.paddingOf(context);
    final scheduleButtonHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 50,
      regular: 54,
      tablet: 58,
    );

    return PopScope(
      canPop: !_showProductsStep,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_showProductsStep) {
          return;
        }

        _returnToServiceSummary();
      },
      child: Scaffold(
        backgroundColor: AutolabCustomer.customerBackgroundColor(context),
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                if (!_showProductsStep)
                  SliverToBoxAdapter(
                    child: ProductDetailHero(
                      product: service,
                      isFavorite: _isFavorite,
                      onFavoriteTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                      },
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalMargin,
                    _showProductsStep
                        ? safePadding.top + AutolabCustomer.spacingLg
                        : 0,
                    horizontalMargin,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: _ServiceDetailSummary(
                          service: service,
                          showProductsStep: _showProductsStep,
                          l10n: l10n,
                          onProductsBack: _returnToServiceSummary,
                        ),
                      ),
                    ),
                  ),
                ),
                ..._relatedProductSlivers(context, horizontalMargin, maxWidth),
                if (!_showProductsStep)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalMargin,
                      AutolabCustomer.spacingLg,
                      horizontalMargin,
                      AutolabCustomer.spacingLg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: _ServiceStepActions(
                            workshopId: workshopId,
                            onNext: () {
                              setState(() {
                                _showProductsStep = true;
                                _includeProducts = true;
                              });
                              _ensureRelatedProductsLoaded();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_showProductsStep)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          scheduleButtonHeight +
                          safePadding.bottom +
                          AutolabCustomer.spacingXxl,
                    ),
                  ),
              ],
            ),
            if (_showProductsStep)
              Positioned(
                left: horizontalMargin,
                right: horizontalMargin,
                bottom: safePadding.bottom + AutolabCustomer.spacingMd,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: SizedBox(
                      width: double.infinity,
                      height: scheduleButtonHeight,
                      child: ElevatedButton.icon(
                        style: AutolabCustomer.primaryButton,
                        onPressed: workshopId.isEmpty
                            ? null
                            : () => _openAppointmentFlow(
                                context,
                                service,
                                workshopId,
                              ),
                        icon: const Icon(
                          Icons.event_available_outlined,
                          size: AutolabCustomer.iconMd,
                        ),
                        label: Text(
                          l10n.serviceDetailScheduleAction,
                          style: AutolabCustomer.bodyLarge.copyWith(
                            color: AutolabCustomer.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _returnToServiceSummary() {
    setState(() {
      _showProductsStep = false;
    });
  }

  List<Widget> _relatedProductSlivers(
    BuildContext context,
    double horizontalMargin,
    double maxWidth,
  ) {
    if (!_showProductsStep) {
      return const [];
    }

    final l10n = AppLocalizations.of(context)!;

    if (_relatedProductsFuture != null) {
      return [
        _relatedProductsMessageSliver(
          horizontalMargin: horizontalMargin,
          maxWidth: maxWidth,
          child: const Padding(
            padding: EdgeInsets.all(AutolabCustomer.spacingLg),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    if (_relatedProductsError != null) {
      return [
        _relatedProductsMessageSliver(
          horizontalMargin: horizontalMargin,
          maxWidth: maxWidth,
          child: _ProductsMessage(
            icon: Icons.error_outline_rounded,
            message: l10n.serviceDetailProductsLoadError,
          ),
        ),
      ];
    }

    final products = _loadedRelatedProducts ?? const <Product>[];
    if (products.isEmpty) {
      return [
        _relatedProductsMessageSliver(
          horizontalMargin: horizontalMargin,
          maxWidth: maxWidth,
          child: _ProductsMessage(
            icon: Icons.inventory_2_outlined,
            message: l10n.serviceDetailProductsEmpty,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalMargin,
          AutolabCustomer.spacingSmd,
          horizontalMargin,
          0,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final product = products[index];
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index < products.length - 1
                        ? AutolabCustomer.spacingSm
                        : 0,
                  ),
                  child: _RelatedProductTile(
                    product: product,
                    quantity: _selectedQuantities[product.id] ?? 0,
                    onQuantityChanged: (delta) =>
                        _changeQuantity(product, delta),
                  ),
                ),
              ),
            );
          }, childCount: products.length),
        ),
      ),
    ];
  }

  void _openAppointmentFlow(
    BuildContext context,
    Product service,
    String workshopId,
  ) {
    final serviceId = Uri.encodeComponent(service.id.trim());
    context.push(
      '/workshops/$workshopId/appointments/new?serviceId=$serviceId',
      extra: WorkshopAppointmentInitialSelection(
        service: service,
        products: _selectedAppointmentProducts(),
      ),
    );
  }

  Widget _relatedProductsMessageSliver({
    required double horizontalMargin,
    required double maxWidth,
    required Widget child,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalMargin,
        AutolabCustomer.spacingSmd,
        horizontalMargin,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
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

  List<AppointmentSelectedProduct> _selectedAppointmentProducts() {
    if (!_includeProducts || _selectedQuantities.isEmpty) {
      return const [];
    }

    final productsById = {
      for (final product in _loadedRelatedProducts ?? const <Product>[])
        product.id: product,
    };

    return _selectedQuantities.entries
        .where((entry) => entry.value > 0)
        .where((entry) => productsById.containsKey(entry.key))
        .map((entry) {
          return AppointmentSelectedProduct(
            product: productsById[entry.key]!,
            quantity: entry.value,
          );
        })
        .toList(growable: false);
  }
}

class _ServiceDetailSummary extends StatelessWidget {
  const _ServiceDetailSummary({
    required this.service,
    required this.showProductsStep,
    required this.l10n,
    required this.onProductsBack,
  });

  final Product service;
  final bool showProductsStep;
  final AppLocalizations l10n;
  final VoidCallback onProductsBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showProductsStep) ...[
          _ProductsStepBackButton(onPressed: onProductsBack),
          const SizedBox(height: AutolabCustomer.spacingXs),
          const _ProductsStepLogo(),
          const SizedBox(height: AutolabCustomer.spacingSm),
        ],
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
            color: AutolabCustomer.customerSecondaryTextColor(context),
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
        if (!showProductsStep) ...[
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
              color: AutolabCustomer.customerSecondaryTextColor(context),
              height: 1.4,
            ),
          ),
        ] else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.serviceDetailAdditionalProductsTitle,
              style: AutolabCustomer.bodyLarge.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AutolabCustomer.spacingXs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.appointmentProductsSwitchLabel,
              style: AutolabCustomer.label.copyWith(
                color: AutolabCustomer.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductsStepBackButton extends StatelessWidget {
  const _ProductsStepBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: AutolabCustomer.customerSurfaceColor(context),
            foregroundColor: AutolabCustomer.customerTextColor(context),
            shape: const CircleBorder(),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: AutolabCustomer.iconXs,
          ),
        ),
      ),
    );
  }
}

class _ProductsStepLogo extends StatelessWidget {
  const _ProductsStepLogo();

  @override
  Widget build(BuildContext context) {
    return AutolabLogoMark(
      width: AutolabCustomer.responsiveDouble(
        context,
        compact: 76,
        regular: 88,
        tablet: 104,
      ),
      height: AutolabCustomer.responsiveDouble(
        context,
        compact: 30,
        regular: 34,
        tablet: 40,
      ),
    );
  }
}

class _ServiceStepActions extends StatelessWidget {
  const _ServiceStepActions({required this.workshopId, required this.onNext});

  final String workshopId;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AutolabCustomer.responsiveDouble(
              context,
              compact: 46,
              regular: 50,
              tablet: 54,
            ),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AutolabCustomer.customerTextColor(context),
                side: const BorderSide(
                  color: AutolabCustomer.primary,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                ),
              ),
              onPressed: () => context.popOrGo(
                workshopId.isEmpty
                    ? '/home-customer'
                    : '/workshops/$workshopId',
              ),
              child: Text(
                l10n.appointmentBackAction,
                style: AutolabCustomer.body.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AutolabCustomer.spacingSm),
        Expanded(
          child: SizedBox(
            height: AutolabCustomer.responsiveDouble(
              context,
              compact: 46,
              regular: 50,
              tablet: 54,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AutolabCustomer.primary,
                foregroundColor: AutolabCustomer.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                ),
              ),
              onPressed: onNext,
              child: Text(
                l10n.appointmentNextAction,
                style: AutolabCustomer.body.copyWith(
                  color: AutolabCustomer.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
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
    final imageWidth = AutolabCustomer.responsiveDouble(
      context,
      compact: 48,
      regular: 54,
      tablet: 64,
    );
    final imageHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 56,
      regular: 62,
      tablet: 72,
    );
    final horizontalGap = AutolabCustomer.responsiveDouble(
      context,
      compact: AutolabCustomer.spacingSm,
      regular: AutolabCustomer.spacingSmd,
      tablet: AutolabCustomer.spacingMd,
    );

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
            width: imageWidth,
            height: imageHeight,
            child: ProductImage(
              imageUrl: product.primaryImageUrl,
              height: imageHeight,
              borderRadius: BorderRadius.circular(AutolabCustomer.radiusChip),
              placeholderIconSize: AutolabCustomer.iconMd,
            ),
          ),
          SizedBox(width: horizontalGap),
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
          SizedBox(width: AutolabCustomer.spacingXs),
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
        child: Icon(
          icon,
          color: AutolabCustomer.primary,
          size: AutolabCustomer.responsiveDouble(
            context,
            compact: 13,
            regular: 14,
            tablet: 16,
          ),
        ),
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
