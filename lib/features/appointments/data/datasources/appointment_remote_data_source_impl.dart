import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/appointment.dart';
import '../models/appointment_model.dart';
import 'appointment_remote_data_source.dart';

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  const AppointmentRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

  static const _appointmentSelect = '''
    id,
    workshop_id,
    service_id,
    customer_name,
    customer_phone,
    customer_email,
    vehicle_type,
    scheduled_at,
    status,
    payment_method,
    notes,
    total_amount,
    created_at,
    appointment_products(product_id, quantity, unit_price)
  ''';

  @override
  Future<AppointmentModel> createAppointment(AppointmentDraft draft) async {
    final response = await client
        .from('appointments')
        .insert(AppointmentModel.toInsertMap(draft))
        .select(_appointmentSelect)
        .single();

    final appointment = AppointmentModel.fromMap(
      Map<String, dynamic>.from(response),
    );

    if (draft.products.isNotEmpty && appointment.id.isNotEmpty) {
      await client
          .from('appointment_products')
          .insert(
            AppointmentModel.productLinesToInsertMaps(
              appointmentId: appointment.id,
              products: draft.products,
            ),
          );

      return _getAppointmentById(appointment.id);
    }

    return appointment;
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsByWorkshop(
    String workshopId,
  ) async {
    final response = await client
        .from('appointments')
        .select(_appointmentSelect)
        .eq('workshop_id', workshopId)
        .order('scheduled_at');

    return response
        .map(
          (item) => AppointmentModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<AppointmentModel> _getAppointmentById(String id) async {
    final response = await client
        .from('appointments')
        .select(_appointmentSelect)
        .eq('id', id)
        .single();

    return AppointmentModel.fromMap(Map<String, dynamic>.from(response));
  }
}
