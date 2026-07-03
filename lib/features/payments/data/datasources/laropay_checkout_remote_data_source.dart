import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/laropay_payment_context.dart';

abstract interface class LaropayCheckoutRemoteDataSource {
  Future<LaropayPaymentContext> getPaymentContext(String appointmentId);
}

class LaropayCheckoutAuthException implements Exception {
  const LaropayCheckoutAuthException();
}

class LaropayCheckoutContextException implements Exception {
  const LaropayCheckoutContextException();
}

class SupabaseLaropayCheckoutRemoteDataSource
    implements LaropayCheckoutRemoteDataSource {
  const SupabaseLaropayCheckoutRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<LaropayPaymentContext> getPaymentContext(String appointmentId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const LaropayCheckoutAuthException();
    }

    final response = await _client
        .from('appointments')
        .select('''
          id,
          order_services!inner(
            order_id,
            orders!inner(
              id,
              order_number,
              remaining_amount,
              total_amount,
              payment_status,
              customers!inner(user_id)
            )
          )
        ''')
        .eq('id', appointmentId)
        .eq('order_services.orders.customers.user_id', user.id)
        .maybeSingle();

    if (response == null) {
      throw const LaropayCheckoutContextException();
    }

    final orderService = _firstMapValue(response['order_services']);
    final order = _mapValue(orderService['orders']);
    final customer = _mapValue(order['customers']);
    if (_stringValue(customer['user_id']) != user.id) {
      throw const LaropayCheckoutContextException();
    }

    final orderId = _stringValue(orderService['order_id']).isNotEmpty
        ? _stringValue(orderService['order_id'])
        : _stringValue(order['id']);
    final amount = _paymentAmount(order);
    final profile = _userProfile(user);

    if (orderId.isEmpty || !amount.isFinite || amount <= 0) {
      throw const LaropayCheckoutContextException();
    }

    return LaropayPaymentContext(
      orderId: orderId,
      orderNumber: _nullableString(order['order_number']),
      amount: amount,
      customerFirstName: profile.firstName,
      customerLastName: profile.lastName,
      customerEmail: profile.email,
      customerPhone: profile.phone,
    );
  }

  static double _paymentAmount(Map<String, dynamic> order) {
    if (_stringValue(order['payment_status']).toLowerCase() != 'unpaid') {
      return double.nan;
    }

    final rawRemainingAmount = order['remaining_amount'];
    final remainingAmount = _numberValue(order['remaining_amount']);
    if (_hasStoredValue(rawRemainingAmount)) {
      return remainingAmount;
    }

    return _numberValue(order['total_amount']);
  }

  static _LaropayUserProfile _userProfile(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email?.trim().isNotEmpty == true
        ? user.email!.trim()
        : _stringValue(metadata['email']);
    final fullName = _stringValue(metadata['name']).isNotEmpty
        ? _stringValue(metadata['name'])
        : email.split('@').first;
    final names = fullName
        .split(RegExp(r'\s+'))
        .where((name) => name.trim().isNotEmpty)
        .toList();

    return _LaropayUserProfile(
      firstName: names.isEmpty ? 'Cliente' : names.first,
      lastName: names.length <= 1 ? 'Autolab' : names.skip(1).join(' '),
      email: email,
      phone: _nullableString(metadata['phone']),
    );
  }
}

class _LaropayUserProfile {
  const _LaropayUserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const {};
}

Map<String, dynamic> _firstMapValue(Object? value) {
  if (value is List && value.isNotEmpty) {
    return _mapValue(value.first);
  }

  return _mapValue(value);
}

String _stringValue(Object? value) {
  return value?.toString().trim() ?? '';
}

String? _nullableString(Object? value) {
  final text = _stringValue(value);
  return text.isEmpty ? null : text;
}

double _numberValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? double.nan;
}

bool _hasStoredValue(Object? value) {
  return value != null && value.toString().trim().isNotEmpty;
}
