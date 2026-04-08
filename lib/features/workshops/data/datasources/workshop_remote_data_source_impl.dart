import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workshop_model.dart';
import 'workshop_remote_data_source.dart';

class WorkshopRemoteDataSourceImpl implements WorkshopRemoteDataSource {
  final SupabaseClient client;

  WorkshopRemoteDataSourceImpl(this.client);

  @override
  Future<List<WorkshopModel>> getWorkshops() async {
    final response = await client.from('workshops').select('''
      id,
      name,
      description,
      location_lat,
      location_lng,
      cover_url,
      avatar_url
    ''');

    print('WORKSHOPS RESPONSE: $response');
    print('WORKSHOPS LENGTH: ${(response as List).length}');

    return response.map((item) => WorkshopModel.fromMap(item)).toList();
  }
}