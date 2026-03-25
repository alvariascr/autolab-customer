import 'dart:convert';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/constants/user_roles.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/failures/auth_rate_limit_failure.dart';
import '../../repository/auth_repository.dart';
import '../datasources/user_role_data_source.dart';
import '../services/login_attempt_service.dart';

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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      final attemptState = await loginAttemptService.getState(cleanEmail);

      if (attemptState.isBlocked) {
        final remaining = attemptState.remainingTime;

        return Left(
          AuthRateLimitFailure(
            remaining: remaining,
            code: ErrorCatalog.authRateLimit.code,
            message:
            '${ErrorCatalog.authRateLimit.message} Intenta nuevamente en ${_formatDuration(remaining)}.',
          ),
        );
      }

      final res = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = res.user;
      final session = res.session;

      if (user == null || session == null) {
        globalErrorHandler.logger.w(
          '[${ErrorCatalog.invalidAuthResponse.code}] ${ErrorCatalog.invalidAuthResponse.message}',
        );

        return Left(
          AuthFailure.fromErrorItem(ErrorCatalog.invalidAuthResponse),
        );
      }

      final role = await userRoleDataSource.getUserRole(user.id);

      await sessionLocalDataSource.saveAccessToken(session.accessToken);

      final refreshToken = session.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await sessionLocalDataSource.saveRefreshToken(refreshToken);
      }

      final sessionJson = jsonEncode({
        'id': user.id,
        'email': user.email,
        'role': role,
      });
      await sessionLocalDataSource.saveUserSession(sessionJson);

      await loginAttemptService.registerSuccess(cleanEmail);

      return Right(AppUser(id: user.id, email: user.email, role: role));
    } on AuthFailure catch (failure) {
      return Left(failure);
    } on AuthException catch (e, st) {
      final msg = e.message.toLowerCase();

      if (msg.contains('invalid login credentials')) {
        globalErrorHandler.logger.w(
          '[${ErrorCatalog.invalidCredentials.code}] ${ErrorCatalog.invalidCredentials.message}',
          error: e,
          stackTrace: st,
        );

        final updatedState = await loginAttemptService.registerFailure(
          cleanEmail,
        );

        if (updatedState.isBlocked) {
          final remaining = updatedState.remainingTime;

          return Left(
            AuthRateLimitFailure(
              remaining: remaining,
              code: ErrorCatalog.authRateLimit.code,
              message:
              '${ErrorCatalog.authRateLimit.message} Intenta nuevamente en ${_formatDuration(remaining)}.',
            ),
          );
        }

        return Left(
          AuthFailure.fromErrorItem(
            ErrorCatalog.invalidCredentials,
            cause: e,
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
          ),
        );
      }

      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    } catch (e, st) {
      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, AppUser>> register(
      String email,
      String password,
      ) async {
    try {
      final res = await client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
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
        AppUser(id: user.id, email: user.email, role: UserRoles.customer),
      );
    } on AuthFailure catch (failure) {
      return Left(failure);
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
          ),
        );
      }

      final failure = globalErrorHandler.handle(e, st);
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
      try {
        final role = await userRoleDataSource.getUserRole(supabaseUser.id);

        final sessionJson = jsonEncode({
          'id': supabaseUser.id,
          'email': supabaseUser.email,
          'role': role,
        });
        await sessionLocalDataSource.saveUserSession(sessionJson);

        globalErrorHandler.logger.i('Sesión restaurada desde Supabase');

        return AppUser(
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
          'No fue posible restaurar la sesión desde red ni desde local',
          error: e,
          stackTrace: st,
        );
        return null;
      }
    }

    return await _recoverUserFromLocal();
  }

  Future<AppUser?> _recoverUserFromLocal() async {
    final sessionJson = await sessionLocalDataSource.getUserSession();
    if (sessionJson == null || sessionJson.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(sessionJson) as Map<String, dynamic>;
      final role = map['role'] as String?;

      if (role != null && UserRoles.isValid(role)) {
        return AppUser(
          id: map['id'] as String,
          email: map['email'] as String?,
          role: role,
        );
      }
    } catch (e, st) {
      globalErrorHandler.logger.w(
        'No se pudo reconstruir la sesión desde almacenamiento local',
        error: e,
        stackTrace: st,
      );
    }

    return null;
  }
}