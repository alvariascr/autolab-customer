class LaropayReturnNavigationController {
  LaropayReturnNavigationController({
    required void Function(String location) navigate,
  }) : _navigate = navigate;

  static const _scheme = 'autolab';
  static const _host = 'laropay-callback';
  static const _path = '/payment-return';
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final void Function(String location) _navigate;

  bool handleAppLink(Uri uri) {
    if (!_isLaropayCallback(uri)) {
      return false;
    }

    final rawPaymentLinkId = uri.queryParameters['paymentLinkId']?.trim() ?? '';
    if (!_isUuid(rawPaymentLinkId)) {
      return false;
    }

    final target = uri.queryParameters['target']?.trim();
    if (target == 'purchases') {
      _navigate('/purchases?paymentLinkId=$rawPaymentLinkId');
      return true;
    }

    final workshopId = uri.queryParameters['workshopId']?.trim() ?? '';
    if (!_isUuid(workshopId)) {
      return false;
    }

    _navigate('/workshops/$workshopId?paymentLinkId=$rawPaymentLinkId');
    return true;
  }

  bool _isLaropayCallback(Uri uri) {
    return uri.scheme == _scheme && uri.host == _host && uri.path == _path;
  }

  bool _isUuid(String value) {
    return _uuidRegex.hasMatch(value);
  }
}
