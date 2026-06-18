import '../../domain/entities/laropay_link.dart';

class LaropayLinkModel extends LaropayLink {
  const LaropayLinkModel({
    required super.linkId,
    required super.linkUrl,
    required super.response,
    required super.responseDescription,
    super.status,
    super.rejectReason,
    super.authResponseCode,
  });

  factory LaropayLinkModel.fromJson(Map<String, dynamic> json) {
    final linkId = json['linkID']?.toString().trim() ?? '';
    final linkUrlValue = json['linkURL']?.toString().trim() ?? '';
    final response = json['response']?.toString().trim() ?? '';
    final responseDescription =
        json['responseDescription']?.toString().trim() ?? '';
    final linkUrl = Uri.tryParse(linkUrlValue);
    final isValidSecureUrl =
        linkUrl != null && linkUrl.isScheme('https') && linkUrl.host.isNotEmpty;

    if (linkId.isEmpty ||
        !isValidSecureUrl ||
        response.isEmpty ||
        responseDescription.isEmpty) {
      throw const FormatException(
        'Laropay response missing linkID, secure HTTPS linkURL or response metadata',
      );
    }

    return LaropayLinkModel(
      linkId: linkId,
      linkUrl: linkUrl,
      response: response,
      responseDescription: responseDescription,
      status: json['status']?.toString(),
      rejectReason: json['rejectReason']?.toString(),
      authResponseCode: json['authResponseCode']?.toString(),
    );
  }
}
