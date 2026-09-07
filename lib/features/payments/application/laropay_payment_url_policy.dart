class LaropayPaymentUrlPolicy {
  const LaropayPaymentUrlPolicy._();

  // Comma-separated list of hosts allowed to reopen a Laropay payment link,
  // supplied per-environment via --dart-define-from-file (see
  // .env.development.json / .env.production.json and scripts/run_*.ps1).
  // Hardcoding only the dev gateway here meant "reopen my payment link"
  // would always fail in any environment pointed at the real production
  // gateway, since its host was never in the allowlist.
  static const String _allowedHostsEnv = String.fromEnvironment(
    'LAROPAY_GATEWAY_HOSTS',
  );

  static final Set<String> _allowedHosts = _buildAllowedHosts();

  static Set<String> _buildAllowedHosts() {
    final hosts = _allowedHostsEnv
        .split(',')
        .map((host) => host.trim().toLowerCase())
        .where((host) => host.isNotEmpty)
        .toSet();

    assert(
      hosts.isNotEmpty,
      'LAROPAY_GATEWAY_HOSTS no está configurado para este build; '
      '"reabrir mi link de pago" fallará siempre hasta que se defina.',
    );

    return hosts;
  }

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
