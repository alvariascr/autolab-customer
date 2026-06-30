import 'package:flutter/foundation.dart';

@immutable
class LaropayLinkRequest {
  const LaropayLinkRequest({
    required this.internalTransactionId,
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
  });

  final String internalTransactionId;
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
}
