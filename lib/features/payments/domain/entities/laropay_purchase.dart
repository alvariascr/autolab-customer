enum LaropayPurchaseState {
  pending,
  partial,
  approved,
  cancelled,
  rejected,
  expired,
  workshopPayment,
  unknown,
}

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
    this.hasPaymentLink = true,
    this.orderNumber,
    this.orderPaymentStatus,
    this.orderTotalAmount,
    this.orderPaidAmount,
    this.orderRemainingAmount,
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
  final bool hasPaymentLink;
  final String? orderNumber;
  final String? orderPaymentStatus;
  final double? orderTotalAmount;
  final double? orderPaidAmount;
  final double? orderRemainingAmount;

  bool get canReopenLink {
    return hasPaymentLink &&
        linkUrl != null &&
        purchaseState == LaropayPurchaseState.pending;
  }

  bool get canRefreshStatus {
    return hasPaymentLink && purchaseState == LaropayPurchaseState.pending;
  }

  LaropayPurchaseState get purchaseState {
    if (hasPaymentLink && hasOutstandingBalance && isLaropayApproved) {
      return LaropayPurchaseState.partial;
    }

    if (!hasPaymentLink && hasOutstandingBalance) {
      return LaropayPurchaseState.workshopPayment;
    }

    final normalizedStatus = status.toLowerCase().trim();
    final normalizedResponse = responseCode.toLowerCase().trim();
    final normalizedDescription = responseDescription.toLowerCase().trim();

    if (normalizedStatus == 'expired') {
      return LaropayPurchaseState.expired;
    }

    if (normalizedStatus == 'paid' ||
        normalizedStatus == 'approved' ||
        normalizedStatus == 'completed') {
      return LaropayPurchaseState.approved;
    }

    if (normalizedStatus == 'cancelled' || normalizedStatus == 'canceled') {
      return LaropayPurchaseState.cancelled;
    }

    if (normalizedStatus == 'rejected' ||
        normalizedStatus == 'failed' ||
        normalizedStatus == 'error') {
      return LaropayPurchaseState.rejected;
    }

    if (normalizedStatus == 'created' ||
        normalizedStatus == 'pending' ||
        normalizedStatus.isEmpty) {
      if (expiresAt != null && expiresAt!.isBefore(DateTime.now().toUtc())) {
        return LaropayPurchaseState.expired;
      }

      return LaropayPurchaseState.pending;
    }

    if ((normalizedResponse.isNotEmpty && normalizedResponse != '00') ||
        normalizedDescription.contains('rechaz')) {
      return LaropayPurchaseState.rejected;
    }

    return LaropayPurchaseState.unknown;
  }

  bool get isLaropayApproved {
    final normalizedStatus = status.toLowerCase().trim();
    return normalizedStatus == 'paid' ||
        normalizedStatus == 'approved' ||
        normalizedStatus == 'completed';
  }

  bool get hasOrderAmounts {
    return orderTotalAmount != null ||
        orderPaidAmount != null ||
        orderRemainingAmount != null;
  }

  bool get hasOutstandingBalance {
    return (orderRemainingAmount ?? 0) > 0;
  }
}
