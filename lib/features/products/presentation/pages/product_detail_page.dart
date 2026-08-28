import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/product_inventory_refresh_notifier.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/favorite_inventory_items_repository.dart';
import '../../domain/repositories/product_repository.dart';
import 'physical_product_detail_content.dart';
import 'service_detail_content.dart';

class ProductDetailPage extends StatefulWidget {
  ProductDetailPage({
    super.key,
    required Product this.product,
    this.favoriteRepository,
  }) : workshopId = product.workshopId,
       productId = product.id;

  const ProductDetailPage.resolve({
    super.key,
    this.product,
    required this.workshopId,
    required this.productId,
    this.favoriteRepository,
  });

  final Product? product;
  final String workshopId;
  final String productId;
  final FavoriteInventoryItemsRepository? favoriteRepository;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Product?> _productFuture;
  late final StreamSubscription<void> _inventoryRefreshSubscription;

  @override
  void initState() {
    super.initState();
    _productFuture = _loadProduct();
    _inventoryRefreshSubscription = sl<ProductInventoryRefreshNotifier>().stream
        .listen((_) => _refreshProduct());
  }

  @override
  void dispose() {
    _inventoryRefreshSubscription.cancel();
    super.dispose();
  }

  Future<Product?> _loadProduct() async {
    final result = await sl<ProductRepository>().getActiveProductsByWorkshop(
      widget.workshopId,
    );

    return result.fold(
      (_) => widget.product,
      (products) =>
          products.where((item) => item.id == widget.productId).firstOrNull ??
          widget.product,
    );
  }

  void _refreshProduct() {
    if (!mounted) {
      return;
    }

    setState(() {
      _productFuture = _loadProduct();
    });
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
          return ServiceDetailContent(
            service: product,
            favoriteRepository:
                widget.favoriteRepository ??
                sl<FavoriteInventoryItemsRepository>(),
          );
        }

        return PhysicalProductDetailContent(
          product: product,
          favoriteRepository:
              widget.favoriteRepository ??
              sl<FavoriteInventoryItemsRepository>(),
        );
      },
    );
  }
}
