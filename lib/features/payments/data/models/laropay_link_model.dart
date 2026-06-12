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
    final linkUrl = Uri.tryParse(linkUrlValue);

    if (linkId.isEmpty || linkUrl == null || !linkUrl.hasScheme) {
      throw const FormatException('Laropay response missing linkID/linkURL');
    }

    return LaropayLinkModel(
      linkId: linkId,
      linkUrl: linkUrl,
      response: json['response']?.toString() ?? '',
      responseDescription: json['responseDescription']?.toString() ?? '',
      status: json['status']?.toString(),
      rejectReason: json['rejectReason']?.toString(),
      authResponseCode: json['authResponseCode']?.toString(),
    );
  }
}
