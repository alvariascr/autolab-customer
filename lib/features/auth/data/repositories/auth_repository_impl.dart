import 'dart:convert';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/data/datasources/user_role_data_source.dart';
import 'package:autolab_customer/features/auth/data/services/login_attempt_service.dart';
import 'package:autolab_customer/features/auth/domain/constants/user_roles.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/failures/auth_rate_limit_failure.dart';
import '../../repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient client;
  final GlobalErrorHandler globalErrorHandler;
  final SessionLocalDataSource sessionLocalDataSource;
  final UserRoleDataSource userRoleDataSource;
  final LoginAttemptService loginAttemptService;

  AuthRepositoryImpl(
      this.client,
      this.globalErrorHandler,
      this.sessionLocalDataSource,
      this.userRoleDataSource,
      this.loginAttemptService,
      );

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      final attemptState = await loginAttemptService.getState(cleanEmail);

      if (attemptState.isBlocked) {
        final remaining = attemptState.remainingTime;

        return Left(
          _createAuthRateLimitFailure(remaining),
        );
      }

      final res = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = res.user;
      final session = res.session;

      if (user == null) {
        globalErrorHandler.logger.w(
          '[${ErrorCatalog.invalidAuthResponse.code}] ${ErrorCatalog.invalidAuthResponse.message}',
        );

        return Left(
          AuthFailure.fromErrorItem(ErrorCatalog.invalidAuthResponse),
        );
      }

      final role = await userRoleDataSource.getUserRole(user.id);

      if (session != null) {
        await _persistSessionTokens(session);
      }

      await _saveUserSession(
        id: user.id,
        email: user.email,
        role: role,
      );
      await loginAttemptService.registerSuccess(cleanEmail);

      return Right(_buildAppUser(id: user.id, email: user.email, role: role));
    } on AuthException catch (e, st) {
      final msg = e.message.toLowerCase();

      if (msg.contains('invalid login credentials')) {
        final updatedState = await loginAttemptService.registerFailure(
          cleanEmail,
        );

        if (updatedState.isBlocked) {
          final remaining = updatedState.remainingTime;

          return Left(
            _createAuthRateLimitFailure(
              remaining,
              cause: e,
              stackTrace: st,
            ),
          );
        }

        globalErrorHandler.logger.w(
          '[${ErrorCatalog.invalidCredentials.code}] ${ErrorCatalog.invalidCredentials.message}',
          error: e,
          stackTrace: st,
        );

        return Left(
          AuthFailure.fromErrorItem(
            ErrorCatalog.invalidCredentials,
            cause: e,
            stackTrace: st,
          ),
        );
      }

      if (msg.contains('email not confirmed')) {
        globalErrorHandler.logger.w(
          '[${ErrorCatalog.unconfirmedEmail.code}] ${ErrorCatalog.unconfirmedEmail.message}',
          error: e,
          stackTrace: st,
        );

        return Left(
          AuthFailure.fromErrorItem(
            ErrorCatalog.unconfirmedEmail,
            cause: e,
            stackTrace: st,
          ),
        );
      }

      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e, st) {
      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, AppUser>> register(
      String name,
      String email,
      String phone,
      String password,
      ) async {
    try {
      final cleanName = name.trim();
      final cleanEmail = email.trim().toLowerCase();
      final cleanPhone = phone.trim();
      final cleanPassword = password.trim();

      // Verificar si la cuenta ya existe antes de registrar
      try {
        final loginRes = await client.auth.signInWithPassword(
          email: cleanEmail,
          password: cleanPassword,
        );

        if (loginRes.user != null) {
          // Cerramos sesión por si Supabase autenticó al usuario
          await client.auth.signOut();

          globalErrorHandler.logger.w(
            '[${ErrorCatalog.accountAlreadyExists.code}] ${ErrorCatalog.accountAlreadyExists.message}',
          );

          return Left(
            AuthFailure.fromErrorItem(ErrorCatalog.accountAlreadyExists),
          );
        }
      } on AuthException catch (e, st) {
        final msg = e.message.toLowerCase();

        if (msg.contains('email not confirmed')) {
          globalErrorHandler.logger.w(
            '[${ErrorCatalog.emailNotConfirmedRegister.code}] ${ErrorCatalog.emailNotConfirmedRegister.message}',
            error: e,
            stackTrace: st,
          );

          return Left(
            AuthFailure.fromErrorItem(
              ErrorCatalog.emailNotConfirmedRegister,
              cause: e,
              stackTrace: st,
            ),
          );
        }

        if (msg.contains('invalid login credentials')) {
          // Este caso nos sirve para continuar con el registro
        } else {
          final failure = globalErrorHandler.handle(e, st);
          return Left(failure);
        }
      }

      final res = await client.auth.signUp(
        email: cleanEmail,
        password: cleanPassword,
        data: {
          'name': cleanName,
          'phone': cleanPhone,
          'role': UserRoles.customer,
        },
      );

      final user = res.user;
      if (user == null) {
        globalErrorHandler.logger.w(
          '[${ErrorCatalog.invalidRegisterResponse.code}] ${ErrorCatalog.invalidRegisterResponse.message}',
        );

        return Left(
          AuthFailure.fromErrorItem(ErrorCatalog.invalidRegisterResponse),
        );
      }

      return Right(
        _buildAppUser(
          id: user.id,
          email: user.email,
          role: UserRoles.customer,
        ),
      );
    } on AuthException catch (e, st) {
      final msg = e.message.toLowerCase();

      if (msg.contains('already registered')) {
        globalErrorHandler.logger.w(
          '[${ErrorCatalog.emailAlreadyRegistered.code}] ${ErrorCatalog.emailAlreadyRegistered.message}',
          error: e,
          stackTrace: st,
        );

        return Left(
          AuthFailure.fromErrorItem(
            ErrorCatalog.emailAlreadyRegistered,
            cause: e,
            stackTrace: st,
          ),
        );
      }

      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e, st) {
      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    }
  }
  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await client.auth.signOut();
      await sessionLocalDataSource.clearSession();
      return const Right(unit);
    } catch (e, st) {
      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
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
        '[${ErrorCatalog.sessionRestoreFailed.code}] ${ErrorCatalog.sessionRestoreFailed.message}',
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
        '[${ErrorCatalog.sessionRestoreFailed.code}] ${ErrorCatalog.sessionRestoreFailed.message}',
        error: e,
        stackTrace: st,
      );
      return null;
    } catch (e, st) {
      globalErrorHandler.logger.w(
        '[${ErrorCatalog.sessionRestoreFailed.code}] ${ErrorCatalog.sessionRestoreFailed.message}',
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
        '[${ErrorCatalog.localSessionRecoveryFailed.code}] ${ErrorCatalog.localSessionRecoveryFailed.message}',
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
    } catch (e, st) {
      globalErrorHandler.logger.w(
        '[${ErrorCatalog.localSessionRecoveryFailed.code}] ${ErrorCatalog.localSessionRecoveryFailed.message}',
        error: e,
        stackTrace: st,
      );
    }

    return null;
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
    final sessionJson = jsonEncode({
      'id': id,
      'email': email,
      'role': role,
    });

    return sessionLocalDataSource.saveUserSession(sessionJson);
  }

  AppUser _buildAppUser({
    required String id,
    required String? email,
    required String role,
  }) {
    return AppUser(
      id: id,
      email: email,
      role: role,
    );
  }

  AuthRateLimitFailure _createAuthRateLimitFailure(
    Duration remaining, {
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AuthRateLimitFailure(
      remaining: remaining,
      code: ErrorCatalog.authRateLimit.code,
      message:
          '${ErrorCatalog.authRateLimit.message} Intenta nuevamente en ${_formatDuration(remaining)}.',
      cause: cause,
      stackTrace: stackTrace,
    );
  }
}
