import 'package:autolab_customer/features/payments/data/datasources/laropay_purchase_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient('https://project.supabase.co', 'anon-key');
  });

  test('normalizes payment id and maps a successful response', () async {
    String? invokedId;
    final dataSource = SupabaseLaropayPurchaseRemoteDataSource(
      client,
      currentUserIdProvider: () => 'user-1',
      orderLookup: (_, _) async => null,
      statusInvoker: (paymentLinkId) async {
        invokedId = paymentLinkId;
        return FunctionResponse(
          status: 200,
          data: {
            'id': 'payment-1',
            'amount': 12000,
            'currency_code': 'CRC',
            'detail': 'Kit',
            'link_id': r'$$ABC',
            'link_url': 'https://pay.test/link',
            'status': 'paid',
            'response_code': '00',
            'response_description': 'OK',
            'reject_reason': '',
            'created_at': '2026-07-08T12:00:00Z',
            'expires_at': '2026-07-09T12:00:00Z',
          },
        );
      },
    );

    final purchase = await dataSource.refreshPurchaseStatus(' payment-1 ');

    expect(invokedId, 'payment-1');
    expect(purchase.id, 'payment-1');
    expect(purchase.status, 'paid');
    expect(purchase.amount, 12000);
    expect(purchase.currencyCode, 'CRC');
    expect(purchase.linkId, r'$$ABC');
    expect(purchase.responseCode, '00');
    expect(purchase.responseDescription, 'OK');
    expect(purchase.linkUrl, Uri.parse('https://pay.test/link'));
  });

  test(
    'maps camelCase status responses returned by the Edge Function',
    () async {
      final dataSource = SupabaseLaropayPurchaseRemoteDataSource(
        client,
        currentUserIdProvider: () => 'user-1',
        orderLookup: (_, _) async => null,
        statusInvoker: (_) async => FunctionResponse(
          status: 200,
          data: {
            'id': 'payment-1',
            'amount': 12000,
            'currencyCode': 'CRC',
            'detail': 'Kit',
            'linkID': r'$$ABC',
            'linkURL': 'https://pay.test/link',
            'status': 'paid',
            'response': '00',
            'responseDescription': 'OK',
            'rejectReason': '',
            'createdAt': '2026-07-08T12:00:00Z',
            'expiresAt': '2026-07-09T12:00:00Z',
          },
        ),
      );

      final purchase = await dataSource.refreshPurchaseStatus('payment-1');

      expect(purchase.id, 'payment-1');
      expect(purchase.status, 'paid');
      expect(purchase.amount, 12000);
      expect(purchase.currencyCode, 'CRC');
      expect(purchase.linkId, r'$$ABC');
      expect(purchase.responseCode, '00');
      expect(purchase.responseDescription, 'OK');
      expect(purchase.linkUrl, Uri.parse('https://pay.test/link'));
    },
  );

  test(
    'completa los campos order* con la orden asociada al payment link',
    () async {
      String? lookedUpPaymentLinkId;
      String? lookedUpUserId;
      final dataSource = SupabaseLaropayPurchaseRemoteDataSource(
        client,
        currentUserIdProvider: () => 'user-1',
        orderLookup: (paymentLinkId, userId) async {
          lookedUpPaymentLinkId = paymentLinkId;
          lookedUpUserId = userId;
          return {
            'order_number': 'ORD-100',
            'payment_status': 'partial',
            'total_amount': 20000,
            'paid_amount': 5000,
            'remaining_amount': 15000,
          };
        },
        statusInvoker: (_) async => FunctionResponse(
          status: 200,
          data: const {
            'id': 'payment-1',
            'amount': 12000,
            'currency_code': 'CRC',
            'link_id': r'$$ABC',
            'link_url': 'https://pay.test/link',
            'status': 'pending',
            'response_code': '00',
            'response_description': 'OK',
            'reject_reason': '',
          },
        ),
      );

      final purchase = await dataSource.refreshPurchaseStatus('payment-1');

      expect(lookedUpPaymentLinkId, 'payment-1');
      expect(lookedUpUserId, 'user-1');
      expect(purchase.orderNumber, 'ORD-100');
      expect(purchase.orderPaymentStatus, 'partial');
      expect(purchase.orderTotalAmount, 20000);
      expect(purchase.orderPaidAmount, 5000);
      expect(purchase.orderRemainingAmount, 15000);
    },
  );

  test(
    'no falla refreshPurchaseStatus si orderLookup retorna null o la orden no existe',
    () async {
      final dataSource = SupabaseLaropayPurchaseRemoteDataSource(
        client,
        currentUserIdProvider: () => 'user-1',
        orderLookup: (_, _) async => null,
        statusInvoker: (_) async => FunctionResponse(
          status: 200,
          data: const {
            'id': 'payment-1',
            'amount': 12000,
            'currency_code': 'CRC',
            'link_id': r'$$ABC',
            'link_url': 'https://pay.test/link',
            'status': 'pending',
            'response_code': '00',
            'response_description': 'OK',
            'reject_reason': '',
          },
        ),
      );

      final purchase = await dataSource.refreshPurchaseStatus('payment-1');

      expect(purchase.id, 'payment-1');
      expect(purchase.orderNumber, isNull);
      expect(purchase.orderPaymentStatus, isNull);
      expect(purchase.orderTotalAmount, isNull);
    },
  );

  test(
    'rejects active status responses with an invalid payment link',
    () async {
      final dataSource = SupabaseLaropayPurchaseRemoteDataSource(
        client,
        currentUserIdProvider: () => 'user-1',
        orderLookup: (_, _) async => null,
        statusInvoker: (_) async => FunctionResponse(
          status: 200,
          data: const {
            'id': 'payment-1',
            'amount': 12000,
            'currency_code': 'CRC',
            'link_id': r'$$ABC',
            'link_url': 'http://pay.test/link',
            'status': 'pending',
            'response_code': '00',
            'response_description': 'OK',
            'reject_reason': '',
          },
        ),
      );

      await expectLater(
        dataSource.refreshPurchaseStatus('payment-1'),
        throwsA(isA<LaropayPurchaseStatusException>()),
      );
    },
  );

  test('rejects an empty payment identifier before invoking', () async {
    var invoked = false;
    final dataSource = SupabaseLaropayPurchaseRemoteDataSource(
      client,
      currentUserIdProvider: () => 'user-1',
      statusInvoker: (_) async {
        invoked = true;
        return FunctionResponse(status: 200, data: const {});
      },
    );

    await expectLater(
      dataSource.refreshPurchaseStatus('   '),
      throwsA(isA<LaropayPurchaseStatusException>()),
    );
    expect(invoked, isFalse);
  });

  test('rejects a non-object response body', () async {
    final dataSource = SupabaseLaropayPurchaseRemoteDataSource(
      client,
      currentUserIdProvider: () => 'user-1',
      statusInvoker: (_) async => FunctionResponse(status: 200, data: []),
    );

    await expectLater(
      dataSource.refreshPurchaseStatus('payment-1'),
      throwsA(isA<LaropayPurchaseStatusException>()),
    );
  });

  test('rejects a non-success response status', () async {
    final dataSource = SupabaseLaropayPurchaseRemoteDataSource(
      client,
      currentUserIdProvider: () => 'user-1',
      statusInvoker: (_) async => FunctionResponse(
        status: 502,
        data: const {'error': 'laropay_status_unavailable'},
      ),
    );

    await expectLater(
      dataSource.refreshPurchaseStatus('payment-1'),
      throwsA(isA<LaropayPurchaseStatusException>()),
    );
  });

  test('translates function http failures', () async {
    final dataSource = SupabaseLaropayPurchaseRemoteDataSource(
      client,
      currentUserIdProvider: () => 'user-1',
      statusInvoker: (_) async => throw const FunctionException(
        status: 502,
        details: {'error': 'laropay_status_unavailable'},
      ),
    );

    await expectLater(
      dataSource.refreshPurchaseStatus('payment-1'),
      throwsA(
        isA<LaropayPurchaseStatusException>()
            .having((error) => error.status, 'status', 502)
            .having(
              (error) => error.message,
              'message',
              'laropay_check_status_function_failed',
            ),
      ),
    );
  });

  test('requires an authenticated user', () async {
    final dataSource = SupabaseLaropayPurchaseRemoteDataSource(
      client,
      currentUserIdProvider: () => null,
      statusInvoker: (_) async => FunctionResponse(status: 200, data: const {}),
    );

    await expectLater(
      dataSource.refreshPurchaseStatus('payment-1'),
      throwsA(isA<LaropayPurchaseAuthException>()),
    );
  });
}
