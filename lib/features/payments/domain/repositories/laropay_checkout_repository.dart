import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/laropay_payment_context.dart';

abstract interface class LaropayCheckoutRepository {
  Future<Either<Failure, LaropayPaymentContext>> getPaymentContext(
    String appointmentId,
  );

  Future<Either<Failure, LaropayPaymentContext>> getOrderPaymentContext(
    String orderId,
  );
}
