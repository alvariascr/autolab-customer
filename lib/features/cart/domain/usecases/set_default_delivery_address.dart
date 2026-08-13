import '../entities/cart_checkout.dart';
import '../repositories/delivery_address_repository.dart';

class SetDefaultDeliveryAddress {
  const SetDefaultDeliveryAddress(this._repository);

  final DeliveryAddressRepository _repository;

  Future<CustomerDeliveryAddress> call(String addressId) {
    final trimmedId = addressId.trim();
    if (trimmedId.isEmpty) {
      throw const CartCheckoutException('cart_invalid_address_id');
    }

    return _repository.setDefaultDeliveryAddress(trimmedId);
  }
}
