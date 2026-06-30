import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/laropay_payment_context.dart';
import '../repositories/laropay_checkout_repository.dart';

class GetLaropayPaymentContext {
  const GetLaropayPaymentContext(this._repository);

  final LaropayCheckoutRepository _repository;

  Future<Either<Failure, LaropayPaymentContext>> call(String appointmentId) {
    return _repository.getPaymentContext(appointmentId);
  }
}
