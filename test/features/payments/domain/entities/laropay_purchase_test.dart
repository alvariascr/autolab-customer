import 'package:autolab_customer/features/payments/domain/entities/laropay_purchase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LaropayPurchase business state', () {
    test('marks pending payment links as reopenable and refreshable', () {
      final purchase = _purchase(status: 'pending');

      expect(purchase.purchaseState, LaropayPurchaseState.pending);
      expect(purchase.canReopenLink, isTrue);
      expect(purchase.canRefreshStatus, isTrue);
    });

    test('marks paid purchases as approved without retry actions', () {
      final purchase = _purchase(status: 'paid');

      expect(purchase.purchaseState, LaropayPurchaseState.approved);
      expect(purchase.isLaropayApproved, isTrue);
      expect(purchase.canReopenLink, isFalse);
      expect(purchase.canRefreshStatus, isFalse);
    });

    test('marks paid online purchases with workshop balance as partial', () {
      final purchase = _purchase(status: 'paid', orderRemainingAmount: 4500);

      expect(purchase.purchaseState, LaropayPurchaseState.partial);
      expect(purchase.hasOutstandingBalance, isTrue);
    });

    test('marks expired pending links as expired', () {
      final purchase = _purchase(
        status: 'pending',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );

      expect(purchase.purchaseState, LaropayPurchaseState.expired);
      expect(purchase.canReopenLink, isFalse);
      expect(purchase.canRefreshStatus, isFalse);
    });
  });
}

LaropayPurchase _purchase({
  required String status,
  DateTime? expiresAt,
  double? orderRemainingAmount,
}) {
  return LaropayPurchase(
    id: 'payment-1',
    amount: 12000,
    currencyCode: 'CRC',
    detail: 'Kit de escobillas',
    linkId: r'$$ABC',
    linkUrl: Uri.parse('https://pay.test/link'),
    status: status,
    responseCode: '00',
    responseDescription: 'OK',
    rejectReason: '',
    createdAt: DateTime.utc(2026, 7, 5),
    expiresAt: expiresAt,
    orderRemainingAmount: orderRemainingAmount,
  );
}
