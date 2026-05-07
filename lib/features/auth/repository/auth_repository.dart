import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AppUser>> login(String email, String password);

  Future<Either<Failure, AppUser>> register(
    String name,
    String email,
    String phone,
    String password,
  );

  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  Future<Either<Failure, Unit>> updatePassword(String password);

  Future<Either<Failure, AppUser?>> getCurrentUser();
}
