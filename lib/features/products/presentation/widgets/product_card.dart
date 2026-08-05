import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../workshops/presentation/widgets/workshop_avatar.dart';
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
      color: AutolabCustomer.customerElevatedSurfaceColor(context),
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
                  child: WorkshopAvatar(
                    imageUrl: product.workshopAvatarUrl,
                    outerRadius: 18,
                    innerRadius: 14,
                    outerColor: AutolabCustomer.customerElevatedSurfaceColor(
                      context,
                    ),
                    innerColor: AutolabCustomer.customerSoftSurfaceColor(
                      context,
                    ),
                    fallbackIconSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            ProductPriceText(
              price: product.sellingPrice,
              style: AutolabCustomer.caption.copyWith(
                color: AutolabCustomer.customerTextColor(context),
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
                  color: AutolabCustomer.customerSecondaryTextColor(context),
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
                  color: AutolabCustomer.customerInvertedSurfaceColor(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AutolabCustomer.customerOnInvertedSurfaceColor(
                    context,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
