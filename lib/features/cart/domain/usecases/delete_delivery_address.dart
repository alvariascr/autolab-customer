import '../entities/cart_checkout.dart';
import '../repositories/delivery_address_repository.dart';

class DeleteDeliveryAddress {
  const DeleteDeliveryAddress(this._repository);

  final DeliveryAddressRepository _repository;

  Future<void> call(String addressId) {
    final trimmedId = addressId.trim();
    if (trimmedId.isEmpty) {
      throw const CartCheckoutException('cart_invalid_address_id');
    }

    return _repository.deleteDeliveryAddress(trimmedId);
  }
}
