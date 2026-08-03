import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/laropay_purchase.dart';

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
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return response.map(_purchaseFromMap).toList(growable: false);
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

  LaropayPurchase _purchaseFromMap(Map<String, dynamic> map) {
    return LaropayPurchase(
      id: _stringValue(map['id']),
      amount: _numberValue(map['amount']),
      currencyCode: _stringValue(map['currency_code']).isEmpty
          ? 'CRC'
          : _stringValue(map['currency_code']),
      detail: _stringValue(map['detail']),
      linkId: _stringValue(map['link_id']),
      linkUrl: _secureUri(map['link_url']),
      status: _stringValue(map['status']),
      responseCode: _stringValue(map['response_code']),
      responseDescription: _stringValue(map['response_description']),
      rejectReason: _stringValue(map['reject_reason']),
      createdAt: DateTime.tryParse(_stringValue(map['created_at'])),
      expiresAt: DateTime.tryParse(_stringValue(map['expires_at'])),
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
    );
  }
}

Object? _firstValue(Map<String, dynamic> map, String primary, String fallback) {
  return map[primary] ?? map[fallback];
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';

double _numberValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(_stringValue(value)) ?? 0;
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
