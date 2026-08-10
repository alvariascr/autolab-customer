import '../repositories/delivery_address_repository.dart';

class DeleteDeliveryAddress {
  const DeleteDeliveryAddress(this._repository);

  final DeliveryAddressRepository _repository;

  Future<void> call(String addressId) {
    return _repository.deleteDeliveryAddress(addressId);
  }
}
