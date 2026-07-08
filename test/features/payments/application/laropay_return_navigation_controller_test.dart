import 'package:autolab_customer/features/payments/application/laropay_return_navigation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const workshopId = '590baf3e-7af5-4d50-bf53-900292a0a786';
  const paymentLinkId = '8b5d3a5e-1234-5678-abcd-900292a0a123';

  test('refreshes status and navigates to the selected workshop', () async {
    String? destination;
    String? refreshedPaymentLinkId;
    final controller = LaropayReturnNavigationController(
      navigate: (location) => destination = location,
      refreshPaymentStatus: (id) async {
        refreshedPaymentLinkId = id;
        return 'paid';
      },
    );

    final handled = await controller.handleAppLink(
      Uri.parse(
        'autolab://laropay-callback/payment-return?workshopId=$workshopId&paymentLinkId=$paymentLinkId',
      ),
    );

    expect(handled, isTrue);
    expect(refreshedPaymentLinkId, paymentLinkId);
    expect(
      destination,
      '/workshops/$workshopId?payment=paid&paymentLinkId=$paymentLinkId',
    );
  });

  test('falls back to pending when status refresh fails', () async {
    String? destination;
    final controller = LaropayReturnNavigationController(
      navigate: (location) => destination = location,
      refreshPaymentStatus: (_) => throw Exception('network_error'),
    );

    final handled = await controller.handleAppLink(
      Uri.parse(
        'autolab://laropay-callback/payment-return?workshopId=$workshopId&paymentLinkId=$paymentLinkId',
      ),
    );

    expect(handled, isTrue);
    expect(
      destination,
      '/workshops/$workshopId?payment=pending&paymentLinkId=$paymentLinkId',
    );
  });

  test('does not refresh when paymentLinkId is missing or invalid', () async {
    var refreshCount = 0;
    String? destination;
    final controller = LaropayReturnNavigationController(
      navigate: (location) => destination = location,
      refreshPaymentStatus: (_) async {
        refreshCount++;
        return 'paid';
      },
    );

    final handled = await controller.handleAppLink(
      Uri.parse(
        'autolab://laropay-callback/payment-return?workshopId=$workshopId&paymentLinkId=invalid',
      ),
    );

    expect(handled, isTrue);
    expect(refreshCount, 0);
    expect(destination, '/workshops/$workshopId?payment=pending');
  });

  test('ignores a callback with an invalid workshop identifier', () async {
    String? destination;
    final controller = LaropayReturnNavigationController(
      navigate: (location) => destination = location,
    );

    final handled = await controller.handleAppLink(
      Uri.parse('autolab://laropay-callback/payment-return?workshopId=invalid'),
    );

    expect(handled, isFalse);
    expect(destination, isNull);
  });

  test('ignores callbacks with invalid route parts', () async {
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

      expect(await controller.handleAppLink(uri), isFalse);
      expect(destination, isNull);
    }
  });
}
