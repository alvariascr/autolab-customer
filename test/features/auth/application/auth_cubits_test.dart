import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/auth/application/auth_session_cubit.dart';
import 'package:autolab_customer/features/auth/application/auth_session_state.dart';
import 'package:autolab_customer/features/auth/application/login_form_cubit.dart';
import 'package:autolab_customer/features/auth/application/login_form_state.dart';
import 'package:autolab_customer/features/auth/application/register_form_cubit.dart';
import 'package:autolab_customer/features/auth/application/register_form_state.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSuccessAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    return Right(AppUser(id: '123', email: email, role: 'customer'));
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    return Right(AppUser(id: '123', email: email, role: 'customer'));
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    return const Right(null);
  }
}

class _NoopFeatureLogger extends Fake implements FeatureLogger {
  @override
  void info({
    required String feature,
    required String action,
    String? code,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warn({
    required String feature,
    required String action,
    String? code,
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void error({
    required String feature,
    required String action,
    String? code,
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

class FakeFailureAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    return const Left(AuthFailure(message: 'Correo o contraseña incorrectos'));
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    return const Left(AuthFailure(message: 'No se pudo registrar'));
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    return const Left(AuthFailure(message: 'No se pudo cerrar sesión'));
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    return const Right(null);
  }
}

class FakeRestoreSessionAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    return Right(AppUser(id: '123', email: email, role: 'customer'));
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    return Right(AppUser(id: '123', email: email, role: 'customer'));
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    return const Right(
      AppUser(id: '123', email: 'test@test.com', role: 'customer'),
    );
  }
}

class FakeRestoreSessionFailureAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    return Right(AppUser(id: '123', email: email, role: 'customer'));
  }

  @override
  Future<Either<Failure, AppUser>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    return Right(AppUser(id: '123', email: email, role: 'customer'));
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    return Left(
      AuthFailure(
        message: 'AUTH_011',
        code: 'AUTH_011',
        uiKey: 'authErrorSessionRestoreFailed',
      ),
    );
  }
}

void main() {
  group('AuthSessionCubit', () {
    test('estado inicial es initial', () {
      final cubit = AuthSessionCubit(
        FakeSuccessAuthRepository(),
        _NoopFeatureLogger(),
      );

      expect(cubit.state, const AuthSessionState.initial());

      cubit.close();
    });

    test(
      'restore session sin usuario emite loading y luego unauthenticated',
      () async {
        final cubit = AuthSessionCubit(
          FakeSuccessAuthRepository(),
          _NoopFeatureLogger(),
        );

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const AuthSessionState(status: AuthSessionStatus.loading),
            const AuthSessionState(status: AuthSessionStatus.unauthenticated),
          ]),
        );
        cubit.restoreSession();
        await expectation;

        await cubit.close();
      },
    );

    test('restore session con usuario emite authenticated', () async {
      final cubit = AuthSessionCubit(
        FakeRestoreSessionAuthRepository(),
        _NoopFeatureLogger(),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const AuthSessionState(status: AuthSessionStatus.loading),
          const AuthSessionState(
            status: AuthSessionStatus.authenticated,
            userId: '123',
            role: 'customer',
          ),
        ]),
      );
      cubit.restoreSession();
      await expectation;

      await cubit.close();
    });

    test('restore session fallida conserva el failure en estado', () async {
      final cubit = AuthSessionCubit(
        FakeRestoreSessionFailureAuthRepository(),
        _NoopFeatureLogger(),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const AuthSessionState(status: AuthSessionStatus.loading),
          const AuthSessionState(
            status: AuthSessionStatus.unauthenticated,
            code: 'AUTH_011',
            uiKey: 'authErrorSessionRestoreFailed',
          ),
        ]),
      );
      cubit.restoreSession();
      await expectation;

      await cubit.close();
    });

    test('logout exitoso deja el estado en unauthenticated', () async {
      final cubit = AuthSessionCubit(
        FakeSuccessAuthRepository(),
        _NoopFeatureLogger(),
      );
      cubit.setAuthenticated(
        const AppUser(id: '123', email: 'test@test.com', role: 'customer'),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const AuthSessionState(
            status: AuthSessionStatus.loading,
            userId: '123',
            role: 'customer',
          ),
          const AuthSessionState(status: AuthSessionStatus.unauthenticated),
        ]),
      );
      cubit.logout();
      await expectation;

      await cubit.close();
    });
  });

  group('LoginFormCubit', () {
    test('login exitoso emite submitting y luego success', () async {
      final cubit = LoginFormCubit(FakeSuccessAuthRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const LoginFormState(status: LoginFormStatus.submitting),
          const LoginFormState(
            status: LoginFormStatus.success,
            user: AppUser(id: '123', email: 'test@test.com', role: 'customer'),
          ),
        ]),
      );
      cubit.submit(email: 'test@test.com', password: '123456');
      await expectation;

      await cubit.close();
    });

    test('login fallido emite error con mensaje', () async {
      final cubit = LoginFormCubit(FakeFailureAuthRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const LoginFormState(status: LoginFormStatus.submitting),
          const LoginFormState(
            status: LoginFormStatus.error,
            message: 'Correo o contraseña incorrectos',
          ),
        ]),
      );
      cubit.submit(email: 'test@test.com', password: 'wrong');
      await expectation;

      await cubit.close();
    });
  });

  group('RegisterFormCubit', () {
    test('register exitoso emite success con userId', () async {
      final cubit = RegisterFormCubit(FakeSuccessAuthRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const RegisterFormState(status: RegisterFormStatus.submitting),
          const RegisterFormState(
            status: RegisterFormStatus.success,
            userId: '123',
          ),
        ]),
      );
      cubit.submit(
        name: 'Luis',
        email: 'new@test.com',
        phone: '88888888',
        password: '123456',
      );
      await expectation;

      await cubit.close();
    });

    test('register fallido emite error con mensaje', () async {
      final cubit = RegisterFormCubit(FakeFailureAuthRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const RegisterFormState(status: RegisterFormStatus.submitting),
          const RegisterFormState(
            status: RegisterFormStatus.error,
            message: 'No se pudo registrar',
          ),
        ]),
      );
      cubit.submit(
        name: 'Luis',
        email: 'new@test.com',
        phone: '88888888',
        password: '123456',
      );
      await expectation;

      await cubit.close();
    });
  });
}
