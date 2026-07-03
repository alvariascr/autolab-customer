import 'package:autolab_customer/features/payments/application/laropay_return_navigation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const workshopId = '590baf3e-7af5-4d50-bf53-900292a0a786';
  const paymentLinkId = '8b5d3a5e-1234-5678-abcd-900292a0a123';

  test('navigates to the selected workshop for a valid Laropay callback', () {
    String? destination;
    final controller = LaropayReturnNavigationController(
      navigate: (location) => destination = location,
    );

    final handled = controller.handleAppLink(
      Uri.parse(
        'autolab://laropay-callback/payment-return?workshopId=$workshopId&paymentLinkId=$paymentLinkId',
      ),
    );

    expect(handled, isTrue);
    expect(destination, '/workshops/$workshopId?payment=pending');
  });

  test('ignores a callback with an invalid workshop identifier', () {
    String? destination;
    final controller = LaropayReturnNavigationController(
      navigate: (location) => destination = location,
    );

    final handled = controller.handleAppLink(
      Uri.parse('autolab://laropay-callback/payment-return?workshopId=invalid'),
    );

    expect(handled, isFalse);
    expect(destination, isNull);
  });

  test('ignores callbacks with invalid route parts', () {
    final rejectedUris = [
      Uri.parse(
        'http://laropay-callback/payment-return?workshopId=$workshopId&paymentLinkId=$paymentLinkId',
      ),
      Uri.parse(
        'autolab://wrong-host/payment-return?workshopId=$workshopId&paymentLinkId=$paymentLinkId',
      ),
      Uri.parse(
        'autolab://laropay-callback/wrong-path?workshopId=$workshopId&paymentLinkId=$paymentLinkId',
      ),
    ];

    for (final uri in rejectedUris) {
      String? destination;
      final controller = LaropayReturnNavigationController(
        navigate: (location) => destination = location,
      );

      expect(controller.handleAppLink(uri), isFalse);
      expect(destination, isNull);
    }
  });
}
