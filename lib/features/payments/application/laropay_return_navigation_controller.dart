import '../../../core/utils/uuid_validator.dart';

class LaropayReturnNavigationController {
  LaropayReturnNavigationController({
    required void Function(String location) navigate,
  }) : _navigate = navigate;

  static const _scheme = 'autolab';
  static const _host = 'laropay-callback';
  static const _path = '/payment-return';

  final void Function(String location) _navigate;

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
      _navigate('/purchases?paymentLinkId=$rawPaymentLinkId');
      return true;
    }

    final workshopId = uri.queryParameters['workshopId']?.trim() ?? '';
    if (!isValidUuid(workshopId)) {
      return false;
    }

    _navigate('/workshops/$workshopId?paymentLinkId=$rawPaymentLinkId');
    return true;
  }

  bool _isLaropayCallback(Uri uri) {
    return uri.scheme == _scheme && uri.host == _host && uri.path == _path;
  }
}
