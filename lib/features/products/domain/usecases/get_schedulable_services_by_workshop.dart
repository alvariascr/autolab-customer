import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetSchedulableServicesByWorkshop {
  const GetSchedulableServicesByWorkshop(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, List<Product>>> call(String workshopId) async {
    final result = await _repository.getActiveProductsByWorkshop(workshopId);

    return result.map((products) {
      return products.where(_isSchedulableService).toList(growable: false);
    });
  }

  bool _isSchedulableService(Product product) {
    return product.itemType.trim().toLowerCase() == 'service' &&
        product.isSchedulable &&
        product.requiresAppointment;
  }
}
