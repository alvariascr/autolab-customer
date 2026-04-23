import 'package:autolab_core/autolab_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    required GlobalErrorHandler errorHandler,
  }) : _client = client,
       _sessionStorageService = sessionStorageService,
       _userRoleDataSource = userRoleDataSource,
       _errorHandler = errorHandler;

  final SupabaseClient _client;
  final AuthSessionStorageService _sessionStorageService;
  final UserRoleDataSource _userRoleDataSource;
  final GlobalErrorHandler _errorHandler;

  Future<AppUser?> restoreFromSupabaseUser(User supabaseUser) async {
    try {
      final role = await _userRoleDataSource.getUserRole(supabaseUser.id);
      await _sessionStorageService.saveUserSession(
        id: supabaseUser.id,
        email: supabaseUser.email,
        role: role,
      );

      _errorHandler.logger.i('Sesión restaurada desde Supabase');

      return _buildAppUser(
        id: supabaseUser.id,
        email: supabaseUser.email,
        role: role,
      );
    } catch (error, stackTrace) {
      final localSession = await recoverFromLocal();

      if (localSession != null && localSession.id == supabaseUser.id) {
        _errorHandler.logger.i(
          'Sesión recuperada desde almacenamiento local por fallo de red',
        );
        return localSession;
      }

      _errorHandler.logger.e(
        '[${AuthErrorCatalog.sessionRestoreFailed.code}] ${_describeErrorItem(AuthErrorCatalog.sessionRestoreFailed)}',
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
        return null;
      }

      final response = await _client.auth.setSession(refreshToken);
      final session = response.session;
      final user = response.user;

      if (session == null || user == null) {
        return null;
      }

      await _sessionStorageService.persistSessionTokens(session);
      return restoreFromSupabaseUser(user);
    } on AuthException catch (error, stackTrace) {
      _errorHandler.logger.w(
        '[${AuthErrorCatalog.sessionRestoreFailed.code}] ${_describeErrorItem(AuthErrorCatalog.sessionRestoreFailed)}',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } catch (error, stackTrace) {
      _errorHandler.logger.w(
        '[${AuthErrorCatalog.sessionRestoreFailed.code}] ${_describeErrorItem(AuthErrorCatalog.sessionRestoreFailed)}',
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
      _errorHandler.logger.w(
        '[${AuthErrorCatalog.localSessionRecoveryFailed.code}] ${_describeErrorItem(AuthErrorCatalog.localSessionRecoveryFailed)}',
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
        return storedUser;
      }
    } catch (error, stackTrace) {
      _errorHandler.logger.w(
        '[${AuthErrorCatalog.localSessionRecoveryFailed.code}] ${_describeErrorItem(AuthErrorCatalog.localSessionRecoveryFailed)}',
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

  String _describeErrorItem(ErrorItem errorItem) {
    return errorItem.message ?? errorItem.uiKey ?? errorItem.code;
  }
}
