import 'package:flutter/material.dart';

import '../../../../core/router/build_context_navigation.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../domain/entities/product.dart';
import '../widgets/product_image.dart';

class ProductDetailHero extends StatelessWidget {
  const ProductDetailHero({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final Product product;
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
            imageUrl: product.primaryImageUrl,
            height: heroHeight,
            placeholderIconSize: AutolabCustomer.iconLg * 1.5,
          ),
          Positioned(
            left: AutolabCustomer.spacingMd,
            top: MediaQuery.paddingOf(context).top + AutolabCustomer.spacingSm,
            child: _HeroActionButton(
              icon: Icons.arrow_back_rounded,
              onTap: () {
                final workshopId = product.workshopId.trim();
                context.popOrGo(
                  workshopId.isEmpty
                      ? '/home-customer'
                      : '/workshops/$workshopId',
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
              child: _WorkshopAvatar(product: product, size: avatarSize),
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
  const _WorkshopAvatar({required this.product, required this.size});

  final Product product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = product.workshopAvatarUrl.trim();

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
