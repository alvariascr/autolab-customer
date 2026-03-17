import 'dart:convert';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient client;
  final GlobalErrorHandler globalErrorHandler;
  final SessionLocalDataSource sessionLocalDataSource;

  AuthRepositoryImpl(
    this.client,
    this.globalErrorHandler,
    this.sessionLocalDataSource,
  );

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = res.user;
      final session = res.session;

      if (user == null || session == null) {
        globalErrorHandler.logger.w(
          'Login fallido: respuesta inválida, usuario o sesión no disponible',
        );

        return const Left(
          AuthFailure(
            message: 'Respuesta inválida: usuario o sesión no disponible',
          ),
        );
      }
      await sessionLocalDataSource.saveAccessToken(session.accessToken);

      final refreshToken = session.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await sessionLocalDataSource.saveRefreshToken(refreshToken);
      }
      final sessionJson = jsonEncode({'id': user.id, 'email': user.email});
      await sessionLocalDataSource.saveUserSession(sessionJson);

      return Right(AppUser(id: user.id, email: user.email));
    } on AuthException catch (e, st) {
      final msg = e.message.toLowerCase();

      if (msg.contains('invalid login credentials')) {
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
          'Registro fallido: respuesta inválida, usuario no disponible',
        );

        return const Left(
          AuthFailure(message: 'Respuesta inválida: usuario no disponible'),
        );
      }

      return Right(AppUser(id: user.id, email: user.email));
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
      globalErrorHandler.logger.i('Sesión restaurada desde Supabase');
      return AppUser(id: supabaseUser.id, email: supabaseUser.email);
    }

    final sessionJson = await sessionLocalDataSource.getUserSession();
    if (sessionJson == null || sessionJson.isEmpty) {
      globalErrorHandler.logger.i('No se encontró sesión persistida localmente');
      return null;
    }

    try {
      final map = jsonDecode(sessionJson) as Map<String, dynamic>;

      globalErrorHandler.logger.i(
        'Sesión reconstruida desde secure storage',
      );

      return AppUser(
        id: map['id'] as String,
        email: map['email'] as String?,
      );
    } catch (e, st) {
      globalErrorHandler.logger.w(
        'No se pudo reconstruir la sesión desde secure storage',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
