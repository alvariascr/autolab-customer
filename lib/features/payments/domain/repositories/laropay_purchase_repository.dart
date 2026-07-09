import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/laropay_purchase.dart';

abstract interface class LaropayPurchaseRepository {
  Future<Either<Failure, List<LaropayPurchase>>> getRecentPurchases();

  Future<Either<Failure, LaropayPurchase>> refreshPurchaseStatus(
    String paymentLinkId,
  );
}
