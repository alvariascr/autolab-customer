import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/laropay_purchase.dart';
import '../repositories/laropay_purchase_repository.dart';

class GetLaropayPurchases {
  const GetLaropayPurchases(this._repository);

  final LaropayPurchaseRepository _repository;

  Future<Either<Failure, List<LaropayPurchase>>> call() {
    return _repository.getRecentPurchases();
  }
}
