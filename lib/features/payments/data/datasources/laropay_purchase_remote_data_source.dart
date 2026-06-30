import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/laropay_purchase.dart';

abstract interface class LaropayPurchaseRemoteDataSource {
  Future<List<LaropayPurchase>> getRecentPurchases();
}

class LaropayPurchaseAuthException implements Exception {
  const LaropayPurchaseAuthException();
}

class SupabaseLaropayPurchaseRemoteDataSource
    implements LaropayPurchaseRemoteDataSource {
  const SupabaseLaropayPurchaseRemoteDataSource(this._client);

  final SupabaseClient _client;

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

    return response
        .whereType<Map>()
        .map((item) => _purchaseFromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
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
      linkUrl: Uri.tryParse(_stringValue(map['link_url'])),
      status: _stringValue(map['status']),
      responseCode: _stringValue(map['response_code']),
      responseDescription: _stringValue(map['response_description']),
      rejectReason: _stringValue(map['reject_reason']),
      createdAt: DateTime.tryParse(_stringValue(map['created_at'])),
      expiresAt: DateTime.tryParse(_stringValue(map['expires_at'])),
    );
  }
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';

double _numberValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(_stringValue(value)) ?? 0;
}
