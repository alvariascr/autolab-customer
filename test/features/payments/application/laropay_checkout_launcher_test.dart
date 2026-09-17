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
  const orderContext = LaropayPaymentContext(
    orderId: 'order-1',
    orderNumber: 'CART-1',
    amount: 18500,
    customerFirstName: 'Emilio',
    customerLastName: 'Alvarez',
    customerEmail: 'emilio@test.com',
    customerPhone: '88505074',
    workshopName: 'Taller Demo',
  );

  test('launches Laropay checkout for a cart order', () async {
    final linkRepository = _FakeLaropayLinkRepository();
    final checkoutRepository = _FakeLaropayCheckoutRepository(
      orderContext: orderContext,
    );
    Uri? openedUrl;
    final launcher = _launcher(
      linkRepository: linkRepository,
      checkoutRepository: checkoutRepository,
      launchExternalUrl: (uri) async {
        openedUrl = uri;
        return true;
      },
    );

    final session = await launcher.launchForOrder(orderId: 'order-1');

    final request = linkRepository.lastRequest;
    expect(session.paymentLinkId, 'payment-link-1');
    expect(openedUrl, Uri.parse('https://pay.test/cart'));
    expect(request?.internalTransactionId, 'order-1');
    expect(request?.amount, 18500);
    expect(request?.document, 'CART-1');
    expect(request?.detail, 'Autolab Taller Demo');
    expect(request?.customerEmail, 'emilio@test.com');
  });

  test('uses order id as document when order number is blank', () async {
    final linkRepository = _FakeLaropayLinkRepository();
    final checkoutRepository = _FakeLaropayCheckoutRepository(
      orderContext: const LaropayPaymentContext(
        orderId: 'order-1',
        orderNumber: ' ',
        amount: 18500,
        customerFirstName: 'Emilio',
        customerLastName: 'Alvarez',
        customerEmail: 'emilio@test.com',
      ),
    );
    final launcher = _launcher(
      linkRepository: linkRepository,
      checkoutRepository: checkoutRepository,
    );

    await launcher.launchForOrder(orderId: 'order-1');

    expect(linkRepository.lastRequest?.document, 'order-1');
  });

  test('throws when payment context cannot be loaded', () async {
    final launcher = _launcher(
      linkRepository: _FakeLaropayLinkRepository(),
      checkoutRepository: _FakeLaropayCheckoutRepository(
        orderFailure: const ServerFailure(message: 'orden no encontrada'),
      ),
    );

    await expectLater(
      launcher.launchForOrder(orderId: 'order-1'),
      throwsA(
        isA<LaropayCheckoutLaunchException>().having(
          (error) => error.message,
          'message',
          'orden no encontrada',
        ),
      ),
    );
  });

  test('throws when Laropay link generation fails', () async {
    final launcher = _launcher(
      linkRepository: _FakeLaropayLinkRepository(
        failure: const ServerFailure(message: 'gateway rechazado'),
      ),
      checkoutRepository: _FakeLaropayCheckoutRepository(
        orderContext: orderContext,
      ),
    );

    await expectLater(
      launcher.launchForOrder(orderId: 'order-1'),
      throwsA(
        isA<LaropayCheckoutLaunchException>().having(
          (error) => error.message,
          'message',
          'gateway rechazado',
        ),
      ),
    );
  });

  test('throws when external checkout cannot be opened', () async {
    final launcher = _launcher(
      linkRepository: _FakeLaropayLinkRepository(),
      checkoutRepository: _FakeLaropayCheckoutRepository(
        orderContext: orderContext,
      ),
      launchExternalUrl: (_) async => false,
    );

    await expectLater(
      launcher.launchForOrder(orderId: 'order-1'),
      throwsA(
        isA<LaropayCheckoutLaunchException>()
            .having(
              (error) => error.message,
              'message',
              'No fue posible abrir el navegador seguro de Laropay.',
            )
            .having(
              (error) => error.linkUrl,
              'linkUrl',
              Uri.parse('https://pay.test/cart'),
            ),
      ),
    );
  });
}

LaropayCheckoutLauncher _launcher({
  required _FakeLaropayLinkRepository linkRepository,
  required _FakeLaropayCheckoutRepository checkoutRepository,
  LaropayExternalUrlLauncher? launchExternalUrl,
}) {
  return LaropayCheckoutLauncher(
    generateLaropayLink: GenerateLaropayLink(linkRepository),
    getPaymentContext: GetLaropayPaymentContext(checkoutRepository),
    launchExternalUrl: launchExternalUrl ?? (_) async => true,
  );
}

class _FakeLaropayLinkRepository implements LaropayLinkRepository {
  _FakeLaropayLinkRepository({this.failure});

  final Failure? failure;
  LaropayLinkRequest? lastRequest;

  @override
  Future<Either<Failure, LaropayLink>> generateLink(
    LaropayLinkRequest request,
  ) async {
    lastRequest = request;

    final failure = this.failure;
    if (failure != null) {
      return left(failure);
    }

    return right(
      LaropayLink(
        paymentLinkId: 'payment-link-1',
        linkId: r'$$CARTLINK',
        linkUrl: Uri.parse('https://pay.test/cart'),
        response: '00',
        responseDescription: 'OK',
      ),
    );
  }
}

class _FakeLaropayCheckoutRepository implements LaropayCheckoutRepository {
  const _FakeLaropayCheckoutRepository({this.orderContext, this.orderFailure});

  final LaropayPaymentContext? orderContext;
  final Failure? orderFailure;

  @override
  Future<Either<Failure, LaropayPaymentContext>> getPaymentContext(
    String appointmentId,
  ) async {
    final failure = orderFailure;
    if (failure != null) {
      return left(failure);
    }

    return right(orderContext!);
  }

  @override
  Future<Either<Failure, LaropayPaymentContext>> getOrderPaymentContext(
    String orderId,
  ) async {
    final failure = orderFailure;
    if (failure != null) {
      return left(failure);
    }

    return right(orderContext!);
  }
}
