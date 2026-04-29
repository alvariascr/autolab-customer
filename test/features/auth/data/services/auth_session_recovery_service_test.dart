import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/auth/data/services/auth_local_session_recovery_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_session_recovery_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_session_storage_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_supabase_session_sync_service.dart';
import 'package:autolab_customer/features/auth/domain/constants/user_roles.dart';
import 'package:autolab_customer/features/auth/domain/entities/app_user.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFeatureLogger extends Mock implements FeatureLogger {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthSessionStorageService extends Mock
    implements AuthSessionStorageService {}

class MockAuthSupabaseSessionSyncService extends Mock
    implements AuthSupabaseSessionSyncService {}

class MockAuthLocalSessionRecoveryService extends Mock
    implements AuthLocalSessionRecoveryService {}

class MockSession extends Mock implements Session {}

class FakeSession extends Fake implements Session {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSession());
  });

  group('AuthSessionRecoveryService', () {
    late MockFeatureLogger mockFeatureLogger;
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockAuthSessionStorageService mockSessionStorageService;
    late MockAuthSupabaseSessionSyncService mockSupabaseSessionSyncService;
    late MockAuthLocalSessionRecoveryService mockLocalSessionRecoveryService;
    late MockSession mockSession;
    late AuthSessionRecoveryService service;

    setUp(() {
      mockFeatureLogger = MockFeatureLogger();
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockSessionStorageService = MockAuthSessionStorageService();
      mockSupabaseSessionSyncService = MockAuthSupabaseSessionSyncService();
      mockLocalSessionRecoveryService = MockAuthLocalSessionRecoveryService();
      mockSession = MockSession();

      when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

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
        () => mockSessionStorageService.persistSessionTokens(any()),
      ).thenAnswer((_) async {});

      service = AuthSessionRecoveryService(
        client: mockSupabaseClient,
        sessionStorageService: mockSessionStorageService,
        supabaseSessionSyncService: mockSupabaseSessionSyncService,
        localSessionRecoveryService: mockLocalSessionRecoveryService,
        featureLogger: mockFeatureLogger,
      );
    });

    test('delegates restoreFromSupabaseUser to sync service first', () async {
      final user = User(
        id: 'user-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'user@test.com',
      );
      final appUser = AppUser(
        id: 'user-1',
        email: 'user@test.com',
        role: UserRoles.customer,
      );

      when(
        () => mockSupabaseSessionSyncService.syncUser(user),
      ).thenAnswer((_) async => Right(appUser));

      final result = await service.restoreFromSupabaseUser(user);

      expect(result, Right<Failure, AppUser?>(appUser));
      verify(() => mockSupabaseSessionSyncService.syncUser(user)).called(1);
      verifyNever(() => mockLocalSessionRecoveryService.recover());
    });

    test(
      'falls back to local recovery when sync fails for same user',
      () async {
        final user = User(
          id: 'user-1',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'user@test.com',
        );
        final syncFailure = AuthFailure.fromErrorItem(
          AuthErrorCatalog.sessionRestoreFailed,
        );
        final localUser = AppUser(
          id: 'user-1',
          email: 'user@test.com',
          role: UserRoles.customer,
        );

        when(
          () => mockSupabaseSessionSyncService.syncUser(user),
        ).thenAnswer((_) async => Left(syncFailure));
        when(
          () => mockLocalSessionRecoveryService.recover(),
        ).thenAnswer((_) async => Right(localUser));

        final result = await service.restoreFromSupabaseUser(user);

        expect(result, Right<Failure, AppUser?>(localUser));
        verify(() => mockLocalSessionRecoveryService.recover()).called(1);
      },
    );

    test('returns Right(null) when refresh token is missing', () async {
      when(
        () => mockSessionStorageService.getRefreshToken(),
      ).thenAnswer((_) async => null);

      final result = await service.restoreFromRefreshToken();

      expect(result, const Right<Failure, AppUser?>(null));
      verifyNever(() => mockGoTrueClient.setSession(any()));
    });

    test('restores from refresh token and delegates sync', () async {
      final user = User(
        id: 'user-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'user@test.com',
      );
      final appUser = AppUser(
        id: 'user-1',
        email: 'user@test.com',
        role: UserRoles.customer,
      );
      when(
        () => mockSessionStorageService.getRefreshToken(),
      ).thenAnswer((_) async => 'refresh-token');
      when(() => mockSession.accessToken).thenReturn('access-token');
      when(() => mockSession.refreshToken).thenReturn('refresh-token');
      when(
        () => mockGoTrueClient.setSession('refresh-token'),
      ).thenAnswer((_) async => AuthResponse(session: mockSession, user: user));
      when(
        () => mockSupabaseSessionSyncService.syncUser(user),
      ).thenAnswer((_) async => Right(appUser));

      final result = await service.restoreFromRefreshToken();

      expect(result, Right<Failure, AppUser?>(appUser));
      verify(
        () => mockSessionStorageService.persistSessionTokens(mockSession),
      ).called(1);
      verify(() => mockSupabaseSessionSyncService.syncUser(user)).called(1);
    });
  });
}
