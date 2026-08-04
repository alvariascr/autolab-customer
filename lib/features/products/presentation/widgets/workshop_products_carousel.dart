import 'package:autolab_core/autolab_core.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_card.dart';
import 'products_message.dart';

class WorkshopProductsCarousel extends StatefulWidget {
  const WorkshopProductsCarousel({super.key, required this.workshopId});

  final String workshopId;

  @override
  State<WorkshopProductsCarousel> createState() =>
      _WorkshopProductsCarouselState();
}

class _WorkshopProductsCarouselState extends State<WorkshopProductsCarousel> {
  late Future<Either<Failure, List<Product>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = sl<ProductRepository>().getActiveProductsByWorkshop(
      widget.workshopId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, List<Product>>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 254,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final result = snapshot.data;
        final products =
            result?.fold((_) => const <Product>[], (items) => items) ??
            const <Product>[];

        if (result == null || result.isLeft()) {
          return ProductsMessage(
            icon: Icons.error_outline_rounded,
            message: 'No fue posible cargar los productos de este taller.',
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            backgroundColor: AutolabCustomer.customerElevatedSurfaceColor(
              context,
            ),
            borderColor: AutolabCustomer.customerBorderColor(context),
            borderRadius: 16,
            iconSpacing: 12,
            textHeight: 1.35,
          );
        }

        if (products.isEmpty) {
          return ProductsMessage(
            icon: Icons.inventory_2_outlined,
            message: 'Este taller aun no tiene productos publicados.',
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            backgroundColor: AutolabCustomer.customerElevatedSurfaceColor(
              context,
            ),
            borderColor: AutolabCustomer.customerBorderColor(context),
            borderRadius: 16,
            iconSpacing: 12,
            textHeight: 1.35,
          );
        }

        return CarouselSlider(
          options: CarouselOptions(
            height: 268,
            enlargeCenterPage: false,
            viewportFraction: 0.62,
            padEnds: false,
            enableInfiniteScroll: products.length > 1,
          ),
          items: products.map((product) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ProductCard(
                product: product,
                onTap: () {
                  context.push(
                    '/workshops/${product.workshopId}/products/${product.id}',
                    extra: product,
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
