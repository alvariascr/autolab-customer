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
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

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

MockAuthRepository _mockRepository() => MockAuthRepository();

void _stubLoginSuccess(MockAuthRepository repository) {
  when(() => repository.login(any(), any())).thenAnswer((invocation) async {
    final email = invocation.positionalArguments.first as String;
    return Right(AppUser(id: '123', email: email, role: 'customer'));
  });
}

void _stubLoginFailure(MockAuthRepository repository) {
  when(() => repository.login(any(), any())).thenAnswer(
    (_) async =>
        const Left(AuthFailure(message: 'Correo o contraseña incorrectos')),
  );
}

void _stubRegisterSuccess(MockAuthRepository repository) {
  when(() => repository.register(any(), any(), any(), any())).thenAnswer((
    invocation,
  ) async {
    final email = invocation.positionalArguments[1] as String;
    return Right(AppUser(id: '123', email: email, role: 'customer'));
  });
}

void _stubRegisterFailure(MockAuthRepository repository) {
  when(() => repository.register(any(), any(), any(), any())).thenAnswer(
    (_) async => const Left(AuthFailure(message: 'No se pudo registrar')),
  );
}

void _stubLogoutSuccess(MockAuthRepository repository) {
  when(() => repository.logout()).thenAnswer((_) async => const Right(unit));
}

void _stubCurrentUser(MockAuthRepository repository, AppUser? user) {
  when(() => repository.getCurrentUser()).thenAnswer((_) async => Right(user));
}

void _stubCurrentUserFailure(MockAuthRepository repository) {
  when(() => repository.getCurrentUser()).thenAnswer(
    (_) async => Left(
      AuthFailure(
        message: 'AUTH_011',
        code: 'AUTH_011',
        uiKey: 'authErrorSessionRestoreFailed',
      ),
    ),
  );
}

void main() {
  group('AuthSessionCubit', () {
    test('estado inicial es initial', () {
      final repository = _mockRepository();
      final cubit = AuthSessionCubit(repository, _NoopFeatureLogger());

      expect(cubit.state, const AuthSessionState.initial());

      cubit.close();
    });

    test(
      'restore session sin usuario emite loading y luego unauthenticated',
      () async {
        final repository = _mockRepository();
        _stubCurrentUser(repository, null);
        final cubit = AuthSessionCubit(repository, _NoopFeatureLogger());

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
      final repository = _mockRepository();
      _stubCurrentUser(
        repository,
        const AppUser(id: '123', email: 'test@test.com', role: 'customer'),
      );
      final cubit = AuthSessionCubit(repository, _NoopFeatureLogger());

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
      final repository = _mockRepository();
      _stubCurrentUserFailure(repository);
      final cubit = AuthSessionCubit(repository, _NoopFeatureLogger());

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
      final repository = _mockRepository();
      _stubLogoutSuccess(repository);
      final cubit = AuthSessionCubit(repository, _NoopFeatureLogger());
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
      final repository = _mockRepository();
      _stubLoginSuccess(repository);
      final cubit = LoginFormCubit(repository);

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
      final repository = _mockRepository();
      _stubLoginFailure(repository);
      final cubit = LoginFormCubit(repository);

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
      final repository = _mockRepository();
      _stubRegisterSuccess(repository);
      final cubit = RegisterFormCubit(repository);

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
      final repository = _mockRepository();
      _stubRegisterFailure(repository);
      final cubit = RegisterFormCubit(repository);

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
