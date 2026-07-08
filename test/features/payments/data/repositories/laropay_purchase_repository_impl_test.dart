import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:autolab_customer/features/payments/data/datasources/laropay_purchase_remote_data_source.dart';
import 'package:autolab_customer/features/payments/data/repositories/laropay_purchase_repository_impl.dart';
import 'package:autolab_customer/features/payments/domain/entities/laropay_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLaropayPurchaseRemoteDataSource extends Mock
    implements LaropayPurchaseRemoteDataSource {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

void main() {
  late MockLaropayPurchaseRemoteDataSource remoteDataSource;
  late MockGlobalErrorHandler errorHandler;
  late LaropayPurchaseRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(StackTrace.current);
  });

  setUp(() {
    remoteDataSource = MockLaropayPurchaseRemoteDataSource();
    errorHandler = MockGlobalErrorHandler();
    repository = LaropayPurchaseRepositoryImpl(
      remoteDataSource: remoteDataSource,
      errorHandler: errorHandler,
    );
  });

  test('returns refreshed purchase when datasource succeeds', () async {
    when(
      () => remoteDataSource.refreshPurchaseStatus('payment-1'),
    ).thenAnswer((_) async => _purchase(status: 'paid'));

    final result = await repository.refreshPurchaseStatus('payment-1');

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => throw StateError('missing')).status, 'paid');
    verify(() => remoteDataSource.refreshPurchaseStatus('payment-1')).called(1);
  });

  test('maps missing session to auth failure', () async {
    when(
      () => remoteDataSource.refreshPurchaseStatus('payment-1'),
    ).thenThrow(const LaropayPurchaseAuthException());

    final result = await repository.refreshPurchaseStatus('payment-1');

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.code, AuthErrorCatalog.sessionExpired.code),
      (_) => fail('expected failure'),
    );
  });

  test('delegates unknown refresh failures to global error handler', () async {
    const failure = UnknownFailure(message: 'unknown');
    when(
      () => remoteDataSource.refreshPurchaseStatus('payment-1'),
    ).thenThrow(const LaropayPurchaseStatusException());
    when(() => errorHandler.handle(any(), any())).thenReturn(failure);

    final result = await repository.refreshPurchaseStatus('payment-1');

    expect(result.isLeft(), isTrue);
    expect(result.swap().getOrElse(() => failure), failure);
    verify(() => errorHandler.handle(any(), any())).called(1);
  });
}

LaropayPurchase _purchase({required String status}) {
  return LaropayPurchase(
    id: 'payment-1',
    amount: 12000,
    currencyCode: 'CRC',
    detail: 'Kit de escobillas',
    linkId: r'$$ABC',
    linkUrl: Uri.parse('https://pay.test/link'),
    status: status,
    responseCode: '00',
    responseDescription: 'OK',
    rejectReason: '',
    createdAt: DateTime.utc(2026, 7, 5),
    expiresAt: DateTime.utc(2026, 7, 6),
  );
}
