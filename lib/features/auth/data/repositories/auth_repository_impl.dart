import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/constants/user_roles.dart';
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
        .maybeSingle();
    if (response == null) {
      throw const AuthFailure(message: 'Perfil de usuario no encontrado');
    }
    final role = response['role'] as String?;

    if (role == null || role.isEmpty) {
      throw AuthFailure(message: 'Rol no definido para el usuario');
    }
    if (!UserRoles.isValid(role)) {
      throw const AuthFailure(message: 'Rol no autorizado');
    }

    return role;
  }

  @override
  Future<Either<Failure, AppUser>> login(
      String email,
      String password,
      ) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
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
    } on AuthFailure catch (failure) {
      return Left(failure);
    } on AuthException catch (e, st) {
      final msg = e.message.toLowerCase();

      if (msg.contains('invalid login credentials')) {
        return const Left(
          AuthFailure(message: 'Correo o contraseña incorrectos'),
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
      return Right(
        AppUser(id: user.id, email: user.email, role: UserRoles.customer),
      );
    } on AuthFailure catch (failure) {
      return Left(failure);
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

      return AppUser(id: user.id, email: user.email, role: role);
    } on AuthFailure catch (failure, st) {
      globalErrorHandler.logger.e(
        'No fue posible restaurar la sesión por problema de rol/perfil',
        error: failure,
        stackTrace: st,
      );
      return null;
    } catch (e, st) {
      globalErrorHandler.logger.e(
        'Error restaurando sesión del usuario',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
