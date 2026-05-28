import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment_model.dart';
import 'appointment_remote_data_source.dart';

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  const AppointmentRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

  static const _appointmentSelect = '''
    id,
    customer_id,
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
  Future<AppointmentModel> createAppointment({
    required Map<String, dynamic> rpcParams,
    required String customerId,
  }) async {
    final response = await client.rpc(
      'create_appointment_with_products',
      params: {...rpcParams, 'p_customer_id': customerId},
    );

    final appointmentId = _appointmentIdFromRpcResponse(response);

    if (appointmentId.isEmpty) {
      throw const FormatException(
        'create_appointment_with_products returned an invalid or empty ID',
      );
    }

    return _getAppointmentById(appointmentId, customerId: customerId);
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsByWorkshop({
    required String workshopId,
    required String customerId,
  }) async {
    final response = await client
        .from('appointments')
        .select(_appointmentSelect)
        .eq('workshop_id', workshopId)
        .eq('customer_id', customerId)
        .order('scheduled_at');

    return response
        .map(
          (item) => AppointmentModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<AppointmentModel> _getAppointmentById(
    String id, {
    required String customerId,
  }) async {
    final response = await client
        .from('appointments')
        .select(_appointmentSelect)
        .eq('id', id)
        .eq('customer_id', customerId)
        .single();

    return AppointmentModel.fromMap(Map<String, dynamic>.from(response));
  }

  String _appointmentIdFromRpcResponse(Object? response) {
    if (response is String) {
      return response;
    }

    if (response is Map) {
      return response['id']?.toString() ??
          response['appointment_id']?.toString() ??
          '';
    }

    return response?.toString() ?? '';
  }
}
