import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/auth/domain/constants/user_roles.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:dartz/dartz.dart';

import 'auth_session_storage_service.dart';

class AuthLocalSessionRecoveryService {
  AuthLocalSessionRecoveryService({
    required AuthSessionStorageService sessionStorageService,
    required FeatureLogger featureLogger,
  }) : _sessionStorageService = sessionStorageService,
       _featureLogger = featureLogger;

  final AuthSessionStorageService _sessionStorageService;
  final FeatureLogger _featureLogger;

  Future<Either<Failure, AppUser?>> recover() async {
    String? sessionJson;
    try {
      sessionJson = await _sessionStorageService.getUserSession();
    } catch (error, stackTrace) {
      final failure = AuthFailure.fromErrorItem(
        AuthErrorCatalog.localSessionRecoveryFailed,
        cause: error,
        stackTrace: stackTrace,
      );
      _featureLogger.warn(
        feature: 'auth',
        action: 'recover_from_local_read_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey},
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    }

    if (sessionJson == null || sessionJson.isEmpty) {
      return const Right(null);
    }

    try {
      final storedUser = _sessionStorageService.parseStoredUserSession(
        sessionJson,
      );
      if (storedUser != null && UserRoles.isValid(storedUser.role)) {
        _featureLogger.info(
          feature: 'auth',
          action: 'recover_from_local_succeeded',
          context: {'userId': storedUser.id, 'role': storedUser.role},
        );
        return Right(storedUser);
      }
    } catch (error, stackTrace) {
      final failure = AuthFailure.fromErrorItem(
        AuthErrorCatalog.localSessionRecoveryFailed,
        cause: error,
        stackTrace: stackTrace,
      );
      _featureLogger.warn(
        feature: 'auth',
        action: 'recover_from_local_parse_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey},
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    }

    return const Right(null);
  }
}
