import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autolab_customer/features/auth/bloc/auth_bloc.dart';
import 'package:autolab_customer/features/auth/bloc/auth_event.dart';
import 'package:autolab_customer/features/auth/bloc/auth_state.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/repository/auth_repository.dart';

class FakeSuccessAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    return Right(AppUser(id: '123', email: email, role: 'customer'));
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String email,
    String password,
  ) async {
    return Right(AppUser(id: '123', email: email, role: 'customer'));
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    return const Right(unit);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return null;
  }
}

class FakeFailureAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    return const Left(AuthFailure(message: 'Correo o contraseña incorrectos'));
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String email,
    String password,
  ) async {
    return const Left(AuthFailure(message: 'No se pudo registrar'));
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    return const Left(AuthFailure(message: 'No se pudo cerrar sesión'));
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return null;
  }
}

void main() {
  group('AuthBloc', () {
    test('estado inicial es AuthInitial', () {
      final bloc = AuthBloc(FakeSuccessAuthRepository());

      expect(bloc.state, const AuthInitial());

      bloc.close();
    });

    test('login exitoso emite AuthLoading y luego AuthSuccess', () async {
      final bloc = AuthBloc(FakeSuccessAuthRepository());

      bloc.add(
        const LoginRequested(email: 'test@test.com', password: '123456'),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthSuccess(userId: '123', role: 'customer'),
        ]),
      );

      await bloc.close();
    });

    test('login fallido emite AuthLoading y luego AuthError', () async {
      final bloc = AuthBloc(FakeFailureAuthRepository());

      bloc.add(
        const LoginRequested(
          email: 'test@test.com',
          password: 'wrong-password',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthError('Correo o contraseña incorrectos'),
        ]),
      );

      await bloc.close();
    });

    test(
      'restore session sin usuario emite AuthLoading y luego AuthInitial',
      () async {
        final bloc = AuthBloc(FakeSuccessAuthRepository());

        bloc.add(const RestoreSession());

        await expectLater(
          bloc.stream,
          emitsInOrder([const AuthLoading(), const AuthInitial()]),
        );

        await bloc.close();
      },
    );
  });
}
