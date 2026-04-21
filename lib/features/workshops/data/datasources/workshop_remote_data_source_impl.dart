import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workshop_model.dart';
import 'workshop_remote_data_source.dart';

class WorkshopRemoteDataSourceImpl implements WorkshopRemoteDataSource {
  final SupabaseClient client;

  WorkshopRemoteDataSourceImpl(this.client);

  @override
  Future<List<WorkshopModel>> getWorkshops() async {
    final response = await client
        .from('workshops')
        .select('''
          id,
          name,
          description,
          location_address,
          status,
          location_lat,
          location_lng,
          delivery_radius_km,
          cover_url,
          avatar_url
        ''')
        .inFilter('status', const ['active', 'complete']);

    return response.map((item) => WorkshopModel.fromMap(item)).toList();
  }
}
