import 'package:autolab_customer/features/cart/application/cart_state.dart';
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
  });
}

Product _product({
  required String id,
  required String workshopId,
  required double deliveryFee,
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
    workshopName: 'Taller $workshopId',
    workshopAvatarUrl: '',
    workshopDeliveryFee: deliveryFee,
  );
}
