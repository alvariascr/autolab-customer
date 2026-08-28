import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerLocationRemoteDataSource {
  const CustomerLocationRemoteDataSource(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> loadLocations(String userId) async {
    return _wrapStorageErrors(() async {
      final response = await _client
          .from('customer_locations')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('updated_at', ascending: false);

      return response
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    });
  }

  Future<Map<String, dynamic>> saveLocation({
    required String userId,
    required Map<String, dynamic> payload,
    String? locationId,
  }) async {
    return _wrapStorageErrors(() async {
      final response = await _client.rpc<Map<String, dynamic>>(
        'save_customer_location',
        params: {
          'p_location_id': locationId,
          'p_label': payload['label'],
          'p_address': payload['address'],
          'p_country': payload['country'],
          'p_province': payload['province'],
          'p_canton': payload['canton'],
          'p_district': payload['district'],
          'p_exact_address': payload['exact_address'],
          'p_latitude': payload['latitude'],
          'p_longitude': payload['longitude'],
        },
      );

      return Map<String, dynamic>.from(response);
    });
  }

  Future<void> deleteLocation(String userId, String locationId) async {
    await _wrapStorageErrors(() async {
      await _client
          .from('customer_locations')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('id', locationId);
    });
  }

  Future<T> _wrapStorageErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on CustomerLocationStorageException {
      rethrow;
    } on PostgrestException catch (error) {
      throw CustomerLocationStorageException(error.message);
    } on SocketException catch (error) {
      throw CustomerLocationStorageException(error.message);
    }
  }
}

class CustomerLocationStorageException implements Exception {
  const CustomerLocationStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
