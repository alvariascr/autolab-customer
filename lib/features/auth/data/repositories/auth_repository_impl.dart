import 'package:dartz/dartz.dart';
import 'package:autolab_core/autolab_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient client;

  AuthRepositoryImpl(this.client);

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        return Left(Failure('Respuesta inválida: usuario nulo'));
      }

      return Right(AppUser(id: user.id, email: user.email));
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      if (msg.contains('invalid login credentials')) {
        return Left(Failure('Correo o contraseña incorrectos'));
      }

      if (msg.contains('email not confirmed')) {
        return Left(Failure('Debes confirmar tu correo antes de iniciar sesión'));
      }

      return Left(Failure('No se pudo iniciar sesión'));
    } catch (e) {
      return Left(Failure('Error inesperado al iniciar sesión'));
    }
  }

  @override
  Future<Either<Failure, AppUser>> register(String email, String password) async {
    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        return Left(Failure('Respuesta inválida: usuario nulo'));
      }

      return Right(AppUser(id: user.id, email: user.email));
    } catch (e) {
      return Left(Failure('Error de registro: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await client.auth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(Failure('Error de logout: ${e.toString()}'));
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email);
  }
}