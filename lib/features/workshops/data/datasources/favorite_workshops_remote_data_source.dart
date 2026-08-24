import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workshop_model.dart';

class FavoriteWorkshopsRemoteDataSource {
  const FavoriteWorkshopsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<WorkshopModel>> getFavoriteWorkshops() async {
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
        .whereType<Map<String, dynamic>>()
        .map((row) => row['workshops'])
        .whereType<Map<String, dynamic>>()
        .map(WorkshopModel.fromMap)
        .toList(growable: false);
  }

  Future<bool> isFavoriteWorkshop(String workshopId) async {
    final userId = _requireUserId();
    final response = await _client
        .from('customer_favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('favorite_type', 'workshop')
        .eq('workshop_id', workshopId)
        .maybeSingle();

    return response != null;
  }

  Future<bool> toggleFavoriteWorkshop(String workshopId) async {
    final userId = _requireUserId();
    final currentFavorite = await isFavoriteWorkshop(workshopId);

    if (currentFavorite) {
      await removeFavoriteWorkshop(workshopId);
      return false;
    }

    await _client.from('customer_favorites').insert({
      'user_id': userId,
      'favorite_type': 'workshop',
      'workshop_id': workshopId,
    });
    return true;
  }

  Future<void> removeFavoriteWorkshop(String workshopId) async {
    final userId = _requireUserId();
    await _client
        .from('customer_favorites')
        .delete()
        .eq('user_id', userId)
        .eq('favorite_type', 'workshop')
        .eq('workshop_id', workshopId);
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id.trim() ?? '';
    if (userId.isEmpty) {
      throw const FavoriteWorkshopAuthRequiredException();
    }

    return userId;
  }
}

class FavoriteWorkshopAuthRequiredException implements Exception {
  const FavoriteWorkshopAuthRequiredException();
}
