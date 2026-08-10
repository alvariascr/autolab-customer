import '../entities/cart_checkout.dart';
import '../repositories/delivery_address_repository.dart';

class SetDefaultDeliveryAddress {
  const SetDefaultDeliveryAddress(this._repository);

  final DeliveryAddressRepository _repository;

  Future<CustomerDeliveryAddress> call(String addressId) {
    return _repository.setDefaultDeliveryAddress(addressId);
  }
}
