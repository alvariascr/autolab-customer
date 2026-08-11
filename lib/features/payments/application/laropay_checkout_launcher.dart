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
    final paymentContext = await (await _getPaymentContext(appointmentId)).fold(
      (failure) async =>
          throw LaropayCheckoutLaunchException(_failureMessage(failure)),
      (context) async => context,
    );
    if (!chargeableAmount.isFinite || chargeableAmount <= 0) {
      throw const LaropayCheckoutLaunchException(
        'No hay productos cobrables para generar el link de pago.',
      );
    }

    await _launchPayment(
      paymentContext: paymentContext,
      amount: chargeableAmount,
      document: paymentContext.orderNumber ?? appointmentId,
      workshopName: workshopName,
    );
  }

  Future<void> launchForOrder({required String orderId}) async {
    final paymentContext = await (await _getPaymentContext.forOrder(orderId))
        .fold(
          (failure) async =>
              throw LaropayCheckoutLaunchException(_failureMessage(failure)),
          (context) async => context,
        );

    await _launchPayment(
      paymentContext: paymentContext,
      amount: paymentContext.amount,
      document: paymentContext.orderNumber ?? orderId,
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
        'No hay productos cobrables para generar el link de pago.',
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

    await result.fold(
      (failure) async =>
          throw LaropayCheckoutLaunchException(_failureMessage(failure)),
      (link) async {
        final opened = await _launchExternalUrl(link.linkUrl);
        if (!opened) {
          throw LaropayCheckoutLaunchException(
            'No fue posible abrir el navegador seguro de Laropay.',
            linkUrl: link.linkUrl,
          );
        }
      },
    );
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
