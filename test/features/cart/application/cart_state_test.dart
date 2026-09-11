import 'package:autolab_customer/features/cart/application/cart_state.dart';
import 'package:autolab_customer/features/cart/domain/entities/cart_checkout.dart';
import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartState', () {
    test('forWorkshop no hereda una tarifa global de otro taller', () {
      final state = CartState(
        currentWorkshopDeliveryFee: 2500,
        // La tarifa cacheada pertenece a workshop-a (recién refrescada para
        // ese taller); pedir la vista de workshop-b no debe heredarla.
        currentWorkshopDeliveryFeeWorkshopId: 'workshop-a',
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
      'forWorkshop sí conserva la tarifa cuando pertenece al taller pedido',
      () {
        final state = CartState(
          currentWorkshopDeliveryFee: 2500,
          currentWorkshopDeliveryFeeWorkshopId: 'workshop-a',
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

        final workshopState = state.forWorkshop('workshop-a');

        expect(workshopState.currentWorkshopDeliveryFee, 2500);
      },
    );

    test(
      'forWorkshop no hereda el switch de envío a domicilio de otro taller',
      () {
        final state = CartState(
          homeDelivery: true,
          // Activado mientras se veía workshop-a; pedir la vista de
          // workshop-b no debe mostrarlo ya activado.
          homeDeliveryWorkshopId: 'workshop-a',
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

        expect(workshopState.homeDelivery, isFalse);
      },
    );

    test('forWorkshop sí conserva el switch de envío cuando pertenece al '
        'taller pedido', () {
      final state = CartState(
        homeDelivery: true,
        homeDeliveryWorkshopId: 'workshop-a',
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

      final workshopState = state.forWorkshop('workshop-a');

      expect(workshopState.homeDelivery, isTrue);
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

    test('agrupa los items del carrito por taller', () {
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
          // Segundo item del mismo taller: debe caer en el mismo grupo que
          // product-a, no crear uno nuevo.
          CartItem(
            product: _product(
              id: 'product-a2',
              workshopId: 'workshop-a',
              deliveryFee: 2500,
            ),
            quantity: 2,
          ),
          // Item de un taller distinto: debe quedar en su propio grupo,
          // separado de los dos anteriores.
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

      final workshopCarts = state.workshopCarts;

      expect(workshopCarts, hasLength(2));

      final workshopACart = workshopCarts.firstWhere(
        (cart) => cart.workshopId == 'workshop-a',
      );
      expect(workshopACart.items, hasLength(2));
      expect(
        workshopACart.items.map((item) => item.product.id),
        containsAll(['product-a', 'product-a2']),
      );

      final workshopBCart = workshopCarts.firstWhere(
        (cart) => cart.workshopId == 'workshop-b',
      );
      expect(workshopBCart.items, hasLength(1));
      expect(workshopBCart.items.single.product.id, 'product-b');
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

    test('no confirma el envío como gratis mientras no se conoce la tarifa '
        'real', () {
      // Envío a domicilio, sin tarifa del taller aún cargada y sin
      // tarifa capturada en el item (el escenario justo cuando se acaba
      // de agregar un producto por primera vez) -- shippingCost cae en
      // 0 como placeholder, pero eso no debe leerse como "gratis".
      final state = CartState(
        homeDelivery: true,
        items: [
          CartItem(
            product: _product(
              id: 'product-a',
              workshopId: 'workshop-a',
              deliveryFee: 0,
            ),
            quantity: 1,
          ),
        ],
      );

      expect(state.shippingCost, 0);
      expect(state.isShippingCostConfirmed, isFalse);
    });

    test('confirma el envío usando la tarifa capturada en el item si aún no '
        'hay una tarifa del taller cargada', () {
      final state = CartState(
        homeDelivery: true,
        items: [
          CartItem(
            product: _product(
              id: 'product-a',
              workshopId: 'workshop-a',
              deliveryFee: 1500,
            ),
            quantity: 1,
          ),
        ],
      );

      expect(state.shippingCost, 1500);
      expect(state.isShippingCostConfirmed, isTrue);
    });

    test('confirma el envío como gratis cuando la tarifa real del taller es '
        'cero', () {
      final state = CartState(
        homeDelivery: true,
        currentWorkshopDeliveryFee: 0,
        currentWorkshopDeliveryFeeWorkshopId: 'workshop-a',
        items: [
          CartItem(
            product: _product(
              id: 'product-a',
              workshopId: 'workshop-a',
              deliveryFee: 0,
            ),
            quantity: 1,
          ),
        ],
      );

      expect(state.shippingCost, 0);
      expect(
        state.isShippingCostConfirmed,
        isTrue,
        reason:
            'la tarifa real del taller ya llegó y es 0 -- esto sí es '
            'envío gratis confirmado, no un placeholder',
      );
    });

    test('confirma el envío con la tarifa real del taller cuando ya llegó y '
        'no es cero', () {
      final state = CartState(
        homeDelivery: true,
        currentWorkshopDeliveryFee: 2500,
        currentWorkshopDeliveryFeeWorkshopId: 'workshop-a',
        items: [
          CartItem(
            product: _product(
              id: 'product-a',
              workshopId: 'workshop-a',
              deliveryFee: 1000,
            ),
            quantity: 1,
          ),
        ],
      );

      expect(
        state.shippingCost,
        2500,
        reason:
            'la tarifa real del taller manda sobre la capturada en el '
            'item',
      );
      expect(state.isShippingCostConfirmed, isTrue);
    });

    test('confirma el envío sin cargar tarifa cuando no es a domicilio', () {
      final state = CartState(
        items: [
          CartItem(
            product: _product(
              id: 'product-a',
              workshopId: 'workshop-a',
              deliveryFee: 0,
            ),
            quantity: 1,
          ),
        ],
      );

      expect(state.shippingCost, 0);
      expect(state.isShippingCostConfirmed, isTrue);
    });

    test(
      'confirma el envío sin cargar tarifa cuando el carrito está vacío',
      () {
        final state = CartState(homeDelivery: true, items: const []);

        expect(state.shippingCost, 0);
        expect(state.isShippingCostConfirmed, isTrue);
      },
    );

    test('usa la primera tarifa capturada distinta de cero cuando hay varios '
        'items con tarifas distintas y aún no llega la tarifa del taller', () {
      final state = CartState(
        homeDelivery: true,
        items: [
          CartItem(
            product: _product(
              id: 'product-a',
              workshopId: 'workshop-a',
              deliveryFee: 1000,
            ),
            quantity: 1,
          ),
          CartItem(
            product: _product(
              id: 'product-b',
              workshopId: 'workshop-a',
              deliveryFee: 2000,
            ),
            quantity: 1,
          ),
        ],
      );

      expect(
        state.shippingCost,
        1000,
        reason:
            'en la práctica todos los items de un mismo taller comparten '
            'la misma tarifa capturada -- este test documenta que, si '
            'llegaran a diferir, se usa la primera tarifa distinta de '
            'cero encontrada',
      );
      expect(state.isShippingCostConfirmed, isTrue);
    });

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
