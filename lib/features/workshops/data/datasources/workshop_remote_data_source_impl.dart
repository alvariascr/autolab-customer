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
            is_closed,
            slot_capacity
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
          )
        ''')
        .eq('id', id)
        .inFilter('status', const ['active', 'complete'])
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final activeEmployeeCount = await _getActiveEmployeeCount(id);

    return WorkshopModel.fromMap({
      ...response,
      'active_employee_count': activeEmployeeCount,
    });
  }

  Future<int> _getActiveEmployeeCount(String workshopId) async {
    final response = await client.rpc(
      'get_workshop_active_employee_count',
      params: {'p_workshop_id': workshopId},
    );

    if (response is int) {
      return response;
    }

    return int.tryParse(response?.toString() ?? '') ?? 0;
  }
}
