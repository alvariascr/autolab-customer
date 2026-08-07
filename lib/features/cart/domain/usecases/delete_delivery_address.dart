import '../repositories/cart_repository.dart';

class DeleteDeliveryAddress {
  const DeleteDeliveryAddress(this._repository);

  final CartRepository _repository;

  Future<void> call(String addressId) {
    return _repository.deleteDeliveryAddress(addressId);
  }
}
