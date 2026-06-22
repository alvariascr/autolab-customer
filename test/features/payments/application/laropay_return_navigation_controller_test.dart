import 'package:autolab_customer/features/payments/application/laropay_return_navigation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const workshopId = '590baf3e-7af5-4d50-bf53-900292a0a786';

  test('navigates to the selected workshop for a valid Laropay callback', () {
    String? destination;
    final controller = LaropayReturnNavigationController(
      navigate: (location) => destination = location,
    );

    final handled = controller.handleAppLink(
      Uri.parse(
        'autolab://laropay-callback/payment-return?workshopId=$workshopId',
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
}
