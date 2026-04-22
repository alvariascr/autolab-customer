import 'dart:convert';

import 'package:autolab_core/autolab_core.dart' hide SessionLocalDataSource;
import 'package:autolab_customer/features/auth/data/datasources/session_local_data_source.dart';
import 'package:autolab_customer/features/auth/data/datasources/user_role_data_source.dart';
import 'package:autolab_customer/features/auth/data/services/login_attempt_service.dart';
import 'package:autolab_customer/features/auth/domain/constants/user_roles.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/failures/auth_rate_limit_failure.dart';
import '../../repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this.client,
    this.globalErrorHandler,
    this.sessionLocalDataSource,
    this.userRoleDataSource,
    this.loginAttemptService,
  );

  final SupabaseClient client;
  final GlobalErrorHandler globalErrorHandler;
  final SessionLocalDataSource sessionLocalDataSource;
  final UserRoleDataSource userRoleDataSource;
  final LoginAttemptService loginAttemptService;

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    final cleanEmail = _normalizeEmail(email);
    final cleanPassword = password.trim();

    try {
      final blockFailure = await _getLoginBlockFailure(cleanEmail);
      if (blockFailure != null) {
        return Left(blockFailure);
      }

      final response = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      return _buildLoginSuccess(response, cleanEmail);
    } on AuthException catch (error, stackTrace) {
      return _handleLoginAuthException(error, stackTrace, cleanEmail);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (error, stackTrace) {
      return Left(globalErrorHandler.handle(error, stackTrace));
    }
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final cleanName = name.trim();
    final cleanEmail = _normalizeEmail(email);
    final cleanPhone = phone.trim();
    final cleanPassword = password.trim();

    try {
      final precheckFailure = await _precheckRegister(
        cleanEmail: cleanEmail,
        cleanPassword: cleanPassword,
      );
      if (precheckFailure != null) {
        return Left(precheckFailure);
      }

      final response = await client.auth.signUp(
        email: cleanEmail,
        password: cleanPassword,
        data: {
          'name': cleanName,
          'phone': cleanPhone,
          'role': UserRoles.customer,
        },
      );

      final user = response.user;
      if (user == null) {
        _logWarning(AuthErrorCatalog.invalidRegisterResponse);
        return Left(
          AuthFailure.fromErrorItem(AuthErrorCatalog.invalidRegisterResponse),
        );
      }

      return Right(
        _buildAppUser(id: user.id, email: user.email, role: UserRoles.customer),
      );
    } on AuthException catch (error, stackTrace) {
      return _handleRegisterAuthException(error, stackTrace);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (error, stackTrace) {
      return Left(globalErrorHandler.handle(error, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await client.auth.signOut();
      await sessionLocalDataSource.clearSession();
      return const Right(unit);
    } catch (error, stackTrace) {
      return Left(globalErrorHandler.handle(error, stackTrace));
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final supabaseUser = client.auth.currentUser;

    if (supabaseUser != null) {
      return _restoreUserFromSupabase(supabaseUser);
    }

    final restoredUser = await _restoreSupabaseSessionFromLocalTokens();
    if (restoredUser != null) {
      return restoredUser;
    }
    return _recoverUserFromLocal();
  }

  Future<Failure?> _getLoginBlockFailure(String cleanEmail) async {
    final attemptState = await loginAttemptService.getState(cleanEmail);
    if (!attemptState.isBlocked) {
      return null;
    }

    return _createAuthRateLimitFailure(attemptState.remainingTime);
  }

  Future<Either<Failure, AppUser>> _buildLoginSuccess(
    AuthResponse response,
    String cleanEmail,
  ) async {
    final user = response.user;
    if (user == null) {
      _logWarning(AuthErrorCatalog.invalidAuthResponse);
      return Left(
        AuthFailure.fromErrorItem(AuthErrorCatalog.invalidAuthResponse),
      );
    }

    final role = await userRoleDataSource.getUserRole(user.id);
    final session = response.session;

    if (session != null) {
      await _persistSessionTokens(session);
    }

    await _saveUserSession(id: user.id, email: user.email, role: role);
    await loginAttemptService.registerSuccess(cleanEmail);

    return Right(_buildAppUser(id: user.id, email: user.email, role: role));
  }

  Future<Either<Failure, AppUser>> _handleLoginAuthException(
    AuthException error,
    StackTrace stackTrace,
    String cleanEmail,
  ) async {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      final updatedState = await loginAttemptService.registerFailure(
        cleanEmail,
      );

      if (updatedState.isBlocked) {
        return Left(
          _createAuthRateLimitFailure(
            updatedState.remainingTime,
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }

      _logWarning(
        AuthErrorCatalog.invalidCredentials,
        error: error,
        stackTrace: stackTrace,
      );

      return Left(
        AuthFailure.fromErrorItem(
          AuthErrorCatalog.invalidCredentials,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    if (message.contains('email not confirmed')) {
      _logWarning(
        AuthErrorCatalog.unconfirmedEmail,
        error: error,
        stackTrace: stackTrace,
      );

      return Left(
        AuthFailure.fromErrorItem(
          AuthErrorCatalog.unconfirmedEmail,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    return Left(globalErrorHandler.handle(error, stackTrace));
  }

  Future<Failure?> _precheckRegister({
    required String cleanEmail,
    required String cleanPassword,
  }) async {
    try {
      final loginResponse = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (loginResponse.user == null) {
        return null;
      }

      await client.auth.signOut();
      _logWarning(AuthErrorCatalog.accountAlreadyExists);
      return AuthFailure.fromErrorItem(AuthErrorCatalog.accountAlreadyExists);
    } on AuthException catch (error, stackTrace) {
      final message = error.message.toLowerCase();

      if (message.contains('invalid login credentials')) {
        return null;
      }

      if (message.contains('email not confirmed')) {
        _logWarning(
          AuthErrorCatalog.emailNotConfirmedRegister,
          error: error,
          stackTrace: stackTrace,
        );

        return AuthFailure.fromErrorItem(
          AuthErrorCatalog.emailNotConfirmedRegister,
          cause: error,
          stackTrace: stackTrace,
        );
      }

      return globalErrorHandler.handle(error, stackTrace);
    }
  }

  Either<Failure, AppUser> _handleRegisterAuthException(
    AuthException error,
    StackTrace stackTrace,
  ) {
    final message = error.message.toLowerCase();

    if (message.contains('already registered')) {
      _logWarning(
        AuthErrorCatalog.emailAlreadyRegistered,
        error: error,
        stackTrace: stackTrace,
      );

      return Left(
        AuthFailure.fromErrorItem(
          AuthErrorCatalog.emailAlreadyRegistered,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    return Left(globalErrorHandler.handle(error, stackTrace));
  }

  Future<AppUser?> _restoreUserFromSupabase(User supabaseUser) async {
    try {
      final role = await userRoleDataSource.getUserRole(supabaseUser.id);
      await _saveUserSession(
        id: supabaseUser.id,
        email: supabaseUser.email,
        role: role,
      );

      globalErrorHandler.logger.i('Sesión restaurada desde Supabase');

      return _buildAppUser(
        id: supabaseUser.id,
        email: supabaseUser.email,
        role: role,
      );
    } catch (e, st) {
      final localSession = await _recoverUserFromLocal();

      if (localSession != null && localSession.id == supabaseUser.id) {
        globalErrorHandler.logger.i(
          'Sesión recuperada desde almacenamiento local por fallo de red',
        );
        return localSession;
      }

      globalErrorHandler.logger.e(
        '[${AuthErrorCatalog.sessionRestoreFailed.code}] ${AuthErrorCatalog.sessionRestoreFailed.message}',
        error: e,
        stackTrace: st,
      );

      return null;
    }
  }

  Future<AppUser?> _restoreSupabaseSessionFromLocalTokens() async {
    try {
      final refreshToken = await sessionLocalDataSource.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final response = await client.auth.setSession(refreshToken);
      final session = response.session;
      final user = response.user;

      if (session == null || user == null) {
        return null;
      }

      await _persistSessionTokens(session);
      return _restoreUserFromSupabase(user);
    } on AuthException catch (e, st) {
      globalErrorHandler.logger.w(
        '[${AuthErrorCatalog.sessionRestoreFailed.code}] ${AuthErrorCatalog.sessionRestoreFailed.message}',
        error: e,
        stackTrace: st,
      );
      return null;
    } catch (e, st) {
      globalErrorHandler.logger.w(
        '[${AuthErrorCatalog.sessionRestoreFailed.code}] ${AuthErrorCatalog.sessionRestoreFailed.message}',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<AppUser?> _recoverUserFromLocal() async {
    String? sessionJson;
    try {
      sessionJson = await sessionLocalDataSource.getUserSession();
    } catch (e, st) {
      globalErrorHandler.logger.w(
        '[${AuthErrorCatalog.localSessionRecoveryFailed.code}] ${AuthErrorCatalog.localSessionRecoveryFailed.message}',
        error: e,
        stackTrace: st,
      );
      return null;
    }

    if (sessionJson == null || sessionJson.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(sessionJson) as Map<String, dynamic>;
      final role = map['role'] as String?;

      if (role != null && UserRoles.isValid(role)) {
        return _buildAppUser(
          id: map['id'] as String,
          email: map['email'] as String?,
          role: role,
        );
      }
    } catch (error, stackTrace) {
      globalErrorHandler.logger.w(
        '[${AuthErrorCatalog.localSessionRecoveryFailed.code}] ${AuthErrorCatalog.localSessionRecoveryFailed.message}',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  Future<void> _persistSessionTokens(Session session) async {
    await sessionLocalDataSource.saveAccessToken(session.accessToken);

    final refreshToken = session.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await sessionLocalDataSource.saveRefreshToken(refreshToken);
    }
  }

  Future<void> _saveUserSession({
    required String id,
    required String? email,
    required String role,
  }) {
    final sessionJson = jsonEncode({'id': id, 'email': email, 'role': role});

    return sessionLocalDataSource.saveUserSession(sessionJson);
  }

  AppUser _buildAppUser({
    required String id,
    required String? email,
    required String role,
  }) {
    return AppUser(id: id, email: email, role: role);
  }

  void _logWarning(
    ErrorItem errorItem, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    globalErrorHandler.logger.w(
      '[${errorItem.code}] ${errorItem.message}',
      error: error,
      stackTrace: stackTrace,
    );
  }

  AuthRateLimitFailure _createAuthRateLimitFailure(
    Duration remaining, {
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AuthRateLimitFailure(
      remaining: remaining,
      code: AuthErrorCatalog.authRateLimit.code,
      message:
          '${AuthErrorCatalog.authRateLimit.message} Intenta nuevamente en ${_formatDuration(remaining)}.',
      cause: cause,
      stackTrace: stackTrace,
    );
  }
}
