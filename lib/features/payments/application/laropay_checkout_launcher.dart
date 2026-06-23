import 'package:autolab_core/autolab_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/entities/laropay_link_request.dart';
import '../domain/usecases/generate_laropay_link.dart';

typedef LaropayExternalUrlLauncher = Future<bool> Function(Uri uri);

class LaropayCheckoutLauncher {
  LaropayCheckoutLauncher({
    required GenerateLaropayLink generateLaropayLink,
    required SupabaseClient supabase,
    LaropayExternalUrlLauncher? launchExternalUrl,
  }) : _generateLaropayLink = generateLaropayLink,
       _supabase = supabase,
       _launchExternalUrl = launchExternalUrl ?? _launchInBrowser;

  final GenerateLaropayLink _generateLaropayLink;
  final SupabaseClient _supabase;
  final LaropayExternalUrlLauncher _launchExternalUrl;

  Future<void> launch({
    required String appointmentId,
    required String workshopName,
  }) async {
    final paymentContext = await _loadPaymentContext(appointmentId);
    final result = await _generateLaropayLink(
      LaropayLinkRequest(
        internalTransactionId: paymentContext.orderId,
        idTransaction: 1,
        amount: paymentContext.amount,
        document: paymentContext.orderNumber ?? appointmentId,
        detail: 'Autolab $workshopName',
        customerFirstName: paymentContext.customerFirstName,
        customerLastName: paymentContext.customerLastName,
        customerEmail: paymentContext.customerEmail,
        customerPhone: paymentContext.customerPhone,
        customerLocation: workshopName,
        expirationType: 'D',
        expirationValue: 1,
      ),
    );

    await result.fold(
      (failure) async =>
          throw LaropayCheckoutLaunchException(_failureMessage(failure)),
      (link) async {
        final opened = await _launchExternalUrl(link.linkUrl);
        if (!opened) {
          throw const LaropayCheckoutLaunchException(
            'No fue posible abrir el navegador seguro de Laropay.',
          );
        }
      },
    );
  }

  Future<_LaropayPaymentContext> _loadPaymentContext(
    String appointmentId,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const LaropayCheckoutLaunchException(
        'Inicia sesión nuevamente para continuar con el pago.',
      );
    }

    final response = await _supabase
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
              customers!inner(user_id)
            )
          )
        ''')
        .eq('id', appointmentId)
        .eq('order_services.orders.customers.user_id', user.id)
        .single();

    final payload = _mapValue(response);
    final orderService = _mapValue(payload['order_services']);
    final order = _mapValue(orderService['orders']);
    final orderId = _stringValue(orderService['order_id']).isNotEmpty
        ? _stringValue(orderService['order_id'])
        : _stringValue(order['id']);
    final amount = _paymentAmount(order);
    final profile = _userProfile(user);

    if (orderId.isEmpty || !amount.isFinite || amount <= 0) {
      throw const LaropayCheckoutLaunchException(
        'La orden no tiene un monto pendiente válido para pagar.',
      );
    }

    return _LaropayPaymentContext(
      orderId: orderId,
      orderNumber: _nullableString(order['order_number']),
      amount: amount,
      customerFirstName: profile.firstName,
      customerLastName: profile.lastName,
      customerEmail: profile.email,
      customerPhone: profile.phone,
    );
  }

  static Future<bool> _launchInBrowser(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static double _paymentAmount(Map<String, dynamic> order) {
    final remainingAmount = _numberValue(order['remaining_amount']);
    return remainingAmount > 0
        ? remainingAmount
        : _numberValue(order['total_amount']);
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

  static String _failureMessage(Failure failure) {
    final message = failure.message.trim();
    return message.isEmpty
        ? 'No fue posible generar el link de pago. Intenta nuevamente.'
        : message;
  }
}

class LaropayCheckoutLaunchException implements Exception {
  const LaropayCheckoutLaunchException(this.message);

  final String message;
}

class _LaropayPaymentContext {
  const _LaropayPaymentContext({
    required this.orderId,
    required this.amount,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerEmail,
    this.orderNumber,
    this.customerPhone,
  });

  final String orderId;
  final String? orderNumber;
  final double amount;
  final String customerFirstName;
  final String customerLastName;
  final String customerEmail;
  final String? customerPhone;
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
