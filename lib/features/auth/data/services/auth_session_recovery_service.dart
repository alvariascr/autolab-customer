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

  Future<AppUser?> restoreFromSupabaseUser(User supabaseUser) async {
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

      return _buildAppUser(
        id: supabaseUser.id,
        email: supabaseUser.email,
        role: role,
      );
    } catch (error, stackTrace) {
      final localSession = await recoverFromLocal();

      if (localSession != null && localSession.id == supabaseUser.id) {
        _featureLogger.info(
          feature: 'auth',
          action: 'restore_from_supabase_user_local_fallback',
          context: {'userId': supabaseUser.id},
        );
        return localSession;
      }

      _featureLogger.error(
        feature: 'auth',
        action: 'restore_from_supabase_user_failed',
        code: AuthErrorCatalog.sessionRestoreFailed.code,
        context: {
          'uiKey': AuthErrorCatalog.sessionRestoreFailed.uiKey,
          'userId': supabaseUser.id,
        },
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  Future<AppUser?> restoreFromRefreshToken() async {
    try {
      final refreshToken = await _sessionStorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _featureLogger.info(
          feature: 'auth',
          action: 'restore_from_refresh_token_empty',
        );
        return null;
      }

      final response = await _client.auth.setSession(refreshToken);
      final session = response.session;
      final user = response.user;

      if (session == null || user == null) {
        _featureLogger.warn(
          feature: 'auth',
          action: 'restore_from_refresh_token_invalid_response',
          code: AuthErrorCatalog.sessionRestoreFailed.code,
          context: {'uiKey': AuthErrorCatalog.sessionRestoreFailed.uiKey},
        );
        return null;
      }

      await _sessionStorageService.persistSessionTokens(session);
      _featureLogger.info(
        feature: 'auth',
        action: 'restore_from_refresh_token_succeeded',
        context: {'userId': user.id},
      );
      return restoreFromSupabaseUser(user);
    } on AuthException catch (error, stackTrace) {
      _featureLogger.warn(
        feature: 'auth',
        action: 'restore_from_refresh_token_auth_exception',
        code: AuthErrorCatalog.sessionRestoreFailed.code,
        context: {'uiKey': AuthErrorCatalog.sessionRestoreFailed.uiKey},
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } catch (error, stackTrace) {
      _featureLogger.warn(
        feature: 'auth',
        action: 'restore_from_refresh_token_failed',
        code: AuthErrorCatalog.sessionRestoreFailed.code,
        context: {'uiKey': AuthErrorCatalog.sessionRestoreFailed.uiKey},
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<AppUser?> recoverFromLocal() async {
    String? sessionJson;
    try {
      sessionJson = await _sessionStorageService.getUserSession();
    } catch (error, stackTrace) {
      _featureLogger.warn(
        feature: 'auth',
        action: 'recover_from_local_read_failed',
        code: AuthErrorCatalog.localSessionRecoveryFailed.code,
        context: {'uiKey': AuthErrorCatalog.localSessionRecoveryFailed.uiKey},
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }

    if (sessionJson == null || sessionJson.isEmpty) {
      return null;
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
        return storedUser;
      }
    } catch (error, stackTrace) {
      _featureLogger.warn(
        feature: 'auth',
        action: 'recover_from_local_parse_failed',
        code: AuthErrorCatalog.localSessionRecoveryFailed.code,
        context: {'uiKey': AuthErrorCatalog.localSessionRecoveryFailed.uiKey},
        error: error,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  AppUser _buildAppUser({
    required String id,
    required String? email,
    required String role,
  }) {
    return AppUser(id: id, email: email, role: role);
  }
}
