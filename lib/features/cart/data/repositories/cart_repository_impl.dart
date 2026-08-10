import '../../domain/entities/cart_checkout.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_checkout_remote_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._remoteDataSource);

  final CartCheckoutRemoteDataSource _remoteDataSource;

  @override
  Future<CartCheckoutResult> createOrder(CartCheckoutRequest request) {
    return _remoteDataSource.createOrder(request);
  }
}
