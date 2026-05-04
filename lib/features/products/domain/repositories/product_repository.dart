import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getActiveProducts();

  Future<Either<Failure, List<Product>>> getActiveProductsByWorkshop(
    String workshopId,
  );
}
