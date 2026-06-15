import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/product.dart';
import '../widgets/product_image.dart';
import '../widgets/product_price_text.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProductHero(
              product: product,
              isFavorite: _isFavorite,
              onFavoriteTap: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF181411),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                _WorkshopLine(product: product),
                const SizedBox(height: 14),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      child: ProductPriceText(
                        price: product.sellingPrice,
                        style: const TextStyle(
                          color: Color(0xFF0E6F3B),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ProductInfoBand(product: product),
                const SizedBox(height: 24),
                _ProductDetailGroup(
                  title: 'Descripcion',
                  child: Text(
                    product.effectiveDescription,
                    style: AppTextStyles.normal.copyWith(
                      color: const Color(0xFF3A332E),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ProductDetailGroup(
                  title: 'Informacion del producto',
                  child: Column(
                    children: [
                      _ProductDetailRow(
                        icon: Icons.category_outlined,
                        label: 'Categoria',
                        value: product.categoryName,
                      ),
                      _ProductDetailRow(
                        icon: Icons.sell_outlined,
                        label: 'Marca',
                        value: product.brandName,
                      ),
                      _ProductDetailRow(
                        icon: Icons.local_shipping_outlined,
                        label: 'Proveedor',
                        value: product.providerName,
                      ),
                      _ProductDetailRow(
                        icon: Icons.event_available_outlined,
                        label: 'Requiere cita',
                        value: product.requiresAppointment ? 'Si' : 'No',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pronto podras solicitar este producto.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Solicitar producto'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF181411),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductHero extends StatelessWidget {
  const _ProductHero({
    required this.product,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final Product product;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ProductImage(
            imageUrl: product.primaryImageUrl,
            height: 286,
            placeholderIconSize: 58,
          ),
          Positioned(
            left: 16,
            top: MediaQuery.paddingOf(context).top + 12,
            child: _HeaderCircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => _returnToPreviousScreen(context),
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.paddingOf(context).top + 12,
            child: Row(
              children: [
                const _HeaderCircleButton(icon: Icons.search_rounded),
                const SizedBox(width: 10),
                _HeaderCircleButton(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  onTap: onFavoriteTap,
                ),
                const SizedBox(width: 10),
                const _HeaderCircleButton(icon: Icons.more_horiz_rounded),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 244,
            child: Center(child: _WorkshopAvatar(product: product)),
          ),
        ],
      ),
    );
  }

  void _returnToPreviousScreen(BuildContext context) {
    final router = GoRouter.of(context);

    if (router.canPop()) {
      context.pop();
      return;
    }

    context.go(
      product.workshopId.isEmpty
          ? '/home-customer'
          : '/workshops/${product.workshopId}',
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xD9181411),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _WorkshopAvatar extends StatelessWidget {
  const _WorkshopAvatar({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = product.workshopAvatarUrl.trim();

    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFF7A2E1B),
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty
            ? const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 42,
              )
            : null,
      ),
    );
  }
}

class _WorkshopLine extends StatelessWidget {
  const _WorkshopLine({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final workshopName = product.workshopName.trim().isNotEmpty
        ? product.workshopName.trim()
        : 'Taller Autolab';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 18,
          color: Color(0xFF6B5F57),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            workshopName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.normal.copyWith(
              color: const Color(0xFF6B5F57),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductInfoBand extends StatelessWidget {
  const _ProductInfoBand({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9E2DC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _ProductMetric(
                title: product.currentStock?.toString() ?? 'N/D',
                subtitle: 'Disponible',
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: _ProductMetric(
                title: _formatItemType(product.itemType),
                subtitle: 'Tipo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatItemType(String value) {
  final normalized = value.trim().toLowerCase();

  if (normalized.isEmpty) {
    return 'N/D';
  }

  if (normalized == 'product') {
    return 'Producto';
  }

  if (normalized == 'part') {
    return 'Repuesto';
  }

  if (normalized == 'supply') {
    return 'Insumo';
  }

  return normalized[0].toUpperCase() + normalized.substring(1);
}

class _ProductMetric extends StatelessWidget {
  const _ProductMetric({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF181411),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B5F57),
                    fontSize: 13,
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

class _ProductDetailGroup extends StatelessWidget {
  const _ProductDetailGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF8),
        border: Border.all(color: const Color(0xFFE9E2DC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF181411),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProductDetailRow extends StatelessWidget {
  const _ProductDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? 'N/D' : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF6B5F57)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B5F57),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF181411),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
