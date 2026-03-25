import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/data/datasources/user_role_data_source.dart';
import 'package:autolab_customer/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:autolab_customer/features/auth/data/services/login_attempt_service.dart';
import 'package:autolab_customer/features/auth/domain/constants/user_roles.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/data/models/login_attempt_state.dart';
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
      ).thenReturn(
        const UnknownFailure(
          message: 'Ocurrió un error inesperado.',
        ),
      );

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

      when(
            () => mockLoginAttemptService.getState(any()),
      ).thenAnswer((_) async => LoginAttemptState.initial());

      when(
            () => mockLoginAttemptService.registerSuccess(any()),
      ).thenAnswer((_) async {});

      when(
            () => mockLoginAttemptService.registerFailure(any()),
      ).thenAnswer(
            (_) async => const LoginAttemptState(
          failedAttempts: 1,
          lockLevel: 0,
          blockedUntil: null,
        ),
      );

      when(() => mockSession.accessToken).thenReturn('access-token-123');
      when(() => mockSession.refreshToken).thenReturn('refresh-token-123');

      repository = AuthRepositoryImpl(
        mockSupabaseClient,
        mockGlobalErrorHandler,
        mockSessionLocalDataSource,
        mockUserRoleDataSource,
        mockLoginAttemptService,
      );
    });

    test(
      'login returns Right(AppUser), resolves role, and persists session with role',
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

        result.fold((_) => fail('Expected Right(AppUser)'), (appUser) {
          expect(appUser, isA<AppUser>());
          expect(appUser.id, 'user-123');
          expect(appUser.email, 'test@test.com');
          expect(appUser.role, UserRoles.customer);
        });

        verify(
              () => mockGoTrueClient.signInWithPassword(
            email: 'test@test.com',
            password: '123456',
          ),
        ).called(1);

        verify(() => mockLoginAttemptService.getState('test@test.com')).called(1);
        verify(() => mockUserRoleDataSource.getUserRole('user-123')).called(1);

        verify(
              () => mockSessionLocalDataSource.saveAccessToken('access-token-123'),
        ).called(1);

        verify(
              () => mockSessionLocalDataSource.saveRefreshToken(
            'refresh-token-123',
          ),
        ).called(1);

        verify(
              () => mockLoginAttemptService.registerSuccess('test@test.com'),
        ).called(1);

        final captured = verify(
              () => mockSessionLocalDataSource.saveUserSession(captureAny()),
        ).captured.single as String;

        expect(captured, contains('"role":"customer"'));
      },
    );

    test(
      'login returns Left(AuthFailure) when user or session is null',
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
          expect(failure.message, ErrorCatalog.invalidAuthResponse.message);
          expect(failure.code, ErrorCatalog.invalidAuthResponse.code);
        }, (_) => fail('Expected Left(Failure)'));

        verify(() => mockAppLogger.w(any())).called(1);
      },
    );

    test(
      'login returns Left(AuthFailure) when credentials are invalid',
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
          expect(failure.message, ErrorCatalog.invalidCredentials.message);
          expect(failure.code, ErrorCatalog.invalidCredentials.code);
        }, (_) => fail('Expected Left(Failure)'));

        verify(() => mockLoginAttemptService.getState('test@test.com')).called(1);
        verify(
              () => mockLoginAttemptService.registerFailure('test@test.com'),
        ).called(1);

        verify(
              () => mockAppLogger.w(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      },
    );

    test('login uses GlobalErrorHandler for unexpected errors', () async {
      final exception = Exception('random error');
      final mappedFailure = UnknownFailure(
        message: ErrorCatalog.unknownError.message,
        code: ErrorCatalog.unknownError.code,
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
      }, (_) => fail('Expected Left(Failure)'));

      verify(() => mockLoginAttemptService.getState('test@test.com')).called(1);
      verify(() => mockGlobalErrorHandler.handle(exception, any())).called(1);
    });

    test('logout returns Right(unit) when signOut succeeds', () async {
      when(() => mockGoTrueClient.signOut()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right(unit));

      verify(() => mockGoTrueClient.signOut()).called(1);
      verify(() => mockSessionLocalDataSource.clearSession()).called(1);
    });

    test('register returns Right(AppUser) when signUp succeeds', () async {
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

      result.fold((_) => fail('Expected Right(AppUser)'), (appUser) {
        expect(appUser.id, 'user-456');
        expect(appUser.email, 'new@test.com');
        expect(appUser.role, UserRoles.customer);
      });
    });

    test(
      'getCurrentUser returns Supabase user and syncs local session when role lookup succeeds',
          () async {
        final user = User(
          id: 'user-123',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'test@test.com',
        );

        when(() => mockGoTrueClient.currentUser).thenReturn(user);
        when(
              () => mockUserRoleDataSource.getUserRole('user-123'),
        ).thenAnswer((_) async => UserRoles.customer);

        final result = await repository.getCurrentUser();

        expect(result, isNotNull);
        expect(result!.id, 'user-123');
        expect(result.email, 'test@test.com');
        expect(result.role, UserRoles.customer);

        final captured = verify(
              () => mockSessionLocalDataSource.saveUserSession(captureAny()),
        ).captured.single as String;

        expect(captured, contains('"id":"user-123"'));
        expect(captured, contains('"role":"customer"'));
      },
    );

    test(
      'getCurrentUser returns local session when role lookup fails and local session matches Supabase user',
          () async {
        final user = User(
          id: 'user-123',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'test@test.com',
        );

        when(() => mockGoTrueClient.currentUser).thenReturn(user);
        when(
              () => mockUserRoleDataSource.getUserRole('user-123'),
        ).thenThrow(Exception('network error'));

        when(
              () => mockSessionLocalDataSource.getUserSession(),
        ).thenAnswer(
              (_) async =>
          '{"id":"user-123","email":"test@test.com","role":"customer"}',
        );

        final result = await repository.getCurrentUser();

        expect(result, isNotNull);
        expect(result!.id, 'user-123');
        expect(result.email, 'test@test.com');
        expect(result.role, UserRoles.customer);
      },
    );

    test(
      'getCurrentUser returns null when role lookup fails and local session belongs to a different user',
          () async {
        final user = User(
          id: 'user-123',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'test@test.com',
        );

        when(() => mockGoTrueClient.currentUser).thenReturn(user);
        when(
              () => mockUserRoleDataSource.getUserRole('user-123'),
        ).thenThrow(Exception('network error'));

        when(
              () => mockSessionLocalDataSource.getUserSession(),
        ).thenAnswer(
              (_) async =>
          '{"id":"other-user","email":"other@test.com","role":"customer"}',
        );

        final result = await repository.getCurrentUser();

        expect(result, isNull);
      },
    );

    test(
      'getCurrentUser returns local session when there is no Supabase user',
          () async {
        when(() => mockGoTrueClient.currentUser).thenReturn(null);
        when(
              () => mockSessionLocalDataSource.getUserSession(),
        ).thenAnswer(
              (_) async =>
          '{"id":"user-999","email":"offline@test.com","role":"customer"}',
        );

        final result = await repository.getCurrentUser();

        expect(result, isNotNull);
        expect(result!.id, 'user-999');
        expect(result.email, 'offline@test.com');
        expect(result.role, UserRoles.customer);
      },
    );
  });
}