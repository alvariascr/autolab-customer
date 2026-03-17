import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient client;
  final GlobalErrorHandler globalErrorHandler;

  AuthRepositoryImpl(this.client, this.globalErrorHandler);

  Future<String> _getUserRole(String userId) async {
    final response = await client
        .from('user_profiles')
        .select('role')
        .eq('user_id', userId)
        .single();

    final role = response['role'] as String?;

    if (role == null || role.isEmpty) {
      throw Exception('Rol no definido para el usuario');
    }

    if (role != 'customer' && role != 'admin') {
      throw Exception('Rol no autorizado');
    }

    return role;
  }

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

      final role = await _getUserRole(user.id);

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

      final role = await _getUserRole(user.id);

      return Right(
        AppUser(
          id: user.id,
          email: user.email,
          role: role,
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

    try {
      final role = await _getUserRole(user.id);

      return AppUser(
        id: user.id,
        email: user.email,
        role: role,
      );
    } catch (_) {
      return null;
    }
  }
}