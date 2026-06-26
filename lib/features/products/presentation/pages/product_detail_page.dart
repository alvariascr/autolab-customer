import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import 'physical_product_detail_content.dart';
import 'service_detail_content.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.itemType.trim().toLowerCase() == 'service') {
      return ServiceDetailContent(service: product);
    }

    return PhysicalProductDetailContent(product: product);
  }
}
