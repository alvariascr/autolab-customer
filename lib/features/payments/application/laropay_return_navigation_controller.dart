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

    final workshopId = uri.queryParameters['workshopId']?.trim() ?? '';
    if (!_isUuid(workshopId)) {
      return false;
    }

    _navigate('/workshops/$workshopId?payment=pending');
    return true;
  }

  bool _isLaropayCallback(Uri uri) {
    return uri.scheme == _scheme && uri.host == _host && uri.path == _path;
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
  }
}
