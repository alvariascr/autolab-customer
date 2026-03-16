import 'package:dartz/dartz.dart';
import 'package:autolab_core/autolab_core.dart';

import '../domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AppUser>> login(String email, String password);

  Future<Either<Failure, AppUser>> register(String email, String password);

  Future<Either<Failure, Unit>> logout();

  Future<AppUser?> getCurrentUser();
}
