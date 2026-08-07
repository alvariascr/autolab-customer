import '../entities/cart_checkout.dart';
import '../repositories/cart_repository.dart';

class SaveDeliveryAddress {
  const SaveDeliveryAddress(this._repository);

  final CartRepository _repository;

  Future<CustomerDeliveryAddress> call(
    CustomerDeliveryAddressRequest request, {
    String? addressId,
  }) {
    return _repository.saveDeliveryAddress(request, addressId: addressId);
  }
}
