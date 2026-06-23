import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/errors/customer_error_catalog.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:autolab_customer/features/payments/data/datasources/laropay_link_remote_data_source.dart';
import 'package:autolab_customer/features/payments/data/datasources/laropay_link_remote_data_source_impl.dart';
import 'package:autolab_customer/features/payments/data/models/laropay_link_model.dart';
import 'package:autolab_customer/features/payments/data/repositories/laropay_link_repository_impl.dart';
import 'package:autolab_customer/features/payments/domain/entities/laropay_link_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLaropayLinkRemoteDataSource extends Mock
    implements LaropayLinkRemoteDataSource {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class MockFeatureLogger extends Mock implements FeatureLogger {}

void main() {
  late MockLaropayLinkRemoteDataSource remoteDataSource;
  late MockGlobalErrorHandler errorHandler;
  late MockFeatureLogger featureLogger;
  late LaropayLinkRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_request());
    registerFallbackValue(StackTrace.current);
  });

  setUp(() {
    remoteDataSource = MockLaropayLinkRemoteDataSource();
    errorHandler = MockGlobalErrorHandler();
    featureLogger = MockFeatureLogger();
    repository = LaropayLinkRepositoryImpl(
      remoteDataSource: remoteDataSource,
      errorHandler: errorHandler,
      featureLogger: featureLogger,
    );
  });

  test('returns link when datasource succeeds', () async {
    when(
      () => remoteDataSource.generateLink(any()),
    ).thenAnswer((_) async => _link());

    final result = await repository.generateLink(_request());

    expect(result.isRight(), isTrue);
    expect(
      result.getOrElse(() => throw StateError('missing')).linkId,
      'link-1',
    );
    verify(() => remoteDataSource.generateLink(any())).called(1);
  });

  test(
    'rejects amount lower than or equal to zero before calling datasource',
    () async {
      final result = await repository.generateLink(_request(amount: 0));

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.code,
          CustomerErrorCatalog.laropayInvalidAmount.code,
        ),
        (_) => fail('expected failure'),
      );
      verifyNever(() => remoteDataSource.generateLink(any()));
    },
  );

  test('rejects non finite amount before calling datasource', () async {
    final result = await repository.generateLink(_request(amount: double.nan));

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) =>
          expect(failure.code, CustomerErrorCatalog.laropayInvalidAmount.code),
      (_) => fail('expected failure'),
    );
    verifyNever(() => remoteDataSource.generateLink(any()));
  });

  test('rejects invalid email before calling datasource', () async {
    final result = await repository.generateLink(
      _request(customerEmail: 'invalid-email'),
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.code, CustomerErrorCatalog.invalidEmail.code),
      (_) => fail('expected failure'),
    );
    verifyNever(() => remoteDataSource.generateLink(any()));
  });

  test(
    'rejects unsupported expiration type before calling datasource',
    () async {
      final result = await repository.generateLink(
        _request(expirationType: 'Y'),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.code,
          CustomerErrorCatalog.laropayInvalidExpiration.code,
        ),
        (_) => fail('expected failure'),
      );
      verifyNever(() => remoteDataSource.generateLink(any()));
    },
  );

  test('maps timeout to controlled failure', () async {
    when(
      () => remoteDataSource.generateLink(any()),
    ).thenThrow(TimeoutException('timeout'));

    final result = await repository.generateLink(_request());

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) =>
          expect(failure.code, CustomerErrorCatalog.laropayNetworkError.code),
      (_) => fail('expected failure'),
    );
  });

  test('maps gateway rejection to controlled failure', () async {
    when(
      () => remoteDataSource.generateLink(any()),
    ).thenThrow(const LaropayGatewayException(statusCode: 400, message: 'bad'));

    final result = await repository.generateLink(_request());

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(
        failure.code,
        CustomerErrorCatalog.laropayGatewayRejected.code,
      ),
      (_) => fail('expected failure'),
    );
  });

  test('maps missing auth token to auth failure', () async {
    when(
      () => remoteDataSource.generateLink(any()),
    ).thenThrow(const LaropayAuthException('missing token'));

    final result = await repository.generateLink(_request());

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.code, AuthErrorCatalog.sessionExpired.code),
      (_) => fail('expected failure'),
    );
  });

  test('maps configuration error to controlled failure', () async {
    when(
      () => remoteDataSource.generateLink(any()),
    ).thenThrow(const LaropayConfigurationException('missing url'));

    final result = await repository.generateLink(_request());

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(
        failure.code,
        CustomerErrorCatalog.laropayGatewayRejected.code,
      ),
      (_) => fail('expected failure'),
    );
  });

  test('delegates unknown failures to global error handler', () async {
    final failure = const UnknownFailure(message: 'unknown');
    when(() => remoteDataSource.generateLink(any())).thenThrow(StateError('x'));
    when(() => errorHandler.handle(any(), any())).thenReturn(failure);

    final result = await repository.generateLink(_request());

    expect(result.isLeft(), isTrue);
    expect(result.swap().getOrElse(() => failure), failure);
    verify(() => errorHandler.handle(any(), any())).called(1);
  });
}

LaropayLinkRequest _request({
  double amount = 10,
  String customerEmail = 'cliente@autolab.app',
  String expirationType = 'D',
}) {
  return LaropayLinkRequest(
    internalTransactionId: 'order-1',
    idTransaction: 1,
    amount: amount,
    document: 'document',
    detail: 'detail',
    customerFirstName: 'Cliente',
    customerLastName: 'Autolab',
    customerEmail: customerEmail,
    customerPhone: '71021210',
    customerLocation: 'San Jose',
    expirationType: expirationType,
    expirationValue: 2,
  );
}

LaropayLinkModel _link() {
  return LaropayLinkModel(
    linkId: 'link-1',
    linkUrl: Uri.parse('https://pay.test/link-1'),
    response: '00',
    responseDescription: 'Success',
    status: 'CREATED',
  );
}
