import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/auth/data/datasources/session_local_data_source.dart';
import 'package:autolab_customer/features/auth/data/services/auth_local_session_recovery_service.dart';
import 'package:autolab_customer/features/auth/data/services/auth_session_storage_service.dart';
import 'package:autolab_customer/features/auth/domain/constants/user_roles.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeatureLogger extends Mock implements FeatureLogger {}

class MockSessionLocalDataSource extends Mock
    implements SessionLocalDataSource {}

void main() {
  group('AuthLocalSessionRecoveryService', () {
    late MockFeatureLogger mockFeatureLogger;
    late MockSessionLocalDataSource mockSessionLocalDataSource;
    late AuthLocalSessionRecoveryService service;

    setUp(() {
      mockFeatureLogger = MockFeatureLogger();
      mockSessionLocalDataSource = MockSessionLocalDataSource();

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

      service = AuthLocalSessionRecoveryService(
        sessionStorageService: AuthSessionStorageService(
          mockSessionLocalDataSource,
        ),
        featureLogger: mockFeatureLogger,
      );
    });

    test('returns Right(AppUser) when stored session is valid', () async {
      when(() => mockSessionLocalDataSource.getUserSession()).thenAnswer(
        (_) async =>
            '{"id":"user-1","email":"user@test.com","role":"customer"}',
      );

      final result = await service.recover();

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right(AppUser?)'), (user) {
        expect(user, isNotNull);
        expect(user!.id, 'user-1');
        expect(user.email, 'user@test.com');
        expect(user.role, UserRoles.customer);
      });
    });

    test('returns Right(null) when stored role is invalid', () async {
      when(() => mockSessionLocalDataSource.getUserSession()).thenAnswer(
        (_) async => '{"id":"user-1","email":"user@test.com","role":"unknown"}',
      );

      final result = await service.recover();

      expect(result.isRight(), true);
      expect(result.fold((_) => const Object(), (user) => user), isNull);
    });

    test('returns Left when stored JSON is malformed', () async {
      when(
        () => mockSessionLocalDataSource.getUserSession(),
      ).thenAnswer((_) async => 'not-json');

      final result = await service.recover();

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure.code, AuthErrorCatalog.localSessionRecoveryFailed.code);
        expect(
          failure.uiKey,
          AuthErrorCatalog.localSessionRecoveryFailed.uiKey,
        );
      }, (_) => fail('Expected Left(Failure)'));
    });
  });
}
