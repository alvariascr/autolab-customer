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
  Future<Either<Failure, List<LaropayPurchase>>> getRecentPurchases() async {
    try {
      return Right(await _remoteDataSource.getRecentPurchases());
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
