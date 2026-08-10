import '../entities/cart_checkout.dart';
import '../repositories/delivery_address_repository.dart';

class LoadDeliveryAddresses {
  const LoadDeliveryAddresses(this._repository);

  final DeliveryAddressRepository _repository;

  Future<List<CustomerDeliveryAddress>> call() {
    return _repository.getDeliveryAddresses();
  }
}
