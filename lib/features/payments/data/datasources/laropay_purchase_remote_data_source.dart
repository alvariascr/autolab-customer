import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/uuid_validator.dart';
import '../../domain/entities/laropay_purchase.dart';
import 'laropay_json_coercion.dart';

const _ordersPageSize = 100;
const _paymentLinkBatchSize = 100;
const _workshopPaymentStatus = 'workshop_payment';

typedef LaropayStatusInvoker =
    Future<FunctionResponse> Function(String paymentLinkId);
typedef CurrentUserIdProvider = String? Function();
typedef LaropayOrderLookup =
    Future<Map<String, dynamic>?> Function(String paymentLinkId, String userId);

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
    LaropayOrderLookup? orderLookup,
  }) : _statusInvoker = statusInvoker,
       _currentUserIdProvider = currentUserIdProvider,
       _orderLookup = orderLookup;

  final SupabaseClient _client;
  final LaropayStatusInvoker? _statusInvoker;
  final CurrentUserIdProvider? _currentUserIdProvider;
  final LaropayOrderLookup? _orderLookup;

  @override
  Future<List<LaropayPurchase>> getRecentPurchases() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const LaropayPurchaseAuthException();
    }

    final orders = await _ordersForUser(user.id);
    final orderIds = orders
        .map((item) => stringValue(item['id']))
        .where(isValidUuid)
        .toSet()
        .toList(growable: false);

    final paymentLinksByOrderId = orderIds.isEmpty
        ? const <String, Map<String, dynamic>>{}
        : await _paymentLinksByOrderId(orderIds, user.id);

    return orders
        .map((item) {
          final orderId = stringValue(item['id']);
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

    final order = _orderLookup != null
        ? await _orderLookup(normalizedId, userId)
        : await _orderForPaymentLink(normalizedId, userId);
    return _purchaseFromStatusResponse(data, order: order);
  }

  // Best-effort: the payment status refresh above already succeeded, so a
  // failure enriching it with order data (network hiccup, RLS edge case)
  // should not turn into a failed refresh -- it only feeds a UI fallback.
  Future<Map<String, dynamic>?> _orderForPaymentLink(
    String paymentLinkId,
    String userId,
  ) async {
    try {
      final response = await _client
          .from('laropay_payment_links')
          .select('''
            orders(order_number, payment_status, total_amount, paid_amount, remaining_amount)
          ''')
          .eq('id', paymentLinkId)
          .eq('user_id', userId)
          .maybeSingle();

      final order = response?['orders'];
      return order is Map<String, dynamic> ? order : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Map<String, dynamic>>> _paymentLinksByOrderId(
    List<String> orderIds,
    String userId,
  ) async {
    final linksByOrderId = <String, Map<String, dynamic>>{};
    for (final batch in _chunks(orderIds, _paymentLinkBatchSize)) {
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
          .inFilter('internal_transaction_id', batch)
          .order('created_at', ascending: false);

      for (final item in response) {
        final map = Map<String, dynamic>.from(item);
        final orderId = stringValue(map['internal_transaction_id']);
        linksByOrderId.putIfAbsent(orderId, () => map);
      }
    }

    return linksByOrderId;
  }

  Future<List<Map<String, dynamic>>> _ordersForUser(String userId) async {
    final orders = <Map<String, dynamic>>[];
    var offset = 0;

    while (true) {
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
          .eq('customers.user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + _ordersPageSize - 1);

      final page = response
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      orders.addAll(page);

      if (page.length < _ordersPageSize) {
        return orders;
      }

      offset += _ordersPageSize;
    }
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

    return LaropayPurchase(
      id: stringValue(order['id']),
      amount: numberValueOrNull(order['paid_amount']) ?? 0,
      currencyCode: 'CRC',
      detail: _orderTitle(order),
      linkId: '',
      status: _workshopPaymentStatus,
      responseCode: '',
      responseDescription: '',
      rejectReason: '',
      createdAt: DateTime.tryParse(stringValue(order['created_at'])),
      expiresAt: null,
      hasPaymentLink: false,
      orderNumber: nullableStringValue(order['order_number']),
      orderPaymentStatus: nullableStringValue(order['payment_status']),
      orderTotalAmount: numberValueOrNull(order['total_amount']),
      orderPaidAmount: numberValueOrNull(order['paid_amount']),
      orderRemainingAmount: numberValueOrNull(order['remaining_amount']),
    );
  }

  LaropayPurchase _purchaseFromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? order,
    String? fallbackDetail,
  }) {
    final detail = stringValue(map['detail']);
    return LaropayPurchase(
      id: stringValue(map['id']),
      amount: numberValueOrNull(map['amount']) ?? 0,
      currencyCode: stringValue(map['currency_code']).isEmpty
          ? 'CRC'
          : stringValue(map['currency_code']),
      detail: detail.isEmpty ? stringValue(fallbackDetail) : detail,
      linkId: stringValue(map['link_id']),
      linkUrl: _secureUri(map['link_url']),
      status: stringValue(map['status']),
      responseCode: stringValue(map['response_code']),
      responseDescription: stringValue(map['response_description']),
      rejectReason: stringValue(map['reject_reason']),
      createdAt: DateTime.tryParse(stringValue(map['created_at'])),
      expiresAt: DateTime.tryParse(stringValue(map['expires_at'])),
      hasPaymentLink: true,
      orderNumber: nullableStringValue(order?['order_number']),
      orderPaymentStatus: nullableStringValue(order?['payment_status']),
      orderTotalAmount: numberValueOrNull(order?['total_amount']),
      orderPaidAmount: numberValueOrNull(order?['paid_amount']),
      orderRemainingAmount: numberValueOrNull(order?['remaining_amount']),
    );
  }

  LaropayPurchase _purchaseFromStatusResponse(
    Map<String, dynamic> map, {
    Map<String, dynamic>? order,
  }) {
    final status = stringValue(map['status']);
    final linkUrl = _secureUri(_firstValue(map, 'link_url', 'linkURL'));
    if (_requiresPaymentLink(status) && linkUrl == null) {
      throw const LaropayPurchaseStatusException();
    }

    return LaropayPurchase(
      id: stringValue(map['id']),
      amount: numberValueOrNull(map['amount']) ?? 0,
      currencyCode:
          stringValue(_firstValue(map, 'currency_code', 'currencyCode')).isEmpty
          ? 'CRC'
          : stringValue(_firstValue(map, 'currency_code', 'currencyCode')),
      detail: stringValue(map['detail']),
      linkId: stringValue(_firstValue(map, 'link_id', 'linkID')),
      linkUrl: linkUrl,
      status: status,
      responseCode: stringValue(_firstValue(map, 'response_code', 'response')),
      responseDescription: stringValue(
        _firstValue(map, 'response_description', 'responseDescription'),
      ),
      rejectReason: stringValue(
        _firstValue(map, 'reject_reason', 'rejectReason'),
      ),
      createdAt: DateTime.tryParse(
        stringValue(_firstValue(map, 'created_at', 'createdAt')),
      ),
      expiresAt: DateTime.tryParse(
        stringValue(_firstValue(map, 'expires_at', 'expiresAt')),
      ),
      hasPaymentLink: true,
      orderNumber: nullableStringValue(order?['order_number']),
      orderPaymentStatus: nullableStringValue(order?['payment_status']),
      orderTotalAmount: numberValueOrNull(order?['total_amount']),
      orderPaidAmount: numberValueOrNull(order?['paid_amount']),
      orderRemainingAmount: numberValueOrNull(order?['remaining_amount']),
    );
  }
}

Object? _firstValue(Map<String, dynamic> map, String primary, String fallback) {
  return map[primary] ?? map[fallback];
}

String _orderTitle(Map<String, dynamic> order) {
  final workshopName = stringValue(_nestedValue(order['workshops'], 'name'));
  if (workshopName.isNotEmpty) {
    return workshopName;
  }

  final orderNumber = stringValue(order['order_number']);
  return orderNumber.isEmpty ? 'Orden' : orderNumber;
}

Object? _nestedValue(Object? value, String key) {
  if (value is Map) {
    return value[key];
  }

  return null;
}

Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
  for (var start = 0; start < values.length; start += size) {
    final end = start + size > values.length ? values.length : start + size;
    yield values.sublist(start, end);
  }
}

Uri? _secureUri(Object? value) {
  final uri = Uri.tryParse(stringValue(value));
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return null;
  }

  return uri;
}

bool _requiresPaymentLink(String status) {
  final normalizedStatus = status.trim().toLowerCase();
  return normalizedStatus == 'created' || normalizedStatus == 'pending';
}
