import 'package:flutter/material.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'physical_product_detail_content.dart';
import 'service_detail_content.dart';

class ProductDetailPage extends StatefulWidget {
  ProductDetailPage({super.key, required Product this.product})
    : workshopId = product.workshopId,
      productId = product.id;

  const ProductDetailPage.resolve({
    super.key,
    this.product,
    required this.workshopId,
    required this.productId,
  });

  final Product? product;
  final String workshopId;
  final String productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final Future<Product?> _productFuture = widget.product == null
      ? _loadProduct()
      : Future.value(widget.product);

  Future<Product?> _loadProduct() async {
    final result = await sl<ProductRepository>().getActiveProductsByWorkshop(
      widget.workshopId,
    );

    return result.fold(
      (_) => null,
      (products) =>
          products.where((item) => item.id == widget.productId).firstOrNull,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product?>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final product = snapshot.data;
        if (product == null) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            body: Center(child: Text(l10n.routerInvalidWorkshopId)),
          );
        }

        if (product.itemType.trim().toLowerCase() == 'service') {
          return ServiceDetailContent(service: product);
        }

        return PhysicalProductDetailContent(product: product);
      },
    );
  }
}
