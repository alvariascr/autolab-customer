import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/laropay_payment_context.dart';

abstract interface class LaropayCheckoutRemoteDataSource {
  Future<LaropayPaymentContext> getPaymentContext(String appointmentId);

  Future<LaropayPaymentContext> getOrderPaymentContext(String orderId);
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
    final profile = _userProfile(user);

    if (orderId.isEmpty ||
        _stringValue(order['payment_status']).toLowerCase() != 'unpaid') {
      throw const LaropayCheckoutContextException();
    }

    return LaropayPaymentContext(
      orderId: orderId,
      orderNumber: _nullableString(order['order_number']),
      amount: 0,
      customerFirstName: profile.firstName,
      customerLastName: profile.lastName,
      customerEmail: profile.email,
      customerPhone: profile.phone,
    );
  }

  @override
  Future<LaropayPaymentContext> getOrderPaymentContext(String orderId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const LaropayCheckoutAuthException();
    }

    final response = await _client
        .from('orders')
        .select('''
          id,
          order_number,
          payment_status,
          total_amount,
          customers!inner(
            user_id,
            name,
            email,
            phone
          ),
          workshops(
            name
          )
        ''')
        .eq('id', orderId)
        .eq('customers.user_id', user.id)
        .maybeSingle();

    if (response == null) {
      throw const LaropayCheckoutContextException();
    }

    final customer = _mapValue(response['customers']);
    if (_stringValue(customer['user_id']) != user.id) {
      throw const LaropayCheckoutContextException();
    }

    if (_stringValue(response['payment_status']).toLowerCase() != 'unpaid') {
      throw const LaropayCheckoutContextException();
    }

    final amount = _numberValue(response['total_amount']);
    if (!amount.isFinite || amount <= 0) {
      throw const LaropayCheckoutContextException();
    }

    final profile = _customerProfile(customer, user);
    final workshop = _mapValue(response['workshops']);

    return LaropayPaymentContext(
      orderId: _stringValue(response['id']),
      orderNumber: _nullableString(response['order_number']),
      amount: amount,
      customerFirstName: profile.firstName,
      customerLastName: profile.lastName,
      customerEmail: profile.email,
      customerPhone: profile.phone,
      workshopName: _nullableString(workshop['name']),
    );
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

  static _LaropayUserProfile _customerProfile(
    Map<String, dynamic> customer,
    User user,
  ) {
    final fallback = _userProfile(user);
    final email = _stringValue(customer['email']).isNotEmpty
        ? _stringValue(customer['email'])
        : fallback.email;
    final fullName = _stringValue(customer['name']).isNotEmpty
        ? _stringValue(customer['name'])
        : '${fallback.firstName} ${fallback.lastName}'.trim();
    final names = fullName
        .split(RegExp(r'\s+'))
        .where((name) => name.trim().isNotEmpty)
        .toList();

    return _LaropayUserProfile(
      firstName: names.isEmpty ? fallback.firstName : names.first,
      lastName: names.length <= 1 ? fallback.lastName : names.skip(1).join(' '),
      email: email,
      phone: _nullableString(customer['phone']) ?? fallback.phone,
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

  if (value is String) {
    return double.tryParse(value.trim()) ?? double.nan;
  }

  return double.nan;
}
