import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/customer_location.dart';
import '../../domain/repositories/customer_location_repository.dart';

class CustomerLocationRepositoryImpl implements CustomerLocationRepository {
  const CustomerLocationRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CustomerLocation>> loadLocations() async {
    final userId = _requireUserId();
    final response = await _client
        .from('customer_locations')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('is_default', ascending: false)
        .order('updated_at', ascending: false);

    return response
        .whereType<Map<String, dynamic>>()
        .map(_locationFromJson)
        .toList(growable: false);
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

    final existingLocations = await loadLocations();
    final shouldBeDefault = isCreating && existingLocations.isEmpty;

    if (shouldBeDefault) {
      await _clearDefaultLocation(userId);
    }

    final payload = {
      'user_id': userId,
      'label': request.label.trim(),
      'address': request.address.trim(),
      'country': request.country.trim(),
      'province': request.province.trim(),
      'canton': request.canton.trim(),
      'district': request.district.trim(),
      'exact_address': request.exactAddress.trim(),
      'latitude': request.latitude,
      'longitude': request.longitude,
      'is_default': shouldBeDefault,
      'is_active': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = isCreating
        ? await _client
              .from('customer_locations')
              .insert(payload)
              .select()
              .single()
        : await _client
              .from('customer_locations')
              .update(payload)
              .eq('user_id', userId)
              .eq('id', trimmedLocationId)
              .select()
              .single();

    return _locationFromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    final userId = _requireUserId();
    final trimmedLocationId = locationId.trim();
    if (trimmedLocationId.isEmpty) {
      throw const CustomerLocationException('location_id_required');
    }

    await _client
        .from('customer_locations')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('id', trimmedLocationId);
  }

  Future<void> _clearDefaultLocation(String userId) async {
    await _client
        .from('customer_locations')
        .update({
          'is_default': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_active', true);
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
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
