import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/laropay_purchase.dart';

final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

typedef LaropayStatusInvoker =
    Future<FunctionResponse> Function(String paymentLinkId);
typedef CurrentUserIdProvider = String? Function();

abstract interface class LaropayPurchaseRemoteDataSource {
  Future<List<LaropayPurchase>> getRecentPurchases();

  Future<LaropayPurchase> refreshPurchaseStatus(String paymentLinkId);
}

class LaropayPurchaseAuthException implements Exception {
  const LaropayPurchaseAuthException();
}

class LaropayPurchaseStatusException implements Exception {
  const LaropayPurchaseStatusException({
    this.message = 'laropay_purchase_status_failed',
    this.status,
    this.details,
  });

  final String message;
  final int? status;
  final Object? details;

  @override
  String toString() {
    return 'LaropayPurchaseStatusException('
        'message: $message, status: $status, details: $details)';
  }
}

class SupabaseLaropayPurchaseRemoteDataSource
    implements LaropayPurchaseRemoteDataSource {
  const SupabaseLaropayPurchaseRemoteDataSource(
    this._client, {
    LaropayStatusInvoker? statusInvoker,
    CurrentUserIdProvider? currentUserIdProvider,
  }) : _statusInvoker = statusInvoker,
       _currentUserIdProvider = currentUserIdProvider;

  final SupabaseClient _client;
  final LaropayStatusInvoker? _statusInvoker;
  final CurrentUserIdProvider? _currentUserIdProvider;

  @override
  Future<List<LaropayPurchase>> getRecentPurchases() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const LaropayPurchaseAuthException();
    }

    final response = await _client
        .from('orders')
        .select('''
          id,
          order_number,
          payment_status,
          total_amount,
          paid_amount,
          remaining_amount,
          created_at,
          updated_at,
          workshops(name),
          customers!inner(user_id)
        ''')
        .eq('customers.user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    final orders = response
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final orderIds = orders
        .map((item) => _stringValue(item['id']))
        .where(_isUuid)
        .toSet()
        .toList(growable: false);

    final paymentLinksByOrderId = orderIds.isEmpty
        ? const <String, Map<String, dynamic>>{}
        : await _paymentLinksByOrderId(orderIds, user.id);

    return orders
        .map((item) {
          final orderId = _stringValue(item['id']);
          return _purchaseFromOrder(
            item,
            paymentLink: paymentLinksByOrderId[orderId],
          );
        })
        .toList(growable: false);
  }

  @override
  Future<LaropayPurchase> refreshPurchaseStatus(String paymentLinkId) async {
    final userId =
        _currentUserIdProvider?.call() ?? _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const LaropayPurchaseAuthException();
    }

    final normalizedId = paymentLinkId.trim();
    if (normalizedId.isEmpty) {
      throw const LaropayPurchaseStatusException();
    }

    late final FunctionResponse response;
    try {
      response =
          await _statusInvoker?.call(normalizedId) ??
          await _client.functions.invoke(
            'laropay-check-status',
            body: {'paymentLinkId': normalizedId},
          );
    } on FunctionException catch (error) {
      throw LaropayPurchaseStatusException(
        message: 'laropay_check_status_function_failed',
        status: error.status,
        details: error.details,
      );
    }

    final data = response.data;
    if (response.status < 200 ||
        response.status >= 300 ||
        data is! Map<String, dynamic>) {
      throw const LaropayPurchaseStatusException();
    }

    return _purchaseFromStatusResponse(data);
  }

  Future<Map<String, Map<String, dynamic>>> _paymentLinksByOrderId(
    List<String> orderIds,
    String userId,
  ) async {
    final response = await _client
        .from('laropay_payment_links')
        .select('''
          id,
          internal_transaction_id,
          amount,
          currency_code,
          detail,
          link_id,
          link_url,
          status,
          response_code,
          response_description,
          reject_reason,
          auth_response_code,
          created_at,
          updated_at,
          expires_at
        ''')
        .eq('user_id', userId)
        .inFilter('internal_transaction_id', orderIds)
        .order('created_at', ascending: false);

    final linksByOrderId = <String, Map<String, dynamic>>{};
    for (final item in response) {
      final map = Map<String, dynamic>.from(item);
      final orderId = _stringValue(map['internal_transaction_id']);
      linksByOrderId.putIfAbsent(orderId, () => map);
    }

    return linksByOrderId;
  }

  LaropayPurchase _purchaseFromOrder(
    Map<String, dynamic> order, {
    Map<String, dynamic>? paymentLink,
  }) {
    if (paymentLink != null) {
      return _purchaseFromMap(
        paymentLink,
        order: order,
        fallbackDetail: _orderTitle(order),
      );
    }

    final paymentStatus = _stringValue(order['payment_status']);
    return LaropayPurchase(
      id: _stringValue(order['id']),
      amount: _nullableNumberValue(order['paid_amount']) ?? 0,
      currencyCode: 'CRC',
      detail: _orderTitle(order),
      linkId: '',
      status: paymentStatus.isEmpty ? 'unpaid' : paymentStatus,
      responseCode: '',
      responseDescription: '',
      rejectReason: '',
      createdAt: DateTime.tryParse(_stringValue(order['created_at'])),
      expiresAt: null,
      hasPaymentLink: false,
      orderNumber: _nullableStringValue(order['order_number']),
      orderPaymentStatus: _nullableStringValue(order['payment_status']),
      orderTotalAmount: _nullableNumberValue(order['total_amount']),
      orderPaidAmount: _nullableNumberValue(order['paid_amount']),
      orderRemainingAmount: _nullableNumberValue(order['remaining_amount']),
    );
  }

  LaropayPurchase _purchaseFromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? order,
    String? fallbackDetail,
  }) {
    final detail = _stringValue(map['detail']);
    return LaropayPurchase(
      id: _stringValue(map['id']),
      amount: _numberValue(map['amount']),
      currencyCode: _stringValue(map['currency_code']).isEmpty
          ? 'CRC'
          : _stringValue(map['currency_code']),
      detail: detail.isEmpty ? _stringValue(fallbackDetail) : detail,
      linkId: _stringValue(map['link_id']),
      linkUrl: _secureUri(map['link_url']),
      status: _stringValue(map['status']),
      responseCode: _stringValue(map['response_code']),
      responseDescription: _stringValue(map['response_description']),
      rejectReason: _stringValue(map['reject_reason']),
      createdAt: DateTime.tryParse(_stringValue(map['created_at'])),
      expiresAt: DateTime.tryParse(_stringValue(map['expires_at'])),
      hasPaymentLink: true,
      orderNumber: _nullableStringValue(order?['order_number']),
      orderPaymentStatus: _nullableStringValue(order?['payment_status']),
      orderTotalAmount: _nullableNumberValue(order?['total_amount']),
      orderPaidAmount: _nullableNumberValue(order?['paid_amount']),
      orderRemainingAmount: _nullableNumberValue(order?['remaining_amount']),
    );
  }

  LaropayPurchase _purchaseFromStatusResponse(Map<String, dynamic> map) {
    final status = _stringValue(map['status']);
    final linkUrl = _secureUri(_firstValue(map, 'link_url', 'linkURL'));
    if (_requiresPaymentLink(status) && linkUrl == null) {
      throw const LaropayPurchaseStatusException();
    }

    return LaropayPurchase(
      id: _stringValue(map['id']),
      amount: _numberValue(map['amount']),
      currencyCode:
          _stringValue(
            _firstValue(map, 'currency_code', 'currencyCode'),
          ).isEmpty
          ? 'CRC'
          : _stringValue(_firstValue(map, 'currency_code', 'currencyCode')),
      detail: _stringValue(map['detail']),
      linkId: _stringValue(_firstValue(map, 'link_id', 'linkID')),
      linkUrl: linkUrl,
      status: status,
      responseCode: _stringValue(_firstValue(map, 'response_code', 'response')),
      responseDescription: _stringValue(
        _firstValue(map, 'response_description', 'responseDescription'),
      ),
      rejectReason: _stringValue(
        _firstValue(map, 'reject_reason', 'rejectReason'),
      ),
      createdAt: DateTime.tryParse(
        _stringValue(_firstValue(map, 'created_at', 'createdAt')),
      ),
      expiresAt: DateTime.tryParse(
        _stringValue(_firstValue(map, 'expires_at', 'expiresAt')),
      ),
      hasPaymentLink: true,
    );
  }
}

Object? _firstValue(Map<String, dynamic> map, String primary, String fallback) {
  return map[primary] ?? map[fallback];
}

String _orderTitle(Map<String, dynamic> order) {
  final workshopName = _stringValue(_nestedValue(order['workshops'], 'name'));
  if (workshopName.isNotEmpty) {
    return workshopName;
  }

  final orderNumber = _stringValue(order['order_number']);
  return orderNumber.isEmpty ? 'Orden' : orderNumber;
}

Object? _nestedValue(Object? value, String key) {
  if (value is Map) {
    return value[key];
  }

  return null;
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';

String? _nullableStringValue(Object? value) {
  final normalized = _stringValue(value);
  return normalized.isEmpty ? null : normalized;
}

double _numberValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(_stringValue(value)) ?? 0;
}

double? _nullableNumberValue(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(_stringValue(value));
}

Uri? _secureUri(Object? value) {
  final uri = Uri.tryParse(_stringValue(value));
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return null;
  }

  return uri;
}

bool _requiresPaymentLink(String status) {
  final normalizedStatus = status.trim().toLowerCase();
  return normalizedStatus == 'created' || normalizedStatus == 'pending';
}

bool _isUuid(String value) {
  return _uuidRegex.hasMatch(value);
}
