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
          phone,
          location_lat,
          location_lng,
          delivery_radius_km,
          offers_home_service,
          cover_url,
          avatar_url
        ''')
        .inFilter('status', const ['active', 'complete']);

    return response.map((item) => WorkshopModel.fromMap(item)).toList();
  }

  @override
  Future<WorkshopModel?> getWorkshopById(String id) async {
    final response = await client
        .from('workshops')
        .select('''
          id,
          name,
          description,
          location_address,
          status,
          phone,
          location_lat,
          location_lng,
          delivery_radius_km,
          offers_home_service,
          cover_url,
          avatar_url,
          business_hours (
            day_of_week,
            open_time,
            close_time,
            is_closed
          ),
          workshop_service_categories (
            workshop_categories (
              name
            )
          ),
          workshop_payment_methods (
            payment_methods (
              name
            )
          ),
          inventory_items (
            id,
            name,
            description,
            item_type,
            status,
            selling_price,
            primary_image_url
          )
        ''')
        .eq('id', id)
        .inFilter('status', const ['active', 'complete'])
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return WorkshopModel.fromMap(response);
  }
}
