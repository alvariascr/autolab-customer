import '../entities/cart_checkout.dart';
import '../repositories/cart_repository.dart';

class CreateCartOrder {
  const CreateCartOrder(this._repository);

  final CartRepository _repository;

  Future<CartCheckoutResult> call(CartCheckoutRequest request) {
    if (request.products.isEmpty) {
      throw const CartCheckoutException('cart_products_required');
    }

    if (request.homeDelivery && request.deliveryDetails == null) {
      throw const CartCheckoutException('cart_delivery_details_required');
    }

    return _repository.createOrder(request);
  }
}
