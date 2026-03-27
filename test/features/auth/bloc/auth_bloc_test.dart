import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/bloc/auth_bloc.dart';
import 'package:autolab_customer/features/auth/bloc/auth_event.dart';
import 'package:autolab_customer/features/auth/bloc/auth_state.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSuccessAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    return Right(
      AppUser(
        id: '123',
        email: email,
        role: 'customer',
      ),
    );
  }

  @override
  Future<Either<Failure, AppUser>> register(
      String name,
      String email,
      String phone,
      String password,
      ) async {
    return Right(
      AppUser(
        id: '123',
        email: email,
        role: 'customer',
      ),
    );
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
    return const Left(
      AuthFailure(message: 'Correo o contraseña incorrectos'),
    );
  }

  @override
  Future<Either<Failure, AppUser>> register(
      String name,
      String email,
      String phone,
      String password,
      ) async {
    return const Left(
      AuthFailure(message: 'No se pudo registrar'),
    );
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    return const Left(
      AuthFailure(message: 'No se pudo cerrar sesión'),
    );
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return null;
  }
}

class FakeRestoreSessionAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    return Right(
      AppUser(
        id: '123',
        email: email,
        role: 'customer',
      ),
    );
  }

  @override
  Future<Either<Failure, AppUser>> register(
      String name,
      String email,
      String phone,
      String password,
      ) async {
    return Right(
      AppUser(
        id: '123',
        email: email,
        role: 'customer',
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    return const Right(unit);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return AppUser(
      id: '123',
      email: 'test@test.com',
      role: 'customer',
    );
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
        const LoginRequested(
          email: 'test@test.com',
          password: '123456',
        ),
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
      'register exitoso emite AuthLoading y luego AuthRegisterSuccess',
          () async {
        final bloc = AuthBloc(FakeSuccessAuthRepository());

        bloc.add(
          const RegisterRequested(
            name: 'Luis',
            email: 'new@test.com',
            phone: '88888888',
            password: '123456',
          ),
        );

        await expectLater(
          bloc.stream,
          emitsInOrder([
            const AuthLoading(),
            const AuthRegisterSuccess('123'),
          ]),
        );

        await bloc.close();
      },
    );

    test('register fallido emite AuthLoading y luego AuthError', () async {
      final bloc = AuthBloc(FakeFailureAuthRepository());

      bloc.add(
        const RegisterRequested(
          name: 'Luis',
          email: 'new@test.com',
          phone: '88888888',
          password: '123456',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthError('No se pudo registrar'),
        ]),
      );

      await bloc.close();
    });

    test('logout fallido emite AuthLoading y luego AuthError', () async {
      final bloc = AuthBloc(FakeFailureAuthRepository());

      bloc.add(const LogoutRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthError('No se pudo cerrar sesión'),
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
          emitsInOrder([
            const AuthLoading(),
            const AuthInitial(),
          ]),
        );

        await bloc.close();
      },
    );

    test(
      'restore session con usuario emite AuthLoading y luego AuthSuccess',
          () async {
        final bloc = AuthBloc(FakeRestoreSessionAuthRepository());

        bloc.add(const RestoreSession());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            const AuthLoading(),
            const AuthSuccess(userId: '123', role: 'customer'),
          ]),
        );

        await bloc.close();
      },
    );

    test('clear auth state emite AuthInitial', () async {
      final bloc = AuthBloc(FakeSuccessAuthRepository());

      bloc.add(const ClearAuthState());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthInitial(),
        ]),
      );

      await bloc.close();
    });
  });
}