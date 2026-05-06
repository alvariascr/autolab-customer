import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/auth/data/datasources/user_role_data_source.dart';
import 'package:autolab_customer/features/auth/data/mappers/auth_exception_mapper.dart';
import 'package:autolab_customer/features/auth/data/services/auth_login_policy_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_register_precheck_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_session_recovery_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_session_storage_service.dart';
import 'package:autolab_customer/features/auth/domain/constants/user_roles.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this.client,
    this.globalErrorHandler,
    this.userRoleDataSource,
    this.authLoginPolicyService,
    this.authRegisterPrecheckService,
    this.sessionStorageService,
    this.sessionRecoveryService,
    this.featureLogger,
    this.authExceptionMapper,
  );

  final SupabaseClient client;
  final GlobalErrorHandler globalErrorHandler;
  final UserRoleDataSource userRoleDataSource;
  final AuthLoginPolicyService authLoginPolicyService;
  final AuthRegisterPrecheckService authRegisterPrecheckService;
  final AuthSessionStorageService sessionStorageService;
  final AuthSessionRecoveryService sessionRecoveryService;
  final FeatureLogger featureLogger;
  final AuthExceptionMapper authExceptionMapper;

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    final cleanEmail = _normalizeEmail(email);
    final cleanPassword = password.trim();

    featureLogger.info(
      feature: 'auth',
      action: 'login_started',
      context: {'email': cleanEmail},
    );

    try {
      final blockFailure = await authLoginPolicyService.getBlockFailure(
        cleanEmail,
      );
      if (blockFailure != null) {
        featureLogger.warn(
          feature: 'auth',
          action: 'login_blocked',
          code: blockFailure.code,
          context: {'email': cleanEmail, 'uiKey': blockFailure.uiKey},
        );
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

    featureLogger.info(
      feature: 'auth',
      action: 'register_started',
      context: {'email': cleanEmail, 'phoneLength': cleanPhone.length},
    );

    try {
      final precheckFailure = await authRegisterPrecheckService.precheck(
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
      featureLogger.info(
        feature: 'auth',
        action: 'repository_logout_succeeded',
      );
      return const Right(unit);
    } catch (error, stackTrace) {
      featureLogger.error(
        feature: 'auth',
        action: 'repository_logout_failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(globalErrorHandler.handle(error, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    final cleanEmail = _normalizeEmail(email);

    featureLogger.info(
      feature: 'auth',
      action: 'password_reset_email_started',
      context: {'email': cleanEmail},
    );

    try {
      await client.auth.resetPasswordForEmail(
        cleanEmail,
        redirectTo: 'autolab://login-callback/reset-password',
      );

      featureLogger.info(
        feature: 'auth',
        action: 'password_reset_email_succeeded',
        context: {'email': cleanEmail},
      );

      return const Right(unit);
    } on AuthException catch (error, stackTrace) {
      return _handlePasswordRecoveryAuthException(
        error,
        stackTrace,
        action: 'password_reset_email_auth_exception',
        email: cleanEmail,
      );
    } catch (error, stackTrace) {
      featureLogger.error(
        feature: 'auth',
        action: 'password_reset_email_failed',
        context: {'email': cleanEmail},
        error: error,
        stackTrace: stackTrace,
      );
      return Left(globalErrorHandler.handle(error, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String password) async {
    final cleanPassword = password.trim();

    featureLogger.info(feature: 'auth', action: 'password_update_started');

    try {
      await client.auth.updateUser(UserAttributes(password: cleanPassword));
      await client.auth.signOut();
      await sessionStorageService.clearSession();

      featureLogger.info(feature: 'auth', action: 'password_update_succeeded');

      return const Right(unit);
    } on AuthException catch (error, stackTrace) {
      return _handlePasswordRecoveryAuthException(
        error,
        stackTrace,
        action: 'password_update_auth_exception',
      );
    } catch (error, stackTrace) {
      featureLogger.error(
        feature: 'auth',
        action: 'password_update_failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(globalErrorHandler.handle(error, stackTrace));
    }
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    final supabaseUser = client.auth.currentUser;

    if (supabaseUser != null) {
      return sessionRecoveryService.restoreFromSupabaseUser(supabaseUser);
    }

    final restoredUser = await sessionRecoveryService.restoreFromRefreshToken();
    if (restoredUser.isLeft()) {
      return restoredUser;
    }

    final recoveredUser = restoredUser.fold((_) => null, (user) => user);
    if (recoveredUser != null) {
      return Right(recoveredUser);
    }

    return sessionRecoveryService.recoverFromLocal();
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
    await authLoginPolicyService.registerSuccess(cleanEmail);

    featureLogger.info(
      feature: 'auth',
      action: 'login_succeeded',
      context: {'email': cleanEmail, 'userId': user.id, 'role': role},
    );

    return Right(_buildAppUser(id: user.id, email: user.email, role: role));
  }

  Future<Either<Failure, AppUser>> _handleLoginAuthException(
    AuthException error,
    StackTrace stackTrace,
    String cleanEmail,
  ) async {
    final mapping = authExceptionMapper.map(
      error,
      stackTrace,
      flow: AuthExceptionFlow.login,
    );
    if (mapping != null) {
      var mappedFailure = mapping.failure;
      var classification = mapping.classification;

      if (mappedFailure.code == AuthErrorCatalog.invalidCredentials.code) {
        mappedFailure = await authLoginPolicyService.registerInvalidCredentials(
          cleanEmail,
          cause: error,
          stackTrace: stackTrace,
        );
        if (mappedFailure.code == AuthErrorCatalog.authRateLimit.code) {
          classification = 'invalid_credentials_rate_limited';
        }
      }

      featureLogger.warn(
        feature: 'auth',
        action: 'login_auth_exception_mapped',
        code: mappedFailure.code,
        context: _buildAuthExceptionContext(
          error,
          flow: AuthExceptionFlow.login,
          email: cleanEmail,
          failure: mappedFailure,
          classification: classification,
        ),
        error: error,
        stackTrace: stackTrace,
      );

      return Left(mappedFailure);
    }

    featureLogger.error(
      feature: 'auth',
      action: 'login_unhandled_auth_exception',
      context: _buildAuthExceptionContext(
        error,
        flow: AuthExceptionFlow.login,
        email: cleanEmail,
        resolution: 'delegated_to_global_error_handler',
      ),
      error: error,
      stackTrace: stackTrace,
    );
    return Left(globalErrorHandler.handle(error, stackTrace));
  }

  Either<Failure, AppUser> _handleRegisterAuthException(
    AuthException error,
    StackTrace stackTrace,
  ) {
    final mapping = authExceptionMapper.map(
      error,
      stackTrace,
      flow: AuthExceptionFlow.register,
    );
    if (mapping != null) {
      final mappedFailure = mapping.failure;
      featureLogger.warn(
        feature: 'auth',
        action: 'register_auth_exception_mapped',
        code: mappedFailure.code,
        context: _buildAuthExceptionContext(
          error,
          flow: AuthExceptionFlow.register,
          failure: mappedFailure,
          classification: mapping.classification,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      return Left(mappedFailure);
    }

    featureLogger.error(
      feature: 'auth',
      action: 'register_unhandled_auth_exception',
      context: _buildAuthExceptionContext(
        error,
        flow: AuthExceptionFlow.register,
        resolution: 'delegated_to_global_error_handler',
      ),
      error: error,
      stackTrace: stackTrace,
    );
    return Left(globalErrorHandler.handle(error, stackTrace));
  }

  Either<Failure, Unit> _handlePasswordRecoveryAuthException(
    AuthException error,
    StackTrace stackTrace, {
    required String action,
    String? email,
  }) {
    final mappedFailure = authExceptionMapper
        .map(error, stackTrace, flow: AuthExceptionFlow.login)
        ?.failure;

    if (mappedFailure != null) {
      featureLogger.warn(
        feature: 'auth',
        action: action,
        code: mappedFailure.code,
        context: _buildAuthExceptionContext(
          error,
          flow: AuthExceptionFlow.login,
          email: email,
          failure: mappedFailure,
          classification: 'password_recovery',
        ),
        error: error,
        stackTrace: stackTrace,
      );
      return Left(mappedFailure);
    }

    featureLogger.error(
      feature: 'auth',
      action: action,
      context: _buildAuthExceptionContext(
        error,
        flow: AuthExceptionFlow.login,
        email: email,
        resolution: 'delegated_to_global_error_handler',
      ),
      error: error,
      stackTrace: stackTrace,
    );
    return Left(globalErrorHandler.handle(error, stackTrace));
  }

  Map<String, Object?> _buildAuthExceptionContext(
    AuthException error, {
    required AuthExceptionFlow flow,
    Failure? failure,
    String? email,
    String? resolution,
    String? classification,
  }) {
    return authExceptionMapper.buildLogContext(
      error,
      flow: flow,
      failure: failure,
      email: email,
      resolution: resolution,
      classification: classification,
    );
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

  void _logWarning(ErrorItem errorItem) {
    featureLogger.warn(
      feature: 'auth',
      action: 'domain_warning',
      code: errorItem.code,
      context: {'uiKey': errorItem.uiKey},
    );
  }
}
