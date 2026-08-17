import 'package:autolab_customer/features/cart/application/cart_items_service.dart';
import 'package:autolab_customer/features/cart/application/cart_state.dart';
import 'package:autolab_customer/features/products/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartItemsService', () {
    const service = CartItemsService();

    test('permite productos de otro taller en un grupo separado', () {
      final currentProduct = _product(
        id: 'product-1',
        workshopId: 'workshop-1',
      );
      final otherWorkshopProduct = _product(
        id: 'product-2',
        workshopId: 'workshop-2',
      );
      final state = CartState(
        items: [CartItem(product: currentProduct, quantity: 1)],
      );

      final result = service.addProduct(
        state,
        otherWorkshopProduct,
        quantity: 1,
      );

      expect(result.wasChanged, isTrue);
      expect(result.status, CartAddProductStatus.added);
      expect(result.items, hasLength(2));
      expect(
        CartState(
          items: result.items,
        ).workshopCarts.map((cart) => cart.workshopId),
        containsAll(['workshop-1', 'workshop-2']),
      );
    });

    test('permite agregar productos del mismo taller', () {
      final currentProduct = _product(
        id: 'product-1',
        workshopId: 'workshop-1',
      );
      final sameWorkshopProduct = _product(
        id: 'product-2',
        workshopId: 'workshop-1',
      );
      final state = CartState(
        items: [CartItem(product: currentProduct, quantity: 1)],
      );

      final result = service.addProduct(
        state,
        sameWorkshopProduct,
        quantity: 1,
      );

      expect(result.wasChanged, isTrue);
      expect(result.status, CartAddProductStatus.added);
      expect(result.items, hasLength(2));
    });

    test('rechaza productos con id vacío', () {
      const state = CartState();

      final result = service.addProduct(
        state,
        _product(id: ' ', workshopId: 'workshop-1'),
        quantity: 1,
      );

      expect(result.wasChanged, isFalse);
      expect(result.status, CartAddProductStatus.invalidProduct);
      expect(result.items, isEmpty);
    });
  });
}

Product _product({required String id, required String workshopId}) {
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
    workshopName: 'Taller $workshopId',
    workshopAvatarUrl: '',
  );
}
