import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/logging/feature_logger.dart';
import '../../domain/constants/user_roles.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/errors/auth_error_catalog.dart';
import '../datasources/user_role_data_source.dart';
import 'auth_session_storage_service.dart';

class AuthSessionRecoveryService {
  AuthSessionRecoveryService({
    required SupabaseClient client,
    required AuthSessionStorageService sessionStorageService,
    required UserRoleDataSource userRoleDataSource,
    required FeatureLogger featureLogger,
  }) : _client = client,
       _sessionStorageService = sessionStorageService,
       _userRoleDataSource = userRoleDataSource,
       _featureLogger = featureLogger;

  final SupabaseClient _client;
  final AuthSessionStorageService _sessionStorageService;
  final UserRoleDataSource _userRoleDataSource;
  final FeatureLogger _featureLogger;

  Future<Either<Failure, AppUser?>> restoreFromSupabaseUser(
    User supabaseUser,
  ) async {
    try {
      final role = await _userRoleDataSource.getUserRole(supabaseUser.id);
      await _sessionStorageService.saveUserSession(
        id: supabaseUser.id,
        email: supabaseUser.email,
        role: role,
      );

      _featureLogger.info(
        feature: 'auth',
        action: 'restore_from_supabase_user_succeeded',
        context: {'userId': supabaseUser.id, 'role': role},
      );

      return Right(
        _buildAppUser(
          id: supabaseUser.id,
          email: supabaseUser.email,
          role: role,
        ),
      );
    } catch (error, stackTrace) {
      final localSession = await recoverFromLocal();

      if (localSession.isRight()) {
        final recoveredUser = localSession.getOrElse(() => null);
        if (recoveredUser != null && recoveredUser.id == supabaseUser.id) {
          _featureLogger.info(
            feature: 'auth',
            action: 'restore_from_supabase_user_local_fallback',
            context: {'userId': supabaseUser.id},
          );
          return Right(recoveredUser);
        }
      }

      final failure = AuthFailure.fromErrorItem(
        AuthErrorCatalog.sessionRestoreFailed,
        cause: error,
        stackTrace: stackTrace,
      );

      _featureLogger.error(
        feature: 'auth',
        action: 'restore_from_supabase_user_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey, 'userId': supabaseUser.id},
        error: error,
        stackTrace: stackTrace,
      );

      return Left(failure);
    }
  }

  Future<Either<Failure, AppUser?>> restoreFromRefreshToken() async {
    try {
      final refreshToken = await _sessionStorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _featureLogger.info(
          feature: 'auth',
          action: 'restore_from_refresh_token_empty',
        );
        return const Right(null);
      }

      final response = await _client.auth.setSession(refreshToken);
      final session = response.session;
      final user = response.user;

      if (session == null || user == null) {
        final failure = AuthFailure.fromErrorItem(
          AuthErrorCatalog.sessionRestoreFailed,
        );
        _featureLogger.warn(
          feature: 'auth',
          action: 'restore_from_refresh_token_invalid_response',
          code: failure.code,
          context: {'uiKey': failure.uiKey},
        );
        return Left(failure);
      }

      await _sessionStorageService.persistSessionTokens(session);
      _featureLogger.info(
        feature: 'auth',
        action: 'restore_from_refresh_token_succeeded',
        context: {'userId': user.id},
      );
      return restoreFromSupabaseUser(user);
    } on AuthException catch (error, stackTrace) {
      final failure = AuthFailure.fromErrorItem(
        AuthErrorCatalog.sessionRestoreFailed,
        cause: error,
        stackTrace: stackTrace,
      );
      _featureLogger.warn(
        feature: 'auth',
        action: 'restore_from_refresh_token_auth_exception',
        code: failure.code,
        context: {'uiKey': failure.uiKey},
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    } catch (error, stackTrace) {
      final failure = UnknownFailure.fromErrorItem(
        AuthErrorCatalog.sessionRestoreFailed,
        cause: error,
        stackTrace: stackTrace,
      );
      _featureLogger.warn(
        feature: 'auth',
        action: 'restore_from_refresh_token_failed',
        code: failure.code,
        context: {'uiKey': failure.uiKey},
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    }
  }

  Future<Either<Failure, AppUser?>> recoverFromLocal() async {
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

  AppUser _buildAppUser({
    required String id,
    required String? email,
    required String role,
  }) {
    return AppUser(id: id, email: email, role: role);
  }
}
