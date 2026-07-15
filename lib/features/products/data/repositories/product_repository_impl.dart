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
  Either<Failure, List<Product>>? _activeProductsCache;
  Future<Either<Failure, List<Product>>>? _activeProductsRequest;
  final Map<String, Either<Failure, List<Product>>> _productsByWorkshopCache =
      {};
  final Map<String, Future<Either<Failure, List<Product>>>>
  _productsByWorkshopRequests = {};

  @override
  Future<Either<Failure, List<Product>>> getActiveProducts() async {
    final cached = _activeProductsCache;
    if (cached != null) {
      featureLogger.info(
        feature: 'products',
        action: 'get_active_products_succeeded',
        context: {
          'count': cached.fold((_) => 0, (products) => products.length),
          'cached': true,
        },
      );
      return cached;
    }

    final pendingRequest = _activeProductsRequest;
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _guard(
      action: 'get_active_products',
      loader: remoteDataSource.getActiveProducts,
    );
    _activeProductsRequest = request;
    final result = await request;
    _activeProductsRequest = null;
    result.fold((_) {}, (products) {
      _activeProductsCache = Right(List<Product>.unmodifiable(products));
    });
    return result;
  }

  @override
  Future<Either<Failure, List<Product>>> getActiveProductsByWorkshop(
    String workshopId,
  ) async {
    final cached = _productsByWorkshopCache[workshopId];
    if (cached != null) {
      featureLogger.info(
        feature: 'products',
        action: 'get_active_products_by_workshop_succeeded',
        context: {
          'workshopId': workshopId,
          'count': cached.fold((_) => 0, (products) => products.length),
          'cached': true,
        },
      );
      return cached;
    }

    final pendingRequest = _productsByWorkshopRequests[workshopId];
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _guard(
      action: 'get_active_products_by_workshop',
      context: {'workshopId': workshopId},
      loader: () => remoteDataSource.getActiveProductsByWorkshop(workshopId),
    );
    _productsByWorkshopRequests[workshopId] = request;
    final result = await request;
    _productsByWorkshopRequests.remove(workshopId);
    result.fold((_) {}, (products) {
      _productsByWorkshopCache[workshopId] = Right(
        List<Product>.unmodifiable(products),
      );
    });
    return result;
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
