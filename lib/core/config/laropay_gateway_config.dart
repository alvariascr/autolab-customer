class LaropayGatewayConfig {
  const LaropayGatewayConfig({
    required this.generateLinkUri,
    this.timeout = const Duration(seconds: 15),
  });

  factory LaropayGatewayConfig.fromEnvironment() {
    final uriValue = const String.fromEnvironment(
      'LAROPAY_GENERATE_LINK_URL',
    ).trim();

    if (uriValue.isEmpty) {
      return const LaropayGatewayConfig(generateLinkUri: null);
    }

    return LaropayGatewayConfig(generateLinkUri: Uri.tryParse(uriValue));
  }

  final Uri? generateLinkUri;
  final Duration timeout;

  bool get isConfigured =>
      generateLinkUri?.isScheme('https') == true &&
      generateLinkUri?.host.isNotEmpty == true;
}
