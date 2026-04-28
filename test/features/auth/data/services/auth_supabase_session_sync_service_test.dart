import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/auth/data/datasources/session_local_data_source.dart';
import 'package:autolab_customer/features/auth/data/datasources/user_role_data_source.dart';
import 'package:autolab_customer/features/auth/data/services/auth_session_storage_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_supabase_session_sync_service.dart';
import 'package:autolab_customer/features/auth/domain/constants/user_roles.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFeatureLogger extends Mock implements FeatureLogger {}

class MockSessionLocalDataSource extends Mock
    implements SessionLocalDataSource {}

class MockUserRoleDataSource extends Mock implements UserRoleDataSource {}

void main() {
  group('AuthSupabaseSessionSyncService', () {
    late MockFeatureLogger mockFeatureLogger;
    late MockSessionLocalDataSource mockSessionLocalDataSource;
    late MockUserRoleDataSource mockUserRoleDataSource;
    late AuthSupabaseSessionSyncService service;

    setUp(() {
      mockFeatureLogger = MockFeatureLogger();
      mockSessionLocalDataSource = MockSessionLocalDataSource();
      mockUserRoleDataSource = MockUserRoleDataSource();

      when(
        () => mockFeatureLogger.info(
          feature: any(named: 'feature'),
          action: any(named: 'action'),
          code: any(named: 'code'),
          context: any(named: 'context'),
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
        () => mockSessionLocalDataSource.saveUserSession(any()),
      ).thenAnswer((_) async {});

      service = AuthSupabaseSessionSyncService(
        sessionStorageService: AuthSessionStorageService(
          mockSessionLocalDataSource,
        ),
        userRoleDataSource: mockUserRoleDataSource,
        featureLogger: mockFeatureLogger,
      );
    });

    test('returns Right(AppUser) when role lookup succeeds', () async {
      final user = User(
        id: 'user-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'user@test.com',
      );

      when(
        () => mockUserRoleDataSource.getUserRole('user-1'),
      ).thenAnswer((_) async => UserRoles.customer);

      final result = await service.syncUser(user);

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right(AppUser)'), (appUser) {
        expect(appUser.id, 'user-1');
        expect(appUser.email, 'user@test.com');
        expect(appUser.role, UserRoles.customer);
      });

      verify(() => mockSessionLocalDataSource.saveUserSession(any())).called(1);
    });

    test('returns Left when role lookup fails', () async {
      final user = User(
        id: 'user-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'user@test.com',
      );

      when(
        () => mockUserRoleDataSource.getUserRole('user-1'),
      ).thenThrow(Exception('role lookup failed'));

      final result = await service.syncUser(user);

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure.code, AuthErrorCatalog.sessionRestoreFailed.code);
        expect(failure.uiKey, AuthErrorCatalog.sessionRestoreFailed.uiKey);
      }, (_) => fail('Expected Left(Failure)'));
    });
  });
}
