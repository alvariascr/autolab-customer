import '../../../workshops/domain/repositories/workshop_repository.dart';
import '../entities/cart_checkout.dart';

class GetWorkshopDeliveryFee {
  const GetWorkshopDeliveryFee(this._repository);

  final WorkshopRepository _repository;

  Future<double> call(String workshopId) async {
    final result = await _repository.getWorkshopById(workshopId);

    return result.fold(
      (_) => throw const CartCheckoutException('cart_delivery_fee_unavailable'),
      (workshop) => workshop?.deliveryFee ?? 0,
    );
  }
}
