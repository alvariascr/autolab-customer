import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../domain/entities/product.dart';
import 'product_image.dart';
import 'product_price_text.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ProductImage(
                  imageUrl: product.primaryImageUrl,
                  height: 130,
                  borderRadius: BorderRadius.circular(16),
                ),
                Positioned(
                  right: 8,
                  bottom: -18,
                  child: _WorkshopAvatar(product: product),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AutolabCustomer.body.copyWith(
                color: const Color(0xFF181411),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            ProductPriceText(
              price: product.sellingPrice,
              style: AutolabCustomer.caption.copyWith(
                color: const Color(0xFF181411),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                product.effectiveDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AutolabCustomer.caption.copyWith(
                  color: const Color(0xFF6B5F57),
                  fontSize: 12,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF181411),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ],
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
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: const Color(0xFFE9DDD2),
        backgroundImage: product.workshopAvatarUrl.trim().isNotEmpty
            ? NetworkImage(product.workshopAvatarUrl)
            : null,
        child: product.workshopAvatarUrl.trim().isEmpty
            ? const Icon(Icons.storefront_outlined, size: 15)
            : null,
      ),
    );
  }
}
