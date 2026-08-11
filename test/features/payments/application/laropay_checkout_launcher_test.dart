import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/payments/application/laropay_checkout_launcher.dart';
import 'package:autolab_customer/features/payments/domain/entities/laropay_link.dart';
import 'package:autolab_customer/features/payments/domain/entities/laropay_link_request.dart';
import 'package:autolab_customer/features/payments/domain/entities/laropay_payment_context.dart';
import 'package:autolab_customer/features/payments/domain/repositories/laropay_checkout_repository.dart';
import 'package:autolab_customer/features/payments/domain/repositories/laropay_link_repository.dart';
import 'package:autolab_customer/features/payments/domain/usecases/generate_laropay_link.dart';
import 'package:autolab_customer/features/payments/domain/usecases/get_laropay_payment_context.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('launches Laropay checkout for a cart order', () async {
    late LaropayLinkRequest request;
    Uri? openedUrl;
    final launcher = LaropayCheckoutLauncher(
      generateLaropayLink: GenerateLaropayLink(
        _FakeLaropayLinkRepository((value) async {
          request = value;
          return right(
            LaropayLink(
              linkId: r'$$CARTLINK',
              linkUrl: Uri.parse('https://pay.test/cart'),
              response: '00',
              responseDescription: 'OK',
            ),
          );
        }),
      ),
      getPaymentContext: GetLaropayPaymentContext(
        _FakeLaropayCheckoutRepository(
          orderContext: const LaropayPaymentContext(
            orderId: 'order-1',
            orderNumber: 'CART-1',
            amount: 18500,
            customerFirstName: 'Emilio',
            customerLastName: 'Alvarez',
            customerEmail: 'emilio@test.com',
            customerPhone: '88505074',
            workshopName: 'Taller Demo',
          ),
        ),
      ),
      launchExternalUrl: (uri) async {
        openedUrl = uri;
        return true;
      },
    );

    await launcher.launchForOrder(orderId: 'order-1');

    expect(openedUrl, Uri.parse('https://pay.test/cart'));
    expect(request.internalTransactionId, 'order-1');
    expect(request.amount, 18500);
    expect(request.document, 'CART-1');
    expect(request.detail, 'Autolab Taller Demo');
    expect(request.customerEmail, 'emilio@test.com');
  });
}

class _FakeLaropayLinkRepository implements LaropayLinkRepository {
  const _FakeLaropayLinkRepository(this._handler);

  final Future<Either<Failure, LaropayLink>> Function(LaropayLinkRequest)
  _handler;

  @override
  Future<Either<Failure, LaropayLink>> generateLink(
    LaropayLinkRequest request,
  ) {
    return _handler(request);
  }
}

class _FakeLaropayCheckoutRepository implements LaropayCheckoutRepository {
  const _FakeLaropayCheckoutRepository({required this.orderContext});

  final LaropayPaymentContext orderContext;

  @override
  Future<Either<Failure, LaropayPaymentContext>> getPaymentContext(
    String appointmentId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, LaropayPaymentContext>> getOrderPaymentContext(
    String orderId,
  ) async {
    return right(orderContext);
  }
}
