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
        await sessionLocalDataSource.saveAccessToken(session.accessToken);

        final refreshToken = session.refreshToken;
        if (refreshToken!.isNotEmpty) {
          await sessionLocalDataSource.saveRefreshToken(refreshToken!);
        }
      }

      final sessionJson = jsonEncode({
        'id': user.id,
        'email': user.email,
        'role': role,
      });

      await sessionLocalDataSource.saveUserSession(sessionJson);
      await loginAttemptService.registerSuccess(cleanEmail);

      return Right(
        AppUser(
          id: user.id,
          email: user.email,
          role: role,
        ),
      );
    } on AuthException catch (e, st) {
      final msg = e.message.toLowerCase();

      if (msg.contains('invalid login credentials')) {
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
              cause: e,
              stackTrace: st,
            ),
          );
        }

        globalErrorHandler.logger.w(
          'Intento de login con credenciales inválidas',
          error: e,
          stackTrace: st,
        );

        return const Left(
          AuthFailure(message: 'Correo o contraseña incorrectos'),
        );
      }

      if (msg.contains('email not confirmed')) {
        globalErrorHandler.logger.w(
          'Intento de login con correo no confirmado',
          error: e,
          stackTrace: st,
        );

        return const Left(
          AuthFailure(
            message: 'Debes confirmar tu correo antes de iniciar sesión',
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
        AppUser(
          id: user.id,
          email: user.email,
          role: UserRoles.customer,
        ),
      );
    } on AuthException catch (e, st) {
      final msg = e.message.toLowerCase();

      if (msg.contains('already registered')) {
        globalErrorHandler.logger.w(
          'Intento de registro con correo ya existente',
          error: e,
          stackTrace: st,
        );

        return const Left(
          AuthFailure(message: 'Este correo ya se encuentra registrado'),
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
          '[${ErrorCatalog.sessionRestoreFailed.code}] ${ErrorCatalog.sessionRestoreFailed.message}',
          error: e,
          stackTrace: st,
        );

        return null;
      }
    }

    return _recoverUserFromLocal();
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
}