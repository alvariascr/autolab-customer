import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class MockAppLogger extends Mock implements AppLogger {}

class MockSessionLocalDataSource extends Mock
    implements SessionLocalDataSource {}

class MockSession extends Mock implements Session {}

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
    late MockSessionLocalDataSource mockSessionLocalDataSource;
    late MockSession mockSession;
    late AuthRepositoryImpl repository;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockGlobalErrorHandler = MockGlobalErrorHandler();
      mockAppLogger = MockAppLogger();
      mockSessionLocalDataSource = MockSessionLocalDataSource();
      mockSession = MockSession();

      when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      when(() => mockGlobalErrorHandler.logger).thenReturn(mockAppLogger);

      when(() => mockAppLogger.w(any())).thenReturn(null);
      when(() => mockAppLogger.i(any())).thenReturn(null);
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

      when(() => mockSessionLocalDataSource.saveAccessToken(any()))
          .thenAnswer((_) async {});
      when(() => mockSessionLocalDataSource.saveRefreshToken(any()))
          .thenAnswer((_) async {});
      when(() => mockSessionLocalDataSource.saveUserSession(any()))
          .thenAnswer((_) async {});
      when(() => mockSessionLocalDataSource.clearSession())
          .thenAnswer((_) async {});
      when(() => mockSessionLocalDataSource.getUserSession())
          .thenAnswer((_) async => null);

      when(() => mockSession.accessToken).thenReturn('access-token-123');
      when(() => mockSession.refreshToken).thenReturn('refresh-token-123');

      repository = AuthRepositoryImpl(
        mockSupabaseClient,
        mockGlobalErrorHandler,
        mockSessionLocalDataSource,
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

        final authResponse = AuthResponse(session: mockSession, user: user);

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

        verify(() => mockSessionLocalDataSource.saveAccessToken('access-token-123'))
            .called(1);
        verify(
              () => mockSessionLocalDataSource.saveRefreshToken(
            'refresh-token-123',
          ),
        ).called(1);
        verify(() => mockSessionLocalDataSource.saveUserSession(any()))
            .called(1);
      },
    );

    test(
      'login retorna Left(AuthFailure) cuando user o session son null',
          () async {
        final authResponse = AuthResponse(session: null, user: null);

        when(
              () => mockGoTrueClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => authResponse);

        final result = await repository.login('test@test.com', '123456');

        expect(result.isLeft(), true);

        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(
            failure.message,
            'Respuesta inválida: usuario o sesión no disponible',
          );
        }, (_) => fail('Se esperaba Left(Failure)'));

        verify(() => mockAppLogger.w(any())).called(1);
      },
    );

    test(
      'login retorna Left(AuthFailure) cuando credenciales son inválidas',
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
          expect(failure, isA<AuthFailure>());
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
      verify(() => mockSessionLocalDataSource.clearSession()).called(1);
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

      final authResponse = AuthResponse(session: null, user: user);

      when(
            () => mockGoTrueClient.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => authResponse);

      final result = await repository.register('new@test.com', '123456');

      expect(result.isRight(), true);

      result.fold((_) => fail('Se esperaba Right(AppUser)'), (appUser) {
        expect(appUser.id, 'user-456');
        expect(appUser.email, 'new@test.com');
      });
    });
  });
}