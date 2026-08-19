import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../../../products/domain/repositories/product_repository.dart';
import '../home_service_inventory_matcher.dart';

class GetHomeServiceWorkshopIds {
  const GetHomeServiceWorkshopIds({
    required ProductRepository productRepository,
    HomeServiceInventoryMatcher matcher = const HomeServiceInventoryMatcher(),
  }) : _productRepository = productRepository,
       _matcher = matcher;

  final ProductRepository _productRepository;
  final HomeServiceInventoryMatcher _matcher;

  Future<Either<Failure, List<String>>> call(String serviceKey) async {
    final result = await _productRepository.getActiveProducts();

    return result.map(
      (products) => products
          .where((product) => _matcher.matchesProduct(serviceKey, product))
          .map((product) => product.workshopId.trim())
          .where((workshopId) => workshopId.isNotEmpty)
          .toSet()
          .toList(growable: false),
    );
  }
}
