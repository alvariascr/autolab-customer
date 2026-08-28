import '../../domain/entities/customer_location.dart';
import '../../domain/repositories/customer_location_repository.dart';
import '../datasources/customer_location_remote_data_source.dart';

class CustomerLocationRepositoryImpl implements CustomerLocationRepository {
  const CustomerLocationRepositoryImpl(this._remoteDataSource);

  final CustomerLocationRemoteDataSource _remoteDataSource;

  @override
  Future<List<CustomerLocation>> loadLocations() async {
    final userId = _requireUserId();
    try {
      final response = await _remoteDataSource.loadLocations(userId);
      return response.map(_locationFromJson).toList(growable: false);
    } on CustomerLocationStorageException catch (error) {
      throw CustomerLocationException(error.message);
    }
  }

  @override
  Future<CustomerLocation> saveLocation(
    CustomerLocationRequest request, {
    String? locationId,
  }) async {
    final userId = _requireUserId();
    final trimmedLocationId = locationId?.trim();
    final isCreating = trimmedLocationId == null || trimmedLocationId.isEmpty;

    if (request.address.trim().isEmpty) {
      throw const CustomerLocationException('location_address_required');
    }

    if (!request.latitude.isFinite || !request.longitude.isFinite) {
      throw const CustomerLocationException('location_coordinates_invalid');
    }

    final payload = {
      'label': request.label.trim(),
      'address': request.address.trim(),
      'country': request.country.trim(),
      'province': request.province.trim(),
      'canton': request.canton.trim(),
      'district': request.district.trim(),
      'exact_address': request.exactAddress.trim(),
      'latitude': request.latitude,
      'longitude': request.longitude,
    };

    try {
      final response = await _remoteDataSource.saveLocation(
        userId: userId,
        payload: payload,
        locationId: isCreating ? null : trimmedLocationId,
      );
      return _locationFromJson(response);
    } on CustomerLocationStorageException catch (error) {
      throw CustomerLocationException(error.message);
    }
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    final userId = _requireUserId();
    final trimmedLocationId = locationId.trim();
    if (trimmedLocationId.isEmpty) {
      throw const CustomerLocationException('location_id_required');
    }

    try {
      await _remoteDataSource.deleteLocation(userId, trimmedLocationId);
    } on CustomerLocationStorageException catch (error) {
      throw CustomerLocationException(error.message);
    }
  }

  String _requireUserId() {
    final userId = _remoteDataSource.currentUserId;
    if (userId == null || userId.trim().isEmpty) {
      throw const CustomerLocationException('location_auth_required');
    }

    return userId;
  }
}

CustomerLocation _locationFromJson(Map<String, dynamic> json) {
  return CustomerLocation(
    id: json['id']?.toString() ?? '',
    label: json['label']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    country: json['country']?.toString() ?? '',
    province: json['province']?.toString() ?? '',
    canton: json['canton']?.toString() ?? '',
    district: json['district']?.toString() ?? '',
    exactAddress: json['exact_address']?.toString() ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    isDefault: json['is_default'] == true,
  );
}

class CustomerLocationException implements Exception {
  const CustomerLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
