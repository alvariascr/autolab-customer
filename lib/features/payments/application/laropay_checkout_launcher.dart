import 'package:autolab_core/autolab_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/entities/laropay_link_request.dart';
import '../domain/entities/laropay_payment_context.dart';
import '../domain/usecases/generate_laropay_link.dart';
import '../domain/usecases/get_laropay_payment_context.dart';

typedef LaropayExternalUrlLauncher = Future<bool> Function(Uri uri);

class LaropayCheckoutLauncher {
  LaropayCheckoutLauncher({
    required GenerateLaropayLink generateLaropayLink,
    required GetLaropayPaymentContext getPaymentContext,
    LaropayExternalUrlLauncher? launchExternalUrl,
  }) : _generateLaropayLink = generateLaropayLink,
       _getPaymentContext = getPaymentContext,
       _launchExternalUrl = launchExternalUrl ?? _launchInBrowser;

  final GenerateLaropayLink _generateLaropayLink;
  final GetLaropayPaymentContext _getPaymentContext;
  final LaropayExternalUrlLauncher _launchExternalUrl;

  Future<void> launch({
    required String appointmentId,
    required String workshopName,
    required double chargeableAmount,
  }) async {
    final contextResult = await _getPaymentContext(appointmentId);
    final paymentContext = contextResult.fold(
      (failure) =>
          throw LaropayCheckoutLaunchException(_failureMessage(failure)),
      (context) => context,
    );

    if (!chargeableAmount.isFinite || chargeableAmount <= 0) {
      throw const LaropayCheckoutLaunchException(
        'El monto a cobrar debe ser mayor a cero para generar el link de pago.',
      );
    }

    await _launchPayment(
      paymentContext: paymentContext,
      amount: chargeableAmount,
      document: _documentFromContext(paymentContext, appointmentId),
      workshopName: workshopName,
    );
  }

  Future<void> launchForOrder({required String orderId}) async {
    final contextResult = await _getPaymentContext.forOrder(orderId);
    final paymentContext = contextResult.fold(
      (failure) =>
          throw LaropayCheckoutLaunchException(_failureMessage(failure)),
      (context) => context,
    );

    await _launchPayment(
      paymentContext: paymentContext,
      amount: paymentContext.amount,
      document: _documentFromContext(paymentContext, orderId),
      workshopName: paymentContext.workshopName ?? 'Autolab',
    );
  }

  Future<void> _launchPayment({
    required LaropayPaymentContext paymentContext,
    required double amount,
    required String document,
    required String workshopName,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw const LaropayCheckoutLaunchException(
        'El monto a cobrar debe ser mayor a cero para generar el link de pago.',
      );
    }

    final result = await _generateLaropayLink(
      LaropayLinkRequest(
        internalTransactionId: paymentContext.orderId,
        amount: amount,
        document: document,
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

    final link = result.fold(
      (failure) =>
          throw LaropayCheckoutLaunchException(_failureMessage(failure)),
      (link) => link,
    );

    final opened = await _launchExternalUrl(link.linkUrl);
    if (!opened) {
      throw LaropayCheckoutLaunchException(
        'No fue posible abrir el navegador seguro de Laropay.',
        linkUrl: link.linkUrl,
      );
    }
  }

  static String _documentFromContext(
    LaropayPaymentContext paymentContext,
    String fallback,
  ) {
    final orderNumber = paymentContext.orderNumber?.trim() ?? '';
    return orderNumber.isEmpty ? fallback : orderNumber;
  }

  static Future<bool> _launchInBrowser(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _failureMessage(Failure failure) {
    final message = failure.message.trim();
    return message.isEmpty
        ? 'No fue posible generar el link de pago. Intenta nuevamente.'
        : message;
  }
}

class LaropayCheckoutLaunchException implements Exception {
  const LaropayCheckoutLaunchException(this.message, {this.linkUrl});

  final String message;
  final Uri? linkUrl;
}
