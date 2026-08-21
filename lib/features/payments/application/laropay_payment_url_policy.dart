class LaropayPaymentUrlPolicy {
  const LaropayPaymentUrlPolicy._();

  static const Set<String> _allowedHosts = {
    'larodevsecuregateway.azurewebsites.net',
  };

  static bool isAllowed(Uri? uri) {
    if (uri == null || !uri.isScheme('https')) {
      return false;
    }

    if (uri.userInfo.isNotEmpty || uri.hasPort) {
      return false;
    }

    return _allowedHosts.contains(uri.host.toLowerCase());
  }
}
