import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/data/datasources/user_role_data_source.dart';
import 'package:autolab_customer/features/auth/data/services/auth_session_recovery_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_session_storage_service.dart';
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
    this.userRoleDataSource,
    this.loginAttemptService,
    this.sessionStorageService,
    this.sessionRecoveryService,
  );

  final SupabaseClient client;
  final GlobalErrorHandler globalErrorHandler;
  final UserRoleDataSource userRoleDataSource;
  final LoginAttemptService loginAttemptService;
  final AuthSessionStorageService sessionStorageService;
  final AuthSessionRecoveryService sessionRecoveryService;

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
      await sessionStorageService.clearSession();
      return const Right(unit);
    } catch (error, stackTrace) {
      return Left(globalErrorHandler.handle(error, stackTrace));
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final supabaseUser = client.auth.currentUser;

    if (supabaseUser != null) {
      return sessionRecoveryService.restoreFromSupabaseUser(supabaseUser);
    }

    final restoredUser = await sessionRecoveryService.restoreFromRefreshToken();
    if (restoredUser != null) {
      return restoredUser;
    }
    return sessionRecoveryService.recoverFromLocal();
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
      await sessionStorageService.persistSessionTokens(session);
    }

    await sessionStorageService.saveUserSession(
      id: user.id,
      email: user.email,
      role: role,
    );
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

    final networkFailure = _mapNetworkAuthException(error, stackTrace);
    if (networkFailure != null) {
      return Left(networkFailure);
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

    final networkFailure = _mapNetworkAuthException(error, stackTrace);
    if (networkFailure != null) {
      return Left(networkFailure);
    }

    return Left(globalErrorHandler.handle(error, stackTrace));
  }

  Failure? _mapNetworkAuthException(
    AuthException error,
    StackTrace stackTrace,
  ) {
    final message = error.message.toLowerCase();
    final runtimeTypeName = error.runtimeType.toString().toLowerCase();

    if (_isTimeoutLikeAuthFailure(message, runtimeTypeName)) {
      return NetworkFailure.fromErrorItem(
        ErrorCatalog.requestTimeout,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (_isNetworkLikeAuthFailure(message, runtimeTypeName)) {
      return NetworkFailure.fromErrorItem(
        ErrorCatalog.networkUnavailable,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  bool _isTimeoutLikeAuthFailure(String message, String runtimeTypeName) {
    return message.contains('timeout') ||
        message.contains('timed out') ||
        runtimeTypeName.contains('timeout');
  }

  bool _isNetworkLikeAuthFailure(String message, String runtimeTypeName) {
    return runtimeTypeName.contains('retryablefetch') ||
        message.contains('failed host lookup') ||
        message.contains('network request failed') ||
        message.contains('network error') ||
        message.contains('connection error') ||
        message.contains('clientexception') ||
        message.contains('socketexception') ||
        message.contains('connection closed') ||
        message.contains('connection refused') ||
        message.contains('unable to resolve host') ||
        message.contains('temporarily unavailable');
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
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
      uiKey: AuthErrorCatalog.authRateLimit.uiKey,
      message: AuthErrorCatalog.authRateLimit.code,
      cause: cause,
      stackTrace: stackTrace,
    );
  }
}
