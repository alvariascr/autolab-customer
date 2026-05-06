import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/application/password_recovery_cubit.dart';
import 'package:autolab_customer/features/auth/application/password_recovery_state.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _PasswordRecoverySuccessRepository implements AuthRepository {
  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String password) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Unit>> logout() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String name,
    String email,
    String phone,
    String password,
  ) {
    throw UnimplementedError();
  }
}

class _PasswordRecoveryFailureRepository
    extends _PasswordRecoverySuccessRepository {
  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    return const Left(AuthFailure(message: 'No se pudo enviar'));
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String password) async {
    return const Left(AuthFailure(message: 'No se pudo actualizar'));
  }
}

void main() {
  group('PasswordRecoveryCubit', () {
    test('sendResetEmail emite submitting y success', () async {
      final cubit = PasswordRecoveryCubit(_PasswordRecoverySuccessRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PasswordRecoveryState(
            status: PasswordRecoveryStatus.submitting,
          ),
          const PasswordRecoveryState(status: PasswordRecoveryStatus.success),
        ]),
      );

      await cubit.sendResetEmail(email: 'test@test.com');
      await expectation;
      await cubit.close();
    });

    test('updatePassword emite submitting y error', () async {
      final cubit = PasswordRecoveryCubit(_PasswordRecoveryFailureRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PasswordRecoveryState(
            status: PasswordRecoveryStatus.submitting,
          ),
          const PasswordRecoveryState(
            status: PasswordRecoveryStatus.error,
            message: 'No se pudo actualizar',
          ),
        ]),
      );

      await cubit.updatePassword(password: '123456');
      await expectation;
      await cubit.close();
    });
  });
}
