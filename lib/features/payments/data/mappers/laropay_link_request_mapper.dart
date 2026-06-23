import '../../domain/entities/laropay_link_request.dart';

extension LaropayLinkRequestMapper on LaropayLinkRequest {
  Map<String, dynamic> toGatewayJson() {
    return {
      'internalTransactionId': internalTransactionId.trim(),
      'idTransaction': idTransaction,
      'amount': amount,
      if (_hasValue(document)) 'document': document!.trim(),
      if (_hasValue(detail)) 'detail': detail!.trim(),
      'customerFirstName': customerFirstName.trim(),
      'customerLastName': customerLastName.trim(),
      'customerEmail': customerEmail.trim(),
      if (_hasValue(customerPhone)) 'customerPhone': customerPhone!.trim(),
      if (_hasValue(customerLocation))
        'customerLocation': customerLocation!.trim(),
      'expirationType': expirationType.trim().toUpperCase(),
      'expirationValue': expirationValue,
    };
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}
