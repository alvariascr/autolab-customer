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

  @override
  Future<void> deleteDeliveryAddress(String addressId) {
    return _remoteDataSource.deleteDeliveryAddress(addressId);
  }

  @override
  Future<List<CustomerDeliveryAddress>> getDeliveryAddresses() {
    return _remoteDataSource.getDeliveryAddresses();
  }

  @override
  Future<double> getWorkshopDeliveryFee(String workshopId) {
    return _remoteDataSource.getWorkshopDeliveryFee(workshopId);
  }

  @override
  Future<CustomerDeliveryAddress> saveDeliveryAddress(
    CustomerDeliveryAddressRequest request, {
    String? addressId,
  }) {
    return _remoteDataSource.saveDeliveryAddress(request, addressId: addressId);
  }

  @override
  Future<CustomerDeliveryAddress> setDefaultDeliveryAddress(String addressId) {
    return _remoteDataSource.setDefaultDeliveryAddress(addressId);
  }
}
