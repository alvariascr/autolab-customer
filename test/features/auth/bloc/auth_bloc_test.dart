import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/bloc/auth_bloc.dart';
import 'package:autolab_customer/features/auth/bloc/auth_event.dart';
import 'package:autolab_customer/features/auth/bloc/auth_state.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/repository/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(mockAuthRepository);
  });

  tearDown(() async {
    await authBloc.close();
  });

  group('AuthBloc', () {
    test('estado inicial es AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    test(
      'login exitoso consulta al repositorio y emite AuthLoading y AuthSuccess',
          () async {
        final user = AppUser(
          id: '123',
          email: 'test@test.com',
          role: 'customer',
        );

        when(
              () => mockAuthRepository.login('test@test.com', '123456'),
        ).thenAnswer((_) async => Right(user));

        authBloc.add(
          const LoginRequested(email: 'test@test.com', password: '123456'),
        );

        await expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            const AuthSuccess(userId: '123', role: 'customer'),
          ]),
        );

        verify(
              () => mockAuthRepository.login('test@test.com', '123456'),
        ).called(1);
      },
    );

    test(
      'login fallido consulta al repositorio y emite AuthLoading y AuthError',
          () async {
        when(
              () => mockAuthRepository.login('test@test.com', 'wrong-password'),
        ).thenAnswer(
              (_) async => const Left(
            AuthFailure(message: 'Correo o contraseña incorrectos'),
          ),
        );

        authBloc.add(
          const LoginRequested(
            email: 'test@test.com',
            password: 'wrong-password',
          ),
        );

        await expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            const AuthError('Correo o contraseña incorrectos'),
          ]),
        );

        verify(
              () => mockAuthRepository.login('test@test.com', 'wrong-password'),
        ).called(1);
      },
    );

    test(
      'restore session sin usuario consulta al repositorio y emite AuthLoading y AuthInitial',
          () async {
        when(
              () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);

        authBloc.add(const RestoreSession());

        await expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            const AuthInitial(),
          ]),
        );

        verify(() => mockAuthRepository.getCurrentUser()).called(1);
      },
    );

    test(
      'restore session con usuario consulta al repositorio y emite AuthLoading y AuthSuccess',
          () async {
        final user = AppUser(
          id: '123',
          email: 'test@test.com',
          role: 'customer',
        );

        when(
              () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => user);

        authBloc.add(const RestoreSession());

        await expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            const AuthSuccess(userId: '123', role: 'customer'),
          ]),
        );

        verify(() => mockAuthRepository.getCurrentUser()).called(1);
      },
    );

    test(
      'logout exitoso consulta al repositorio y emite AuthLoading y AuthInitial',
          () async {
        when(
              () => mockAuthRepository.logout(),
        ).thenAnswer((_) async => const Right(unit));

        authBloc.add(const LogoutRequested());

        await expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            const AuthInitial(),
          ]),
        );

        verify(() => mockAuthRepository.logout()).called(1);
      },
    );

    test(
      'register exitoso consulta al repositorio y emite AuthLoading y AuthSuccess',
          () async {
        final user = AppUser(
          id: '123',
          email: 'new@test.com',
          role: 'customer',
        );

        when(
              () => mockAuthRepository.register('new@test.com', '123456'),
        ).thenAnswer((_) async => Right(user));

        authBloc.add(
          const RegisterRequested(email: 'new@test.com', password: '123456'),
        );

        await expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            const AuthSuccess(userId: '123', role: 'customer'),
          ]),
        );

        verify(
              () => mockAuthRepository.register('new@test.com', '123456'),
        ).called(1);
      },
    );
  });
}