import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/customer_error_catalog.dart';
import '../../../auth/domain/errors/auth_error_catalog.dart';
import '../../domain/entities/laropay_payment_context.dart';
import '../../domain/repositories/laropay_checkout_repository.dart';
import '../datasources/laropay_checkout_remote_data_source.dart';

class LaropayCheckoutRepositoryImpl implements LaropayCheckoutRepository {
  const LaropayCheckoutRepositoryImpl({
    required LaropayCheckoutRemoteDataSource remoteDataSource,
    required GlobalErrorHandler errorHandler,
  }) : _remoteDataSource = remoteDataSource,
       _errorHandler = errorHandler;

  final LaropayCheckoutRemoteDataSource _remoteDataSource;
  final GlobalErrorHandler _errorHandler;

  @override
  Future<Either<Failure, LaropayPaymentContext>> getPaymentContext(
    String appointmentId,
  ) async {
    try {
      return Right(await _remoteDataSource.getPaymentContext(appointmentId));
    } on LaropayCheckoutAuthException catch (error, stackTrace) {
      return Left(
        AuthFailure.fromErrorItem(
          AuthErrorCatalog.sessionExpired,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on LaropayCheckoutContextException catch (error, stackTrace) {
      return Left(
        ValidationFailure.fromErrorItem(
          CustomerErrorCatalog.laropayInvalidRequest,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return Left(_errorHandler.handle(error, stackTrace));
    }
  }
}
