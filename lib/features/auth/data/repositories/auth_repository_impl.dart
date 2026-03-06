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
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        return Left(Failure('Respuesta inválida: usuario nulo'));
      }

      return Right(AppUser(id: user.id, email: user.email));
    } catch (e) {
      return Left(Failure('Error de login: ${e.toString()}'));
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