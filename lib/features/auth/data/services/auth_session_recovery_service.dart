import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/logging/feature_logger.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/errors/auth_error_catalog.dart';
import 'auth_local_session_recovery_service.dart';
import 'auth_session_storage_service.dart';
import 'auth_supabase_session_sync_service.dart';

class AuthSessionRecoveryService {
  AuthSessionRecoveryService({
    required SupabaseClient client,
    required AuthSessionStorageService sessionStorageService,
    required AuthSupabaseSessionSyncService supabaseSessionSyncService,
    required AuthLocalSessionRecoveryService localSessionRecoveryService,
    required FeatureLogger featureLogger,
  }) : _client = client,
       _sessionStorageService = sessionStorageService,
       _supabaseSessionSyncService = supabaseSessionSyncService,
       _localSessionRecoveryService = localSessionRecoveryService,
       _featureLogger = featureLogger;

  final SupabaseClient _client;
  final AuthSessionStorageService _sessionStorageService;
  final AuthSupabaseSessionSyncService _supabaseSessionSyncService;
  final AuthLocalSessionRecoveryService _localSessionRecoveryService;
  final FeatureLogger _featureLogger;

  Future<Either<Failure, AppUser?>> restoreFromSupabaseUser(
    User supabaseUser,
  ) async {
    final syncResult = await _supabaseSessionSyncService.syncUser(supabaseUser);
    if (syncResult.isRight()) {
      return syncResult;
    }

    final localSession = await _localSessionRecoveryService.recover();
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

    return syncResult.fold(Left.new, (_) => const Right(null));
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
      return _supabaseSessionSyncService.syncUser(user);
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
    return _localSessionRecoveryService.recover();
  }
}
