import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient client;
  final GlobalErrorHandler globalErrorHandler;

  AuthRepositoryImpl(this.client, this.globalErrorHandler);

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        globalErrorHandler.logger.w(
          'Login fallido: respuesta inválida, usuario no disponible',
        );

        return const Left(
          AuthFailure(message: 'Respuesta inválida: usuario no disponible'),
        );
      }

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
      String name,
      String email,
      String phone,
      String password,
      ) async {
    try {
      final cleanName = name.trim();
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      // Verificar si la cuenta ya existe antes de registrar
      try {
        final loginRes = await client.auth.signInWithPassword(
          email: cleanEmail,
          password: cleanPassword,
        );

        if (loginRes.user != null) {
          globalErrorHandler.logger.w(
            'Intento de registro con cuenta ya existente',
          );

          return const Left(
            AuthFailure(message: 'Esta cuenta ya existe. Inicia sesión'),
          );
        }
      } on AuthException catch (e, st) {
        final msg = e.message.toLowerCase();

        if (msg.contains('email not confirmed')) {
          globalErrorHandler.logger.w(
            'Intento de registro con cuenta existente no confirmada',
            error: e,
            stackTrace: st,
          );

          return const Left(
            AuthFailure(
              message: 'Esta cuenta ya existe, pero debes confirmar tu correo',
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
          'role': 'customer',
        },
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

      if (msg.contains('invalid email')) {
        globalErrorHandler.logger.w(
          'Intento de registro con correo inválido',
          error: e,
          stackTrace: st,
        );

        return const Left(
          AuthFailure(message: 'El correo ingresado no es válido'),
        );
      }

      if (msg.contains('password')) {
        globalErrorHandler.logger.w(
          'Intento de registro con contraseña inválida',
          error: e,
          stackTrace: st,
        );

        return const Left(
          AuthFailure(message: 'La contraseña no cumple los requisitos'),
        );
      }

      if (msg.contains('email rate limit exceeded') ||
          msg.contains('rate limit exceeded')) {
        globalErrorHandler.logger.w(
          'Límite de intentos de registro alcanzado',
          error: e,
          stackTrace: st,
        );

        return const Left(
          AuthFailure(
            message:
            'Se alcanzó el límite de intentos de registro. Intenta nuevamente en unos minutos',
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
      return const Right(unit);
    } catch (e, st) {
      final failure = globalErrorHandler.handle(e, st);
      return Left(failure);
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    return AppUser(id: user.id, email: user.email);
  }
}