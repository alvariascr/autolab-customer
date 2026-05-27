import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/appointment.dart';
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
  Future<AppointmentModel> createAppointment(AppointmentDraft draft) async {
    final response = await client.rpc(
      'create_appointment_with_products',
      params: {
        ...AppointmentModel.toCreateRpcParams(draft),
        'p_customer_id': _requireCurrentUserId(),
      },
    );

    final appointmentId = _appointmentIdFromRpcResponse(response);

    if (appointmentId.isEmpty) {
      throw StateError('create_appointment_with_products returned empty id');
    }

    return _getAppointmentById(appointmentId);
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsByWorkshop(
    String workshopId,
  ) async {
    final customerId = _currentUserId();
    if (customerId == null || customerId.isEmpty) {
      return const [];
    }

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

  Future<AppointmentModel> _getAppointmentById(String id) async {
    final customerId = _requireCurrentUserId();
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

  String? _currentUserId() {
    return client.auth.currentUser?.id;
  }

  String _requireCurrentUserId() {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError('Authenticated user is required for appointments');
    }

    return userId;
  }
}
