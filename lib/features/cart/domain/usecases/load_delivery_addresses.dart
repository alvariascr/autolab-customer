import '../entities/cart_checkout.dart';
import '../repositories/cart_repository.dart';

class LoadDeliveryAddresses {
  const LoadDeliveryAddresses(this._repository);

  final CartRepository _repository;

  Future<List<CustomerDeliveryAddress>> call() {
    return _repository.getDeliveryAddresses();
  }
}
