import 'dart:async';
import 'dart:io';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/customer_error_catalog.dart';
import '../../domain/entities/workshop.dart';
import '../../domain/repositories/workshop_repository.dart';
import '../datasources/workshop_remote_data_source.dart';

class WorkshopRepositoryImpl implements WorkshopRepository {
  WorkshopRepositoryImpl({
    required this.remoteDataSource,
    required this.errorHandler,
    required this.featureLogger,
  });

  final WorkshopRemoteDataSource remoteDataSource;
  final GlobalErrorHandler errorHandler;
  final FeatureLogger featureLogger;
  Either<Failure, List<Workshop>>? _workshopsCache;
  Future<Either<Failure, List<Workshop>>>? _workshopsRequest;

  @override
  Future<Either<Failure, List<Workshop>>> getWorkshops() async {
    final cached = _workshopsCache;
    if (cached != null) {
      featureLogger.info(
        feature: 'workshops',
        action: 'get_workshops_succeeded',
        context: {
          'count': cached.fold((_) => 0, (workshops) => workshops.length),
          'cached': true,
        },
      );
      return cached;
    }

    final pendingRequest = _workshopsRequest;
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _loadWorkshops();
    _workshopsRequest = request;
    final Either<Failure, List<Workshop>> result;
    try {
      result = await request;
    } finally {
      _workshopsRequest = null;
    }
    result.fold((_) {}, (workshops) {
      _workshopsCache = Right(List<Workshop>.unmodifiable(workshops));
    });
    return result;
  }

  Future<Either<Failure, List<Workshop>>> _loadWorkshops() async {
    try {
      featureLogger.info(feature: 'workshops', action: 'get_workshops_started');
      final workshops = await remoteDataSource.getWorkshops();
      featureLogger.info(
        feature: 'workshops',
        action: 'get_workshops_succeeded',
        context: {'count': workshops.length},
      );
      return Right(workshops);
    } on TimeoutException catch (error, stackTrace) {
      final failure = TimeoutFailure.fromErrorItem(
        CustomerErrorCatalog.workshopNetworkError,
        cause: error,
        stackTrace: stackTrace,
      );
      featureLogger.warn(
        feature: 'workshops',
        action: 'get_workshops_timeout',
        code: failure.code,
        context: {'uiKey': failure.uiKey},
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
        feature: 'workshops',
        action: 'get_workshops_network_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey},
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
        feature: 'workshops',
        action: 'get_workshops_server_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey},
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    } catch (error, stackTrace) {
      final failure = errorHandler.handle(error, stackTrace);
      featureLogger.error(
        feature: 'workshops',
        action: 'get_workshops_unhandled_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey},
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, Workshop?>> getWorkshopById(String id) async {
    try {
      featureLogger.info(
        feature: 'workshops',
        action: 'get_workshop_by_id_started',
        context: {'workshopId': id},
      );
      final workshop = await remoteDataSource.getWorkshopById(id);
      featureLogger.info(
        feature: 'workshops',
        action: 'get_workshop_by_id_succeeded',
        context: {'workshopId': id, 'found': workshop != null},
      );
      return Right(workshop);
    } on TimeoutException catch (error, stackTrace) {
      final failure = TimeoutFailure.fromErrorItem(
        CustomerErrorCatalog.workshopNetworkError,
        cause: error,
        stackTrace: stackTrace,
      );
      featureLogger.warn(
        feature: 'workshops',
        action: 'get_workshop_by_id_timeout',
        code: failure.code,
        context: {'uiKey': failure.uiKey, 'workshopId': id},
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
        feature: 'workshops',
        action: 'get_workshop_by_id_network_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey, 'workshopId': id},
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
        feature: 'workshops',
        action: 'get_workshop_by_id_server_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey, 'workshopId': id},
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    } catch (error, stackTrace) {
      final failure = errorHandler.handle(error, stackTrace);
      featureLogger.error(
        feature: 'workshops',
        action: 'get_workshop_by_id_unhandled_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey, 'workshopId': id},
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    }
  }
}
