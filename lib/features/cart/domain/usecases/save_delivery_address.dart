import '../entities/cart_checkout.dart';
import '../repositories/delivery_address_repository.dart';

class SaveDeliveryAddress {
  const SaveDeliveryAddress(this._repository);

  final DeliveryAddressRepository _repository;

  Future<CustomerDeliveryAddress> call(
    CustomerDeliveryAddressRequest request, {
    String? addressId,
  }) {
    return _repository.saveDeliveryAddress(request, addressId: addressId);
  }
}
