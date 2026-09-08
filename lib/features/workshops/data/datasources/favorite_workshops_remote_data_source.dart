import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/supabase_error_matchers.dart';
import '../models/workshop_model.dart';

class FavoriteWorkshopsRemoteDataSource {
  const FavoriteWorkshopsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<WorkshopModel>> getFavoriteWorkshops() async {
    return _wrapStorageErrors(() async {
      final userId = _requireUserId();
      final response = await _client
          .from('customer_favorites')
          .select('''
          workshops (
            id,
            name,
            description,
            location_address,
            status,
            phone,
            location_lat,
            location_lng,
            delivery_radius_km,
            delivery_fee,
            offers_home_service,
            cover_url,
            avatar_url
          )
        ''')
          .eq('user_id', userId)
          .eq('favorite_type', 'workshop')
          .order('created_at', ascending: false);

      return response
          .map((row) => row['workshops'])
          .whereType<Map<String, dynamic>>()
          .map(WorkshopModel.fromMap)
          .toList(growable: false);
    });
  }

  Future<bool> isFavoriteWorkshop(String workshopId) async {
    return _wrapStorageErrors(() async {
      final userId = _requireUserId();
      final response = await _client
          .from('customer_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('favorite_type', 'workshop')
          .eq('workshop_id', workshopId)
          .maybeSingle();

      return response != null;
    });
  }

  Future<bool> toggleFavoriteWorkshop(String workshopId) async {
    return _wrapStorageErrors(() async {
      _requireUserId();
      return _client.rpc<bool>(
        'toggle_customer_favorite_workshop',
        params: {'p_workshop_id': workshopId},
      );
    });
  }

  Future<void> removeFavoriteWorkshop(String workshopId) async {
    await _wrapStorageErrors(() async {
      final userId = _requireUserId();
      await _client
          .from('customer_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('favorite_type', 'workshop')
          .eq('workshop_id', workshopId);
    });
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id.trim() ?? '';
    if (userId.isEmpty) {
      throw const FavoriteWorkshopAuthRequiredException();
    }

    return userId;
  }

  Future<T> _wrapStorageErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FavoriteWorkshopAuthRequiredException {
      rethrow;
    } on FavoriteWorkshopStorageException {
      rethrow;
    } on PostgrestException catch (error, stackTrace) {
      if (isAuthRequiredError(error)) {
        throw const FavoriteWorkshopAuthRequiredException();
      }
      throw FavoriteWorkshopStorageException(error, stackTrace);
    } on SocketException catch (error, stackTrace) {
      throw FavoriteWorkshopStorageException(error, stackTrace);
    }
  }
}

class FavoriteWorkshopAuthRequiredException implements Exception {
  const FavoriteWorkshopAuthRequiredException();
}

class FavoriteWorkshopStorageException implements Exception {
  const FavoriteWorkshopStorageException(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() => error.toString();
}
