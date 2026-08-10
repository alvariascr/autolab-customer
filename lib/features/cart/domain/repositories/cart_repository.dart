import '../entities/cart_checkout.dart';

abstract interface class CartRepository {
  Future<CartCheckoutResult> createOrder(CartCheckoutRequest request);
}
