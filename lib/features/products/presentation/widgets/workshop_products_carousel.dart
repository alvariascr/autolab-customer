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
          return const _ProductsMessage(
            icon: Icons.error_outline_rounded,
            message: 'No fue posible cargar los productos de este taller.',
          );
        }

        if (products.isEmpty) {
          return const _ProductsMessage(
            icon: Icons.inventory_2_outlined,
            message: 'Este taller aun no tiene productos publicados.',
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

class _ProductsMessage extends StatelessWidget {
  const _ProductsMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DED5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9B3D24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AutolabCustomer.caption.copyWith(
                color: const Color(0xFF6B5F57),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
