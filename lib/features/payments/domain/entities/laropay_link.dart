class LaropayLink {
  const LaropayLink({
    required this.linkId,
    required this.linkUrl,
    required this.response,
    required this.responseDescription,
    this.status,
    this.rejectReason,
    this.authResponseCode,
  });

  final String linkId;
  final Uri linkUrl;
  final String response;
  final String responseDescription;
  final String? status;
  final String? rejectReason;
  final String? authResponseCode;
}
