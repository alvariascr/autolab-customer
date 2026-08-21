import 'package:flutter/foundation.dart';

import '../../../core/utils/uuid_validator.dart';

class LaropayReturnNavigationController {
  LaropayReturnNavigationController({
    required void Function(String location) navigate,
  }) : _navigate = navigate;

  static const _scheme = 'autolab';
  static const _host = 'laropay-callback';
  static const _path = '/payment-return';

  final void Function(String location) _navigate;

  // Bumped synchronously the instant a real Laropay deep-link callback is
  // handled, before navigation happens. Checkout pages waiting to decide
  // "gateway closed abruptly" vs. "a real result arrived" compare this
  // against a baseline captured before launching the gateway, so a callback
  // that arrives just as (or slightly after) their own fallback timer fires
  // is never mistaken for an abrupt close.
  static final ValueNotifier<int> handledCallbackCount = ValueNotifier<int>(0);

  bool handleAppLink(Uri uri) {
    if (!_isLaropayCallback(uri)) {
      return false;
    }

    final rawPaymentLinkId = uri.queryParameters['paymentLinkId']?.trim() ?? '';
    if (!isValidUuid(rawPaymentLinkId)) {
      return false;
    }

    final target = uri.queryParameters['target']?.trim();
    if (target == 'purchases') {
      handledCallbackCount.value++;
      _navigate(
        Uri(
          path: '/purchases',
          queryParameters: {'paymentLinkId': rawPaymentLinkId},
        ).toString(),
      );
      return true;
    }

    final workshopId = uri.queryParameters['workshopId']?.trim() ?? '';
    if (!isValidUuid(workshopId)) {
      return false;
    }

    handledCallbackCount.value++;
    _navigate(
      Uri(
        path: '/workshops/$workshopId',
        queryParameters: {'paymentLinkId': rawPaymentLinkId},
      ).toString(),
    );
    return true;
  }

  bool _isLaropayCallback(Uri uri) {
    return uri.scheme == _scheme && uri.host == _host && uri.path == _path;
  }
}
