import '../entities/cart_checkout.dart';
import '../repositories/cart_repository.dart';

class SetDefaultDeliveryAddress {
  const SetDefaultDeliveryAddress(this._repository);

  final CartRepository _repository;

  Future<CustomerDeliveryAddress> call(String addressId) {
    return _repository.setDefaultDeliveryAddress(addressId);
  }
}
