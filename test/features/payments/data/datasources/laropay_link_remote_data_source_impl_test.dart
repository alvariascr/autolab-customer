import 'dart:convert';

import 'package:autolab_customer/core/config/laropay_gateway_config.dart';
import 'package:autolab_customer/features/payments/data/datasources/laropay_link_remote_data_source_impl.dart';
import 'package:autolab_customer/features/payments/data/exceptions/laropay_invalid_response_exception.dart';
import 'package:autolab_customer/features/payments/data/models/laropay_link_model.dart';
import 'package:autolab_customer/features/payments/domain/entities/laropay_link_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'posts sanitized payload to configured gateway and parses link',
    () async {
      late Map<String, dynamic> payload;
      final dataSource = LaropayLinkRemoteDataSourceImpl(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url,
            Uri.parse('https://api.autolab.test/laropay/links'),
          );
          expect(request.headers['authorization'], 'Bearer session-token');
          payload = jsonDecode(request.body) as Map<String, dynamic>;

          return http.Response(
            jsonEncode({
              'paymentLinkId': 'payment-link-1',
              'response': '00',
              'responseDescription': 'Success',
              'linkID': 'link-1',
              'linkURL': 'https://pay.test/link-1',
              'status': 'CREATED',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        config: LaropayGatewayConfig(
          generateLinkUri: Uri.parse('https://api.autolab.test/laropay/links'),
        ),
        authTokenProvider: () => 'session-token',
      );

      final link = await dataSource.generateLink(_request());

      expect(link.linkId, 'link-1');
      expect(link.paymentLinkId, 'payment-link-1');
      expect(link.linkUrl, Uri.parse('https://pay.test/link-1'));
      expect(payload.containsKey('idTransaction'), isFalse);
      expect(payload['amount'], 10);
      expect(payload['customerEmail'], 'cliente@autolab.app');
      expect(payload.containsKey('token'), isFalse);
      expect(payload.containsKey('idUser'), isFalse);
    },
  );

  test('throws when gateway url is not configured', () async {
    final dataSource = LaropayLinkRemoteDataSourceImpl(
      client: MockClient((_) async => http.Response('{}', 200)),
      config: const LaropayGatewayConfig(generateLinkUri: null),
      authTokenProvider: () => 'session-token',
    );

    expect(
      () => dataSource.generateLink(_request()),
      throwsA(isA<LaropayConfigurationException>()),
    );
  });

  test('throws when gateway url is not https', () async {
    final dataSource = LaropayLinkRemoteDataSourceImpl(
      client: MockClient((_) async => http.Response('{}', 200)),
      config: LaropayGatewayConfig(
        generateLinkUri: Uri.parse('http://api.autolab.test/laropay/links'),
      ),
      authTokenProvider: () => 'session-token',
    );

    expect(
      () => dataSource.generateLink(_request()),
      throwsA(isA<LaropayConfigurationException>()),
    );
  });

  test('throws before request when auth token is missing', () async {
    var called = false;
    final dataSource = LaropayLinkRemoteDataSourceImpl(
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
      config: LaropayGatewayConfig(
        generateLinkUri: Uri.parse('https://api.autolab.test/laropay/links'),
      ),
      authTokenProvider: () => ' ',
    );

    expect(
      () => dataSource.generateLink(_request()),
      throwsA(isA<LaropayAuthException>()),
    );
    expect(called, isFalse);
  });

  test('throws gateway exception for non successful response', () async {
    final dataSource = LaropayLinkRemoteDataSourceImpl(
      client: MockClient((_) async => http.Response('bad request', 400)),
      config: LaropayGatewayConfig(
        generateLinkUri: Uri.parse('https://api.autolab.test/laropay/links'),
      ),
      authTokenProvider: () => 'session-token',
    );

    expect(
      () => dataSource.generateLink(_request()),
      throwsA(isA<LaropayGatewayException>()),
    );
  });

  test('redacts unsafe gateway body on server errors', () async {
    final dataSource = LaropayLinkRemoteDataSourceImpl(
      client: MockClient(
        (_) async => http.Response(
          'Error: database password leaked\n    at handler.ts:1',
          500,
        ),
      ),
      config: LaropayGatewayConfig(
        generateLinkUri: Uri.parse('https://api.autolab.test/laropay/links'),
      ),
      authTokenProvider: () => 'session-token',
    );

    expect(
      () => dataSource.generateLink(_request()),
      throwsA(
        isA<LaropayGatewayException>().having(
          (error) => error.message,
          'message',
          'laropay_gateway_unavailable',
        ),
      ),
    );
  });

  test('uses safe structured gateway error when available', () async {
    final dataSource = LaropayLinkRemoteDataSourceImpl(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'error': 'invalid_order'}), 400),
      ),
      config: LaropayGatewayConfig(
        generateLinkUri: Uri.parse('https://api.autolab.test/laropay/links'),
      ),
      authTokenProvider: () => 'session-token',
    );

    expect(
      () => dataSource.generateLink(_request()),
      throwsA(
        isA<LaropayGatewayException>().having(
          (error) => error.message,
          'message',
          'invalid_order',
        ),
      ),
    );
  });

  test(
    'throws invalid response exception when response does not include link data',
    () {
      expect(
        () => LaropayLinkModel.fromJson({
          'response': '00',
          'responseDescription': 'Success',
        }),
        throwsA(isA<LaropayInvalidResponseException>()),
      );
    },
  );

  test('throws invalid response exception when link url is not https', () {
    expect(
      () => LaropayLinkModel.fromJson({
        'response': '00',
        'responseDescription': 'Success',
        'paymentLinkId': 'payment-link-1',
        'linkID': 'link-1',
        'linkURL': 'http://pay.test/link-1',
      }),
      throwsA(isA<LaropayInvalidResponseException>()),
    );
  });

  test(
    'throws invalid response exception when response metadata is missing',
    () {
      expect(
        () => LaropayLinkModel.fromJson({
          'linkID': 'link-1',
          'linkURL': 'https://pay.test/link-1',
        }),
        throwsA(isA<LaropayInvalidResponseException>()),
      );
    },
  );

  test(
    'parses gateway response metadata even when response is not successful',
    () {
      final model = LaropayLinkModel.fromJson({
        'response': '99',
        'responseDescription': 'Rejected',
        'paymentLinkId': 'payment-link-1',
        'linkID': 'link-1',
        'linkURL': 'https://pay.test/link-1',
      });

      expect(model.response, '99');
      expect(model.responseDescription, 'Rejected');
    },
  );
}

LaropayLinkRequest _request() {
  return LaropayLinkRequest(
    internalTransactionId: 'order-1',
    amount: 10,
    document: 'document',
    detail: 'detail',
    customerFirstName: 'Cliente',
    customerLastName: 'Autolab',
    customerEmail: 'cliente@autolab.app',
    customerPhone: '71021210',
    customerLocation: 'San Jose',
    expirationType: 'D',
    expirationValue: 2,
  );
}
