import 'package:autolab_customer/features/cart/application/cart_state.dart';
import 'package:autolab_customer/features/cart/domain/entities/cart_checkout.dart';
import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartState', () {
    test('forWorkshop no hereda una tarifa global de otro taller', () {
      final state = CartState(
        currentWorkshopDeliveryFee: 2500,
        items: [
          CartItem(
            product: _product(
              id: 'product-a',
              workshopId: 'workshop-a',
              deliveryFee: 2500,
            ),
            quantity: 1,
          ),
          CartItem(
            product: _product(
              id: 'product-b',
              workshopId: 'workshop-b',
              deliveryFee: 1000,
            ),
            quantity: 1,
          ),
        ],
      );

      final workshopState = state.forWorkshop('workshop-b');

      expect(workshopState.items, hasLength(1));
      expect(workshopState.items.single.product.workshopId, 'workshop-b');
      expect(workshopState.currentWorkshopDeliveryFee, isNull);
    });

    test(
      'usa un producto con metadata válida como representante del taller',
      () {
        final cart = CartWorkshopCart(
          workshopId: 'workshop-a',
          items: [
            CartItem(
              product: _product(
                id: 'product-a',
                workshopId: 'workshop-a',
                deliveryFee: 2500,
                workshopName: ' ',
                workshopAvatarUrl: ' ',
              ),
              quantity: 1,
            ),
            CartItem(
              product: _product(
                id: 'product-b',
                workshopId: 'workshop-a',
                deliveryFee: 2500,
                workshopName: 'Taller Principal',
                workshopAvatarUrl: 'https://example.com/avatar.png',
              ),
              quantity: 1,
            ),
          ],
        );

        expect(cart.workshopName, 'Taller Principal');
        expect(cart.workshopAvatarUrl, 'https://example.com/avatar.png');
      },
    );

    test('memoiza los carritos agrupados por instancia de estado', () {
      final state = CartState(
        items: [
          CartItem(
            product: _product(
              id: 'product-a',
              workshopId: 'workshop-a',
              deliveryFee: 2500,
            ),
            quantity: 1,
          ),
        ],
      );

      final firstRead = state.workshopCarts;
      final secondRead = state.workshopCarts;

      expect(identical(firstRead, secondRead), isTrue);
      expect(firstRead, hasLength(1));
      expect(firstRead.single.workshopId, 'workshop-a');
    });

    test(
      'preserva pendingCheckoutResult a través de un ciclo de toJson/fromJson',
      () {
        final state = CartState(
          items: [
            CartItem(
              product: _product(
                id: 'product-a',
                workshopId: 'workshop-a',
                deliveryFee: 2500,
              ),
              quantity: 1,
            ),
          ],
          pendingCheckoutResult: const CartCheckoutResult(
            orderId: 'order-id',
            orderNumber: 'order-number',
            totalAmount: 1500,
          ),
        );

        final restored = CartState.fromJson(state.toJson());

        expect(restored.pendingCheckoutResult, state.pendingCheckoutResult);
      },
    );

    test('fromJson sin pendingCheckoutResult persistido queda en null', () {
      final state = CartState(
        items: [
          CartItem(
            product: _product(
              id: 'product-a',
              workshopId: 'workshop-a',
              deliveryFee: 2500,
            ),
            quantity: 1,
          ),
        ],
      );

      final restored = CartState.fromJson(state.toJson());

      expect(restored.pendingCheckoutResult, isNull);
    });
  });
}

Product _product({
  required String id,
  required String workshopId,
  required double deliveryFee,
  String? workshopName,
  String workshopAvatarUrl = '',
}) {
  return Product(
    id: id,
    workshopId: workshopId,
    name: 'Producto $id',
    description: 'Descripción',
    primaryImageUrl: '',
    sellingPrice: 1000,
    currentStock: 10,
    minimumStockAlert: 1,
    itemType: 'product',
    status: 'active',
    requiresAppointment: false,
    skuNumber: id,
    barcode: '',
    categoryName: '',
    brandName: '',
    providerName: '',
    workshopName: workshopName ?? 'Taller $workshopId',
    workshopAvatarUrl: workshopAvatarUrl,
    workshopDeliveryFee: deliveryFee,
  );
}
