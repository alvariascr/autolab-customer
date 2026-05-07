import 'dart:convert';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/auth/data/datasources/session_local_data_source.dart';
import 'package:autolab_customer/features/auth/data/datasources/user_role_data_source.dart';
import 'package:autolab_customer/features/auth/data/mappers/auth_exception_mapper.dart';
import 'package:autolab_customer/features/auth/data/models/login_attempt_state.dart';
import 'package:autolab_customer/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:autolab_customer/features/auth/data/services/auth_local_session_recovery_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_login_policy_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_session_recovery_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_session_storage_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_supabase_session_sync_service.dart';
import 'package:autolab_customer/features/auth/data/services/login_attempt_service.dart';
import 'package:autolab_customer/features/auth/domain/constants/user_roles.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:autolab_customer/features/auth/domain/failures/auth_rate_limit_failure.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class _SupabaseAuthCodes {
  static const invalidCredentials = 'invalid_credentials';
  static const noAuthorization = 'no_authorization';
  static const emailNotConfirmed = 'email_not_confirmed';
  static const userAlreadyExists = 'user_already_exists';
  static const requestTimeout = 'request_timeout';
}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class MockAppLogger extends Mock implements AppLogger {}

class MockFeatureLogger extends Mock implements FeatureLogger {}

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
    late MockFeatureLogger mockFeatureLogger;
    late MockSessionLocalDataSource mockSessionLocalDataSource;
    late MockUserRoleDataSource mockUserRoleDataSource;
    late MockLoginAttemptService mockLoginAttemptService;
    late MockSession mockSession;
    late AuthLoginPolicyService authLoginPolicyService;
    late AuthSupabaseSessionSyncService authSupabaseSessionSyncService;
    late AuthLocalSessionRecoveryService authLocalSessionRecoveryService;
    late AuthSessionStorageService sessionStorageService;
    late AuthSessionRecoveryService sessionRecoveryService;
    late AuthRepositoryImpl repository;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockGlobalErrorHandler = MockGlobalErrorHandler();
      mockAppLogger = MockAppLogger();
      mockFeatureLogger = MockFeatureLogger();
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
        () => mockFeatureLogger.info(
          feature: any(named: 'feature'),
          action: any(named: 'action'),
          code: any(named: 'code'),
          context: any(named: 'context'),
        ),
      ).thenReturn(null);
      when(
        () => mockFeatureLogger.warn(
          feature: any(named: 'feature'),
          action: any(named: 'action'),
          code: any(named: 'code'),
          context: any(named: 'context'),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);
      when(
        () => mockFeatureLogger.error(
          feature: any(named: 'feature'),
          action: any(named: 'action'),
          code: any(named: 'code'),
          context: any(named: 'context'),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);

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

      when(() => mockGlobalErrorHandler.handle(any(), any())).thenReturn(
        const UnknownFailure(message: 'Ocurrió un error inesperado.'),
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
        () => mockSessionLocalDataSource.getRefreshToken(),
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

      when(() => mockLoginAttemptService.registerFailure(any())).thenAnswer(
        (_) async => const LoginAttemptState(
          failedAttempts: 1,
          lockLevel: 0,
          blockedUntil: null,
        ),
      );

      when(() => mockSession.accessToken).thenReturn('access-token-123');
      when(() => mockSession.refreshToken).thenReturn('refresh-token-123');

      sessionStorageService = AuthSessionStorageService(
        mockSessionLocalDataSource,
      );
      authSupabaseSessionSyncService = AuthSupabaseSessionSyncService(
        sessionStorageService: sessionStorageService,
        userRoleDataSource: mockUserRoleDataSource,
        featureLogger: mockFeatureLogger,
      );
      authLocalSessionRecoveryService = AuthLocalSessionRecoveryService(
        sessionStorageService: sessionStorageService,
        featureLogger: mockFeatureLogger,
      );
      sessionRecoveryService = AuthSessionRecoveryService(
        client: mockSupabaseClient,
        sessionStorageService: sessionStorageService,
        supabaseSessionSyncService: authSupabaseSessionSyncService,
        localSessionRecoveryService: authLocalSessionRecoveryService,
        featureLogger: mockFeatureLogger,
      );
      authLoginPolicyService = AuthLoginPolicyService(mockLoginAttemptService);

      repository = AuthRepositoryImpl(
        mockSupabaseClient,
        mockGlobalErrorHandler,
        mockUserRoleDataSource,
        authLoginPolicyService,
        sessionStorageService,
        sessionRecoveryService,
        mockFeatureLogger,
        const AuthExceptionMapper(),
      );
    });

    group('login', () {
      test(
        'retorna Right(AppUser) cuando signInWithPassword es exitoso',
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

          verify(
            () => mockGoTrueClient.signInWithPassword(
              email: 'test@test.com',
              password: '123456',
            ),
          ).called(1);

          verify(
            () => mockLoginAttemptService.getState('test@test.com'),
          ).called(1);
          verify(
            () => mockUserRoleDataSource.getUserRole('user-123'),
          ).called(1);

          verify(
            () =>
                mockSessionLocalDataSource.saveAccessToken('access-token-123'),
          ).called(1);

          verify(
            () => mockSessionLocalDataSource.saveRefreshToken(
              'refresh-token-123',
            ),
          ).called(1);

          verify(
            () => mockLoginAttemptService.registerSuccess('test@test.com'),
          ).called(1);

          final captured =
              verify(
                    () => mockSessionLocalDataSource.saveUserSession(
                      captureAny(),
                    ),
                  ).captured.single
                  as String;

          expect(captured, contains('"role":"customer"'));
        },
      );

      test('retorna Left cuando user es null', () async {
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
          expect(failure.message, AuthErrorCatalog.invalidAuthResponse.code);
          expect(failure.code, AuthErrorCatalog.invalidAuthResponse.code);
          expect(failure.uiKey, AuthErrorCatalog.invalidAuthResponse.uiKey);
        }, (_) => fail('Expected Left(Failure)'));

        verify(
          () => mockFeatureLogger.warn(
            feature: 'auth',
            action: 'domain_warning',
            code: AuthErrorCatalog.invalidAuthResponse.code,
            context: {'uiKey': AuthErrorCatalog.invalidAuthResponse.uiKey},
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      });

      test('retorna Left cuando credenciales son inválidas', () async {
        final authException = AuthApiException(
          'Invalid login credentials',
          statusCode: '400',
        );

        when(
          () => mockGoTrueClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(authException);

        when(
          () => mockLoginAttemptService.registerFailure('test@test.com'),
        ).thenAnswer(
          (_) async => const LoginAttemptState(
            failedAttempts: 1,
            lockLevel: 0,
            blockedUntil: null,
          ),
        );

        final result = await repository.login('test@test.com', 'bad-password');

        expect(result.isLeft(), true);

        result.fold((failure) {
          expect(failure, isA<Failure>());
          expect(failure.message, AuthErrorCatalog.invalidCredentials.code);
          expect(failure.code, AuthErrorCatalog.invalidCredentials.code);
          expect(failure.uiKey, AuthErrorCatalog.invalidCredentials.uiKey);
        }, (_) => fail('Se esperaba Left(Failure)'));
      });

      test(
        'retorna Left cuando Supabase expone invalid_credentials como code explícito',
        () async {
          final authException = AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: _SupabaseAuthCodes.invalidCredentials,
          );

          when(
            () => mockGoTrueClient.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(authException);

          when(
            () => mockLoginAttemptService.registerFailure('test@test.com'),
          ).thenAnswer(
            (_) async => const LoginAttemptState(
              failedAttempts: 1,
              lockLevel: 0,
              blockedUntil: null,
            ),
          );

          final result = await repository.login(
            'test@test.com',
            'bad-password',
          );

          expect(result.isLeft(), true);

          result.fold((failure) {
            expect(failure, isA<Failure>());
            expect(failure.code, AuthErrorCatalog.invalidCredentials.code);
            expect(failure.uiKey, AuthErrorCatalog.invalidCredentials.uiKey);
          }, (_) => fail('Se esperaba Left(Failure)'));

          verifyNever(
            () => mockGlobalErrorHandler.handle(authException, any()),
          );
        },
      );

      test('retorna Left cuando el correo no ha sido confirmado', () async {
        final authException = AuthApiException(
          'Email not confirmed',
          statusCode: '400',
          code: _SupabaseAuthCodes.emailNotConfirmed,
        );

        when(
          () => mockGoTrueClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(authException);

        final result = await repository.login('test@test.com', '123456');

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure.message, AuthErrorCatalog.unconfirmedEmail.code);
          expect(failure.code, AuthErrorCatalog.unconfirmedEmail.code);
          expect(failure.uiKey, AuthErrorCatalog.unconfirmedEmail.uiKey);
        }, (_) => fail('Debería ser Left'));
        verify(
          () => mockFeatureLogger.warn(
            feature: 'auth',
            action: 'login_auth_exception_mapped',
            code: AuthErrorCatalog.unconfirmedEmail.code,
            context: any(named: 'context'),
            error: authException,
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      });

      test('retorna Left cuando Supabase expone no_authorization', () async {
        final authException = AuthApiException(
          'Unauthorized',
          statusCode: '401',
          code: _SupabaseAuthCodes.noAuthorization,
        );

        when(
          () => mockGoTrueClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(authException);

        final result = await repository.login('test@test.com', '123456');

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure.code, AuthErrorCatalog.unauthorized.code);
          expect(failure.uiKey, AuthErrorCatalog.unauthorized.uiKey);
        }, (_) => fail('Debería ser Left'));

        verifyNever(() => mockGlobalErrorHandler.handle(authException, any()));
      });

      test(
        'retorna Left(NetworkFailure) cuando Supabase devuelve un error de red',
        () async {
          final authException = AuthRetryableFetchException(
            message: 'network failed',
          );

          when(
            () => mockGoTrueClient.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(authException);

          final result = await repository.login('test@test.com', '123456');

          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.code, ErrorCatalog.networkUnavailable.code);
            expect(failure.uiKey, ErrorCatalog.networkUnavailable.uiKey);
          }, (_) => fail('Debería ser Left'));

          verifyNever(
            () => mockGlobalErrorHandler.handle(authException, any()),
          );
        },
      );

      test(
        'retorna Left(TimeoutFailure-like) cuando Supabase devuelve timeout en auth',
        () async {
          final authException = AuthApiException(
            'Request timed out',
            statusCode: '504',
            code: _SupabaseAuthCodes.requestTimeout,
          );

          when(
            () => mockGoTrueClient.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(authException);

          final result = await repository.login('test@test.com', '123456');

          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<TimeoutFailure>());
            expect(failure.code, ErrorCatalog.requestTimeout.code);
            expect(failure.uiKey, ErrorCatalog.requestTimeout.uiKey);
          }, (_) => fail('Debería ser Left'));

          verifyNever(
            () => mockGlobalErrorHandler.handle(authException, any()),
          );
        },
      );

      test('uses GlobalErrorHandler for unexpected errors', () async {
        final exception = Exception('random error');
        final mappedFailure = UnknownFailure(
          message: ErrorCatalog.unknownError.code,
          code: ErrorCatalog.unknownError.code,
          uiKey: ErrorCatalog.unknownError.uiKey,
          cause: exception,
        );

        when(
          () => mockGoTrueClient.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(exception);

        when(
          () => mockGlobalErrorHandler.handle(exception, any()),
        ).thenReturn(mappedFailure);

        final result = await repository.login('test@test.com', '123456');

        expect(result.isLeft(), true);

        result.fold((failure) {
          expect(failure, mappedFailure);
        }, (_) => fail('Expected Left(Failure)'));

        verify(
          () => mockLoginAttemptService.getState('test@test.com'),
        ).called(1);
        verify(() => mockGlobalErrorHandler.handle(exception, any())).called(1);
      });

      test(
        'returns Left(AuthRateLimitFailure) when invalid credentials trigger block',
        () async {
          final authException = AuthApiException(
            'Invalid login credentials',
            statusCode: '401',
          );

          when(
            () => mockGoTrueClient.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(authException);

          when(
            () => mockLoginAttemptService.registerFailure('test@test.com'),
          ).thenAnswer(
            (_) async => LoginAttemptState(
              failedAttempts: 5,
              lockLevel: 1,
              blockedUntil: DateTime.now().add(const Duration(minutes: 5)),
            ),
          );

          final result = await repository.login(
            'test@test.com',
            'bad-password',
          );

          expect(result.isLeft(), true);

          result.fold((failure) {
            expect(failure, isA<AuthRateLimitFailure>());
            expect(failure.code, AuthErrorCatalog.authRateLimit.code);
          }, (_) => fail('Expected Left(Failure)'));
        },
      );
    });

    group('logout', () {
      test('returns Right(unit) when signOut succeeds', () async {
        when(() => mockGoTrueClient.signOut()).thenAnswer((_) async {});
        when(
          () => mockSessionLocalDataSource.clearSession(),
        ).thenAnswer((_) async {});

        final result = await repository.logout();

        expect(result, const Right(unit));
        verify(() => mockGoTrueClient.signOut()).called(1);
        verify(() => mockSessionLocalDataSource.clearSession()).called(1);
      });

      test('returns Left(Failure) when signOut fails', () async {
        final exception = Exception('signout error');
        final mappedFailure = UnknownFailure(
          message: ErrorCatalog.unknownError.code,
          code: ErrorCatalog.unknownError.code,
          uiKey: ErrorCatalog.unknownError.uiKey,
          cause: exception,
        );

        when(() => mockGoTrueClient.signOut()).thenThrow(exception);
        when(
          () => mockGlobalErrorHandler.handle(exception, any()),
        ).thenReturn(mappedFailure);

        final result = await repository.logout();

        expect(result.isLeft(), true);

        result.fold((failure) {
          expect(failure, mappedFailure);
        }, (_) => fail('Expected Left(Failure)'));

        verify(() => mockGlobalErrorHandler.handle(exception, any())).called(1);
        verifyNever(() => mockSessionLocalDataSource.clearSession());
      });
    });

    group('register', () {
      test('returns Right(AppUser) when signUp succeeds', () async {
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
            emailRedirectTo: any(named: 'emailRedirectTo'),
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

        verify(
          () => mockGoTrueClient.signUp(
            email: 'new@test.com',
            password: '123456',
            emailRedirectTo: 'autolab://login-callback/email-confirmed',
            data: {
              'name': 'Luis',
              'phone': '88888888',
              'role': UserRoles.customer,
            },
          ),
        ).called(1);
      });

      test(
        'returns Left when signUp returns an obfuscated existing user',
        () async {
          final user = User(
            id: 'fake-user',
            appMetadata: const {},
            userMetadata: const {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
            email: 'existing@test.com',
            identities: const [],
          );

          final authResponse = AuthResponse(session: null, user: user);

          when(
            () => mockGoTrueClient.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              emailRedirectTo: any(named: 'emailRedirectTo'),
              data: any(named: 'data'),
            ),
          ).thenAnswer((_) async => authResponse);

          final result = await repository.register(
            'Luis',
            'existing@test.com',
            '88888888',
            '123456',
          );

          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(
              failure.message,
              AuthErrorCatalog.emailAlreadyRegistered.code,
            );
            expect(failure.code, AuthErrorCatalog.emailAlreadyRegistered.code);
            expect(
              failure.uiKey,
              AuthErrorCatalog.emailAlreadyRegistered.uiKey,
            );
          }, (_) => fail('Debería ser Left'));
          verifyNever(() => mockGoTrueClient.signOut());
          verifyNever(() => mockGlobalErrorHandler.handle(any(), any()));
        },
      );

      test(
        'returns Left when signUp reports account exists but not confirmed',
        () async {
          final authException = AuthApiException(
            'Email not confirmed',
            statusCode: '400',
            code: _SupabaseAuthCodes.emailNotConfirmed,
          );

          when(
            () => mockGoTrueClient.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              emailRedirectTo: any(named: 'emailRedirectTo'),
              data: any(named: 'data'),
            ),
          ).thenThrow(authException);

          final result = await repository.register(
            'Luis',
            'existing@test.com',
            '88888888',
            '123456',
          );

          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(
              failure.message,
              AuthErrorCatalog.emailNotConfirmedRegister.code,
            );
            expect(
              failure.code,
              AuthErrorCatalog.emailNotConfirmedRegister.code,
            );
            expect(
              failure.uiKey,
              AuthErrorCatalog.emailNotConfirmedRegister.uiKey,
            );
          }, (_) => fail('Debería ser Left'));
        },
      );

      test('returns Left(AuthFailure) when signUp user is null', () async {
        final authResponse = AuthResponse(session: null, user: null);

        when(
          () => mockGoTrueClient.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => authResponse);

        final result = await repository.register(
          'Luis',
          'new@test.com',
          '88888888',
          '123456',
        );

        expect(result.isLeft(), true);

        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(
            failure.message,
            AuthErrorCatalog.invalidRegisterResponse.code,
          );
          expect(failure.code, AuthErrorCatalog.invalidRegisterResponse.code);
          expect(failure.uiKey, AuthErrorCatalog.invalidRegisterResponse.uiKey);
        }, (_) => fail('Expected Left(Failure)'));

        verify(
          () => mockFeatureLogger.warn(
            feature: 'auth',
            action: 'domain_warning',
            code: AuthErrorCatalog.invalidRegisterResponse.code,
            context: {'uiKey': AuthErrorCatalog.invalidRegisterResponse.uiKey},
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      });

      test(
        'returns Left when email already registered (signUp exception)',
        () async {
          final authException = AuthApiException(
            'User already registered',
            statusCode: '400',
            code: _SupabaseAuthCodes.userAlreadyExists,
          );

          when(
            () => mockGoTrueClient.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              emailRedirectTo: any(named: 'emailRedirectTo'),
              data: any(named: 'data'),
            ),
          ).thenThrow(authException);

          final result = await repository.register(
            'Luis',
            'new@test.com',
            '88888888',
            '123456',
          );

          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(
              failure.message,
              AuthErrorCatalog.emailAlreadyRegistered.code,
            );
            expect(failure.code, AuthErrorCatalog.emailAlreadyRegistered.code);
            expect(
              failure.uiKey,
              AuthErrorCatalog.emailAlreadyRegistered.uiKey,
            );
          }, (_) => fail('Debería ser Left'));
        },
      );

      test('uses GlobalErrorHandler for unexpected errors', () async {
        final exception = Exception('signup error');
        final mappedFailure = UnknownFailure(
          message: ErrorCatalog.unknownError.code,
          code: ErrorCatalog.unknownError.code,
          uiKey: ErrorCatalog.unknownError.uiKey,
          cause: exception,
        );

        when(
          () => mockGoTrueClient.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
            data: any(named: 'data'),
          ),
        ).thenThrow(exception);

        when(
          () => mockGlobalErrorHandler.handle(exception, any()),
        ).thenReturn(mappedFailure);

        final result = await repository.register(
          'Luis',
          'new@test.com',
          '88888888',
          '123456',
        );

        expect(result.isLeft(), true);

        result.fold((failure) {
          expect(failure, mappedFailure);
        }, (_) => fail('Expected Left(Failure)'));

        verify(() => mockGlobalErrorHandler.handle(exception, any())).called(1);
      });
    });

    group('getCurrentUser', () {
      test(
        'returns Supabase user and syncs local session when role lookup succeeds',
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

          expect(result.isRight(), true);
          result.fold((_) => fail('Expected Right(AppUser?)'), (user) {
            expect(user, isNotNull);
            expect(user!.id, 'user-123');
            expect(user.email, 'test@test.com');
            expect(user.role, UserRoles.customer);
          });

          verify(
            () => mockSessionLocalDataSource.saveUserSession(captureAny()),
          ).called(1);
          verify(
            () => mockFeatureLogger.info(
              feature: 'auth',
              action: 'restore_from_supabase_user_succeeded',
              code: any(named: 'code'),
              context: {'userId': 'user-123', 'role': UserRoles.customer},
            ),
          ).called(1);
        },
      );

      test(
        'returns local session when role lookup fails but local session exists',
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

          when(() => mockSessionLocalDataSource.getUserSession()).thenAnswer(
            (_) async => jsonEncode({
              'id': 'user-123',
              'email': 'test@test.com',
              'role': UserRoles.customer,
            }),
          );

          final result = await repository.getCurrentUser();

          expect(result.isRight(), true);
          result.fold((_) => fail('Expected Right(AppUser?)'), (user) {
            expect(user, isNotNull);
            expect(user!.id, 'user-123');
            expect(user.email, 'test@test.com');
            expect(user.role, UserRoles.customer);
          });

          verify(
            () => mockFeatureLogger.info(
              feature: 'auth',
              action: 'restore_from_supabase_user_local_fallback',
              code: any(named: 'code'),
              context: {'userId': 'user-123'},
            ),
          ).called(1);
        },
      );

      test(
        'restores session from refresh token when currentUser is null',
        () async {
          final user = User(
            id: 'user-123',
            appMetadata: const {},
            userMetadata: const {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
            email: 'test@test.com',
          );

          when(() => mockGoTrueClient.currentUser).thenReturn(null);
          when(
            () => mockSessionLocalDataSource.getRefreshToken(),
          ).thenAnswer((_) async => 'refresh-token-123');
          when(
            () => mockGoTrueClient.setSession('refresh-token-123'),
          ).thenAnswer(
            (_) async => AuthResponse(session: mockSession, user: user),
          );
          when(
            () => mockUserRoleDataSource.getUserRole('user-123'),
          ).thenAnswer((_) async => UserRoles.customer);

          final result = await repository.getCurrentUser();

          expect(result.isRight(), true);
          result.fold((_) => fail('Expected Right(AppUser?)'), (user) {
            expect(user, isNotNull);
            expect(user!.id, 'user-123');
            expect(user.email, 'test@test.com');
            expect(user.role, UserRoles.customer);
          });

          verify(
            () => mockGoTrueClient.setSession('refresh-token-123'),
          ).called(1);
          verify(
            () =>
                mockSessionLocalDataSource.saveAccessToken('access-token-123'),
          ).called(1);
          verify(
            () => mockSessionLocalDataSource.saveRefreshToken(
              'refresh-token-123',
            ),
          ).called(1);
        },
      );

      test('returns null when no Supabase user and no local session', () async {
        when(() => mockGoTrueClient.currentUser).thenReturn(null);
        when(
          () => mockSessionLocalDataSource.getUserSession(),
        ).thenAnswer((_) async => null);

        final result = await repository.getCurrentUser();

        expect(result, const Right<Failure, AppUser?>(null));
      });
      test('returns null when local session is invalid', () async {
        when(() => mockGoTrueClient.currentUser).thenReturn(null);
        when(
          () => mockSessionLocalDataSource.getUserSession(),
        ).thenAnswer((_) async => '{"id":"user-1","role":"invalid-role"}');

        final result = await repository.getCurrentUser();

        expect(result, const Right<Failure, AppUser?>(null));
      });

      test('returns Left when local session JSON is malformed', () async {
        when(() => mockGoTrueClient.currentUser).thenReturn(null);
        when(
          () => mockSessionLocalDataSource.getUserSession(),
        ).thenAnswer((_) async => 'not-json');

        final result = await repository.getCurrentUser();

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(
            failure.code,
            AuthErrorCatalog.localSessionRecoveryFailed.code,
          );
          expect(
            failure.uiKey,
            AuthErrorCatalog.localSessionRecoveryFailed.uiKey,
          );
        }, (_) => fail('Expected Left(Failure)'));
        verify(
          () => mockFeatureLogger.warn(
            feature: 'auth',
            action: 'recover_from_local_parse_failed',
            code: AuthErrorCatalog.localSessionRecoveryFailed.code,
            context: {
              'uiKey': AuthErrorCatalog.localSessionRecoveryFailed.uiKey,
            },
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      });
    });
  });
}
