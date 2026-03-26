import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/data/datasources/user_role_data_source.dart';
import 'package:autolab_customer/features/auth/data/models/login_attempt_state.dart';
import 'package:autolab_customer/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:autolab_customer/features/auth/data/services/login_attempt_service.dart';
import 'package:autolab_customer/features/auth/domain/constants/user_roles.dart';
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

class MockUserRoleDataSource extends Mock implements UserRoleDataSource {}

class MockLoginAttemptService extends Mock implements LoginAttemptService {}

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
    late MockUserRoleDataSource mockUserRoleDataSource;
    late MockLoginAttemptService mockLoginAttemptService;
    late MockSession mockSession;
    late AuthRepositoryImpl repository;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockGlobalErrorHandler = MockGlobalErrorHandler();
      mockAppLogger = MockAppLogger();
      mockSessionLocalDataSource = MockSessionLocalDataSource();
      mockUserRoleDataSource = MockUserRoleDataSource();
      mockLoginAttemptService = MockLoginAttemptService();
      mockSession = MockSession();

      when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      when(() => mockGlobalErrorHandler.logger).thenReturn(mockAppLogger);

      when(() => mockAppLogger.i(any())).thenReturn(null);
      when(() => mockAppLogger.w(any())).thenReturn(null);
      when(() => mockAppLogger.e(any())).thenReturn(null);

      when(
            () => mockAppLogger.w(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);

      when(
            () => mockAppLogger.e(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);

      when(
            () => mockGlobalErrorHandler.handle(any(), any()),
      ).thenReturn(const UnknownFailure(message: 'Unexpected error'));

      when(
            () => mockSessionLocalDataSource.saveAccessToken(any()),
      ).thenAnswer((_) async {});
      when(
            () => mockSessionLocalDataSource.saveRefreshToken(any()),
      ).thenAnswer((_) async {});
      when(
            () => mockSessionLocalDataSource.saveUserSession(any()),
      ).thenAnswer((_) async {});
      when(
            () => mockSessionLocalDataSource.clearSession(),
      ).thenAnswer((_) async {});
      when(
            () => mockSessionLocalDataSource.getUserSession(),
      ).thenAnswer((_) async => null);

      when(
            () => mockUserRoleDataSource.getUserRole(any()),
      ).thenAnswer((_) async => UserRoles.customer);

      when(() => mockSession.accessToken).thenReturn('access-token-123');
      when(() => mockSession.refreshToken).thenReturn('refresh-token-123');

      when(
            () => mockLoginAttemptService.getState(any()),
      ).thenAnswer((_) async => LoginAttemptState.initial());

      when(
            () => mockLoginAttemptService.registerSuccess(any()),
      ).thenAnswer((_) async {});

      when(
            () => mockLoginAttemptService.registerFailure(any()),
      ).thenAnswer((_) async => LoginAttemptState.initial());

      repository = AuthRepositoryImpl(
        mockSupabaseClient,
        mockGlobalErrorHandler,
        mockSessionLocalDataSource,
        mockUserRoleDataSource,
        mockLoginAttemptService,
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
          expect(appUser.role, UserRoles.customer);
        });
      },
    );

    test('login retorna Left cuando user o session es null', () async {
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
      }, (_) => fail('Se esperaba Left(Failure)'));
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
      },
    );

    test('logout retorna Right(unit) cuando signOut es exitoso', () async {
      when(() => mockGoTrueClient.signOut()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right(unit));
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
            () => mockGoTrueClient.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

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
        expect(appUser.role, UserRoles.customer);
      });
    });
  });
}