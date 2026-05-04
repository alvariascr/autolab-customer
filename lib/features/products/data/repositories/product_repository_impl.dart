import 'dart:async';
import 'dart:io';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/customer_error_catalog.dart';
import '../../../../core/logging/feature_logger.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.errorHandler,
    required this.featureLogger,
  });

  final ProductRemoteDataSource remoteDataSource;
  final GlobalErrorHandler errorHandler;
  final FeatureLogger featureLogger;

  @override
  Future<Either<Failure, List<Product>>> getActiveProducts() async {
    return _guard(
      action: 'get_active_products',
      loader: remoteDataSource.getActiveProducts,
    );
  }

  @override
  Future<Either<Failure, List<Product>>> getActiveProductsByWorkshop(
    String workshopId,
  ) async {
    return _guard(
      action: 'get_active_products_by_workshop',
      context: {'workshopId': workshopId},
      loader: () => remoteDataSource.getActiveProductsByWorkshop(workshopId),
    );
  }

  Future<Either<Failure, List<Product>>> _guard({
    required String action,
    required Future<List<Product>> Function() loader,
    Map<String, Object?> context = const {},
  }) async {
    try {
      featureLogger.info(
        feature: 'products',
        action: '${action}_started',
        context: context,
      );
      final products = await loader();
      featureLogger.info(
        feature: 'products',
        action: '${action}_succeeded',
        context: {...context, 'count': products.length},
      );
      return Right(products);
    } on TimeoutException catch (error, stackTrace) {
      final failure = TimeoutFailure.fromErrorItem(
        CustomerErrorCatalog.workshopNetworkError,
        cause: error,
        stackTrace: stackTrace,
      );
      featureLogger.warn(
        feature: 'products',
        action: '${action}_timeout',
        code: failure.code,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    } on SocketException catch (error, stackTrace) {
      final failure = NetworkFailure.fromErrorItem(
        CustomerErrorCatalog.workshopNetworkError,
        cause: error,
        stackTrace: stackTrace,
      );
      featureLogger.warn(
        feature: 'products',
        action: '${action}_network_failed',
        code: failure.code,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    } on PostgrestException catch (error, stackTrace) {
      final failure = ServerFailure.fromErrorItem(
        CustomerErrorCatalog.workshopLoadFailed,
        cause: error,
        stackTrace: stackTrace,
      );
      featureLogger.warn(
        feature: 'products',
        action: '${action}_server_failed',
        code: failure.code,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    } catch (error, stackTrace) {
      final failure = errorHandler.handle(error, stackTrace);
      featureLogger.error(
        feature: 'products',
        action: '${action}_unhandled_failed',
        code: failure.code,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    }
  }
}
