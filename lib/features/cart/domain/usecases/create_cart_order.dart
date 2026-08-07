import '../entities/cart_checkout.dart';
import '../repositories/cart_repository.dart';

class CreateCartOrder {
  const CreateCartOrder(this._repository);

  final CartRepository _repository;

  Future<CartCheckoutResult> call(CartCheckoutRequest request) {
    return _repository.createOrder(request);
  }
}
