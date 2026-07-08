class LaropayReturnNavigationController {
  LaropayReturnNavigationController({
    required void Function(String location) navigate,
    Future<String?> Function(String paymentLinkId)? refreshPaymentStatus,
  }) : _navigate = navigate,
       _refreshPaymentStatus = refreshPaymentStatus;

  static const _scheme = 'autolab';
  static const _host = 'laropay-callback';
  static const _path = '/payment-return';
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final void Function(String location) _navigate;
  final Future<String?> Function(String paymentLinkId)? _refreshPaymentStatus;

  Future<bool> handleAppLink(Uri uri) async {
    if (!_isLaropayCallback(uri)) {
      return false;
    }

    final workshopId = uri.queryParameters['workshopId']?.trim() ?? '';
    if (!_isUuid(workshopId)) {
      return false;
    }

    final rawPaymentLinkId = uri.queryParameters['paymentLinkId']?.trim() ?? '';
    final paymentLinkId = _isUuid(rawPaymentLinkId) ? rawPaymentLinkId : '';
    final paymentStatus = paymentLinkId.isNotEmpty
        ? await _resolvePaymentStatus(paymentLinkId)
        : 'pending';
    final paymentLinkQuery = paymentLinkId.isEmpty
        ? ''
        : '&paymentLinkId=$paymentLinkId';

    _navigate(
      '/workshops/$workshopId'
      '?payment=$paymentStatus'
      '$paymentLinkQuery',
    );
    return true;
  }

  bool _isLaropayCallback(Uri uri) {
    return uri.scheme == _scheme && uri.host == _host && uri.path == _path;
  }

  bool _isUuid(String value) {
    return _uuidRegex.hasMatch(value);
  }

  Future<String> _resolvePaymentStatus(String paymentLinkId) async {
    try {
      final status = await _refreshPaymentStatus?.call(paymentLinkId);
      return _normalizePaymentStatus(status);
    } catch (_) {
      return 'pending';
    }
  }

  String _normalizePaymentStatus(String? status) {
    return switch (status?.trim().toLowerCase()) {
      'paid' || 'approved' || 'completed' => 'paid',
      'rejected' || 'failed' || 'cancelled' || 'canceled' => 'rejected',
      'expired' => 'expired',
      _ => 'pending',
    };
  }
}
