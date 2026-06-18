class LaropayGatewayConfig {
  const LaropayGatewayConfig({
    required this.generateLinkUri,
    this.timeout = const Duration(seconds: 15),
  });

  factory LaropayGatewayConfig.fromEnvironment() {
    final uriValue = const String.fromEnvironment(
      'LAROPAY_GENERATE_LINK_URL',
    ).trim();

    return LaropayGatewayConfig(
      generateLinkUri: uriValue.isEmpty ? null : Uri.tryParse(uriValue),
    );
  }

  final Uri? generateLinkUri;
  final Duration timeout;

  bool get isConfigured {
    final uri = generateLinkUri;
    return uri != null && uri.isScheme('https') && uri.host.isNotEmpty;
  }
}
