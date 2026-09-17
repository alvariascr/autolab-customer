import 'package:autolab_core/autolab_core.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../domain/entities/laropay_link_request.dart';
import '../domain/entities/laropay_payment_context.dart';
import '../domain/usecases/generate_laropay_link.dart';
import '../domain/usecases/get_laropay_payment_context.dart';

typedef LaropayExternalUrlLauncher = Future<bool> Function(Uri uri);

class LaropayCheckoutSession {
  const LaropayCheckoutSession({required this.paymentLinkId});

  final String paymentLinkId;
}

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

  Future<LaropayCheckoutSession> launch({
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

    return _launchPayment(
      paymentContext: paymentContext,
      amount: chargeableAmount,
      document: _documentFromContext(paymentContext, appointmentId),
      workshopName: workshopName,
    );
  }

  Future<LaropayCheckoutSession> launchForOrder({
    required String orderId,
  }) async {
    final contextResult = await _getPaymentContext.forOrder(orderId);
    final paymentContext = contextResult.fold((failure) {
      throw LaropayCheckoutLaunchException(_failureMessage(failure));
    }, (context) => context);

    return _launchPayment(
      paymentContext: paymentContext,
      amount: paymentContext.amount,
      document: _documentFromContext(paymentContext, orderId),
      workshopName: paymentContext.workshopName ?? 'Autolab',
    );
  }

  Future<LaropayCheckoutSession> _launchPayment({
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

    final link = result.fold((failure) {
      throw LaropayCheckoutLaunchException(_failureMessage(failure));
    }, (link) => link);

    final opened = await _launchExternalUrl(link.linkUrl);
    if (!opened) {
      throw LaropayCheckoutLaunchException(
        'No fue posible abrir el navegador seguro de Laropay.',
        linkUrl: link.linkUrl,
      );
    }

    return LaropayCheckoutSession(paymentLinkId: link.paymentLinkId);
  }

  static String _documentFromContext(
    LaropayPaymentContext paymentContext,
    String fallback,
  ) {
    final orderNumber = paymentContext.orderNumber?.trim() ?? '';
    return orderNumber.isEmpty ? fallback : orderNumber;
  }

  static Future<bool> _launchInBrowser(Uri uri) async {
    final url = uri.toString();
    try {
      final openedInAppBrowser = await launchUrlString(
        url,
        mode: LaunchMode.inAppBrowserView,
      );
      if (openedInAppBrowser) {
        return true;
      }
    } on Exception {
      // Fall back to an external browser below. Some Android environments do
      // not expose Custom Tabs even when a regular browser is installed.
    }

    try {
      final openedExternal = await launchUrlString(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (openedExternal) {
        return true;
      }
    } on Exception {
      // Fall back to the platform default below. Some Android environments
      // reject external browser launches even when the URL itself is valid.
    }

    try {
      final openedDefault = await launchUrlString(
        url,
        mode: LaunchMode.platformDefault,
      );
      return openedDefault;
    } on Exception {
      return false;
    }
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
