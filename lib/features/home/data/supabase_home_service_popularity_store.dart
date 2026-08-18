import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/home_service_popularity_store.dart';

class SupabaseHomeServicePopularityStore implements HomeServicePopularityStore {
  const SupabaseHomeServicePopularityStore(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, int>> loadClickCounts() async {
    final response = await _client
        .from('home_service_click_counts')
        .select('service_key, click_count');

    return {
      for (final row in response)
        row['service_key'] as String: (row['click_count'] as num).toInt(),
    };
  }

  @override
  Future<int> recordClick(String serviceKey) async {
    final response = await _client.rpc<int>(
      'increment_home_service_click',
      params: {'p_service_key': serviceKey},
    );
    return response;
  }
}
