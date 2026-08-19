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

    final clickCounts = <String, int>{};
    for (final row in response) {
      final serviceKey = row['service_key'];
      if (serviceKey is! String) continue;
      final normalizedServiceKey = serviceKey.trim();
      if (normalizedServiceKey.isEmpty) continue;

      final clickCount = row['click_count'];
      clickCounts[normalizedServiceKey] = clickCount is num
          ? clickCount.toInt()
          : 0;
    }

    return clickCounts;
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
