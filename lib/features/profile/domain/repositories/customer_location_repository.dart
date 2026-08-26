import '../entities/customer_location.dart';

abstract interface class CustomerLocationRepository {
  Future<List<CustomerLocation>> loadLocations();

  Future<CustomerLocation> saveLocation(
    CustomerLocationRequest request, {
    String? locationId,
  });

  Future<void> deleteLocation(String locationId);
}
