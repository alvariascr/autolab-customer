class LaropayLinkRequest {
  const LaropayLinkRequest({
    required this.internalTransactionId,
    required this.idTransaction,
    required this.amount,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerEmail,
    this.document,
    this.detail,
    this.customerPhone,
    this.customerLocation,
    this.expirationType = 'D',
    this.expirationValue = 1,
    this.urlCallback,
    this.securityCode,
  });

  final String internalTransactionId;
  final int idTransaction;
  final double amount;
  final String? document;
  final String? detail;
  final String customerFirstName;
  final String customerLastName;
  final String customerEmail;
  final String? customerPhone;
  final String? customerLocation;
  final String expirationType;
  final int expirationValue;
  final Uri? urlCallback;
  final String? securityCode;

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
      if (urlCallback != null) 'urlCallback': urlCallback.toString(),
      if (_hasValue(securityCode)) 'securityCode': securityCode!.trim(),
    };
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}
