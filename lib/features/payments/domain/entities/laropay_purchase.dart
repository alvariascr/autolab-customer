class LaropayPurchase {
  const LaropayPurchase({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.detail,
    required this.linkId,
    required this.status,
    required this.responseCode,
    required this.responseDescription,
    required this.rejectReason,
    required this.createdAt,
    required this.expiresAt,
    this.linkUrl,
  });

  final String id;
  final double amount;
  final String currencyCode;
  final String detail;
  final String linkId;
  final String status;
  final String responseCode;
  final String responseDescription;
  final String rejectReason;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final Uri? linkUrl;
}
