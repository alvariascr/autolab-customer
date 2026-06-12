import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/customer_error_catalog.dart';
import '../../../../core/logging/feature_logger.dart';
import '../../domain/entities/laropay_link.dart';
import '../../domain/entities/laropay_link_request.dart';
import '../../domain/repositories/laropay_link_repository.dart';
import '../datasources/laropay_link_remote_data_source.dart';
import '../datasources/laropay_link_remote_data_source_impl.dart';

class LaropayLinkRepositoryImpl implements LaropayLinkRepository {
  const LaropayLinkRepositoryImpl({
    required LaropayLinkRemoteDataSource remoteDataSource,
    required GlobalErrorHandler errorHandler,
    required FeatureLogger featureLogger,
  }) : _remoteDataSource = remoteDataSource,
       _errorHandler = errorHandler,
       _featureLogger = featureLogger;

  final LaropayLinkRemoteDataSource _remoteDataSource;
  final GlobalErrorHandler _errorHandler;
  final FeatureLogger _featureLogger;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const _allowedExpirationTypes = {'D', 'H', 'M'};

  @override
  Future<Either<Failure, LaropayLink>> generateLink(
    LaropayLinkRequest request,
  ) async {
    final validationFailure = _validate(request);
    if (validationFailure != null) {
      _featureLogger.warn(
        feature: 'payments',
        action: 'generate_laropay_link_validation_failed',
        code: validationFailure.code,
        context: {'transactionId': request.internalTransactionId},
      );
      return Left(validationFailure);
    }

    final context = {
      'transactionId': request.internalTransactionId,
      'amount': request.amount,
      'email': request.customerEmail,
    };

    try {
      _featureLogger.info(
        feature: 'payments',
        action: 'generate_laropay_link_started',
        context: context,
      );
      final link = await _remoteDataSource.generateLink(request);
      _featureLogger.info(
        feature: 'payments',
        action: 'generate_laropay_link_succeeded',
        context: {...context, 'linkId': link.linkId, 'status': link.status},
      );
      return Right(link);
    } on TimeoutException catch (error, stackTrace) {
      final failure = TimeoutFailure.fromErrorItem(
        CustomerErrorCatalog.laropayNetworkError,
        cause: error,
        stackTrace: stackTrace,
      );
      _logFailure('generate_laropay_link_timeout', failure, context, error);
      return Left(failure);
    } on LaropayGatewayException catch (error, stackTrace) {
      final failure = ServerFailure.fromErrorItem(
        CustomerErrorCatalog.laropayGatewayRejected,
        cause: error,
        stackTrace: stackTrace,
      );
      _logFailure('generate_laropay_link_gateway_rejected', failure, {
        ...context,
        'statusCode': error.statusCode,
      }, error);
      return Left(failure);
    } on FormatException catch (error, stackTrace) {
      final failure = ValidationFailure.fromErrorItem(
        CustomerErrorCatalog.laropayInvalidResponse,
        cause: error,
        stackTrace: stackTrace,
      );
      _logFailure(
        'generate_laropay_link_invalid_response',
        failure,
        context,
        error,
      );
      return Left(failure);
    } catch (error, stackTrace) {
      final failure = _errorHandler.handle(error, stackTrace);
      _featureLogger.error(
        feature: 'payments',
        action: 'generate_laropay_link_unhandled_failed',
        code: failure.code,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    }
  }

  Failure? _validate(LaropayLinkRequest request) {
    if (request.internalTransactionId.trim().isEmpty) {
      return ValidationFailure.fromErrorItem(
        CustomerErrorCatalog.laropayInvalidRequest,
      );
    }

    if (request.amount <= 0) {
      return ValidationFailure.fromErrorItem(
        CustomerErrorCatalog.laropayInvalidAmount,
      );
    }

    if (request.customerFirstName.trim().isEmpty ||
        request.customerLastName.trim().isEmpty) {
      return ValidationFailure.fromErrorItem(
        CustomerErrorCatalog.laropayInvalidRequest,
      );
    }

    if (!_emailPattern.hasMatch(request.customerEmail.trim())) {
      return ValidationFailure.fromErrorItem(CustomerErrorCatalog.invalidEmail);
    }

    if (!_allowedExpirationTypes.contains(
      request.expirationType.trim().toUpperCase(),
    )) {
      return ValidationFailure.fromErrorItem(
        CustomerErrorCatalog.laropayInvalidExpiration,
      );
    }

    if (request.expirationValue <= 0) {
      return ValidationFailure.fromErrorItem(
        CustomerErrorCatalog.laropayInvalidExpiration,
      );
    }

    return null;
  }

  void _logFailure(
    String action,
    Failure failure,
    Map<String, Object?> context,
    Object error,
  ) {
    _featureLogger.warn(
      feature: 'payments',
      action: action,
      code: failure.code,
      context: context,
      error: error,
      stackTrace: failure.stackTrace,
    );
  }
}
