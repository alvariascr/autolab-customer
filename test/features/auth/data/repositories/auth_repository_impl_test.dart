import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:autolab_customer/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class MockAppLogger extends Mock implements AppLogger {}

class FakeAuthResponse extends Fake implements AuthResponse {}

class FakeUser extends Fake implements User {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthResponse());
    registerFallbackValue(FakeUser());
  });

  group('AuthRepositoryImpl', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockGlobalErrorHandler mockGlobalErrorHandler;
    late MockAppLogger mockAppLogger;
    late AuthRepositoryImpl repository;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockGlobalErrorHandler = MockGlobalErrorHandler();
      mockAppLogger = MockAppLogger();

      when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      when(() => mockGlobalErrorHandler.logger).thenReturn(mockAppLogger);

      when(() => mockAppLogger.w(any())).thenReturn(null);
      when(
            () => mockAppLogger.w(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);

      when(
            () => mockGlobalErrorHandler.handle(any(), any()),
      ).thenReturn(const UnknownFailure());

      repository = AuthRepositoryImpl(
        mockSupabaseClient,
        mockGlobalErrorHandler,
      );
    });

    test(
      'login retorna Right(AppUser) cuando signInWithPassword es exitoso',
          () async {
        final user = User(
          id: 'user-123',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'test@test.com',
        );

        final authResponse = AuthResponse(
          session: null,
          user: user,
        );

        when(
              () => mockGoTrueClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => authResponse);

        final result = await repository.login('test@test.com', '123456');

        expect(result.isRight(), true);

        result.fold((_) => fail('Se esperaba Right(AppUser)'), (appUser) {
          expect(appUser, isA<AppUser>());
          expect(appUser.id, 'user-123');
          expect(appUser.email, 'test@test.com');
        });

        verify(
              () => mockGoTrueClient.signInWithPassword(
            email: 'test@test.com',
            password: '123456',
          ),
        ).called(1);
      },
    );

    test('login retorna Left cuando user es null', () async {
      final authResponse = AuthResponse(
        session: null,
        user: null,
      );

      when(
            () => mockGoTrueClient.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => authResponse);

      final result = await repository.login('test@test.com', '123456');

      expect(result.isLeft(), true);

      result.fold((failure) {
        expect(failure, isA<Failure>());
        expect(failure.message, 'Respuesta inválida: usuario no disponible');
      }, (_) => fail('Se esperaba Left(Failure)'));

      verify(() => mockAppLogger.w(any())).called(1);
    });

    test(
      'login retorna Left cuando credenciales son inválidas',
          () async {
        when(
              () => mockGoTrueClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Invalid login credentials'));

        final result = await repository.login('test@test.com', 'bad-password');

        expect(result.isLeft(), true);

        result.fold((failure) {
          expect(failure, isA<Failure>());
          expect(failure.message, 'Correo o contraseña incorrectos');
        }, (_) => fail('Se esperaba Left(Failure)'));

        verify(
              () => mockAppLogger.w(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      },
    );

    test('login usa GlobalErrorHandler para errores no controlados', () async {
      final exception = Exception('random error');
      final mappedFailure = UnknownFailure(
        message: 'Ocurrió un error inesperado',
        cause: exception,
      );

      when(
            () => mockGoTrueClient.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(exception);

      when(
            () => mockGlobalErrorHandler.handle(any(), any()),
      ).thenReturn(mappedFailure);

      final result = await repository.login('test@test.com', '123456');

      expect(result.isLeft(), true);

      result.fold((failure) {
        expect(failure, mappedFailure);
      }, (_) => fail('Se esperaba Left(Failure)'));

      verify(() => mockGlobalErrorHandler.handle(exception, any())).called(1);
    });

    test('logout retorna Right(unit) cuando signOut es exitoso', () async {
      when(() => mockGoTrueClient.signOut()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right(unit));

      verify(() => mockGoTrueClient.signOut()).called(1);
    });

    test('register retorna Right(AppUser) cuando signUp es exitoso', () async {
      final user = User(
        id: 'user-456',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'new@test.com',
      );

      final authResponse = AuthResponse(
        session: null,
        user: user,
      );

      when(
            () => mockGoTrueClient.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => authResponse);

      final result = await repository.register(
        'Luis',
        'new@test.com',
        '88888888',
        '123456',
      );

      expect(result.isRight(), true);

      result.fold((_) => fail('Se esperaba Right(AppUser)'), (appUser) {
        expect(appUser.id, 'user-456');
        expect(appUser.email, 'new@test.com');
      });
    });
  });
}