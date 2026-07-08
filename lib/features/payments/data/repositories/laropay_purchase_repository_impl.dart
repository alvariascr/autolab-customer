import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../../../auth/domain/errors/auth_error_catalog.dart';
import '../../domain/entities/laropay_purchase.dart';
import '../../domain/repositories/laropay_purchase_repository.dart';
import '../datasources/laropay_purchase_remote_data_source.dart';

class LaropayPurchaseRepositoryImpl implements LaropayPurchaseRepository {
  const LaropayPurchaseRepositoryImpl({
    required LaropayPurchaseRemoteDataSource remoteDataSource,
    required GlobalErrorHandler errorHandler,
  }) : _remoteDataSource = remoteDataSource,
       _errorHandler = errorHandler;

  final LaropayPurchaseRemoteDataSource _remoteDataSource;
  final GlobalErrorHandler _errorHandler;

  @override
  Future<Either<Failure, List<LaropayPurchase>>> getRecentPurchases() {
    return _guard(_remoteDataSource.getRecentPurchases);
  }

  @override
  Future<Either<Failure, LaropayPurchase>> refreshPurchaseStatus(
    String paymentLinkId,
  ) {
    return _guard(() => _remoteDataSource.refreshPurchaseStatus(paymentLinkId));
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on LaropayPurchaseAuthException catch (error, stackTrace) {
      return Left(
        AuthFailure.fromErrorItem(
          AuthErrorCatalog.sessionExpired,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return Left(_errorHandler.handle(error, stackTrace));
    }
  }
}
