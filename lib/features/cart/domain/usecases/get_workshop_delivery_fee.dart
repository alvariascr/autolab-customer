import '../repositories/cart_repository.dart';

class GetWorkshopDeliveryFee {
  const GetWorkshopDeliveryFee(this._repository);

  final CartRepository _repository;

  Future<double> call(String workshopId) {
    return _repository.getWorkshopDeliveryFee(workshopId);
  }
}
