import '../entities/cart_checkout.dart';

abstract interface class CartRepository {
  Future<List<CustomerDeliveryAddress>> getDeliveryAddresses();

  Future<CustomerDeliveryAddress> saveDeliveryAddress(
    CustomerDeliveryAddressRequest request, {
    String? addressId,
  });

  Future<CustomerDeliveryAddress> setDefaultDeliveryAddress(String addressId);

  Future<void> deleteDeliveryAddress(String addressId);

  Future<CartCheckoutResult> createOrder(CartCheckoutRequest request);
}
