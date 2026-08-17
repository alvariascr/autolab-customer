import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/costa_rica_time.dart';
import '../models/appointment_model.dart';
import 'appointment_remote_data_source.dart';

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  const AppointmentRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

  static const _appointmentBaseSelect = '''
    id,
    order_service_id,
    appointment_status,
    scheduled_datetime,
    note,
    vehicle_id,
    employee_id,
    updated_at,
    updated_by,
    cancelled_at,
    cancelled_by,
    cancellation_reason,
    vehicles(vehicle_type, license_plate),
    order_services!inner(
      inventory_item_id,
      orders!inner(
        workshop_id,
        customers!inner(id, user_id)
      )
    )
  ''';

  static const _customerAppointmentSelect = '''
    id,
    order_service_id,
    appointment_status,
    scheduled_datetime,
    note,
    vehicle_id,
    employee_id,
    updated_at,
    updated_by,
    cancelled_at,
    cancelled_by,
    cancellation_reason,
    vehicles(vehicle_type, license_plate),
    order_services!inner(
      id,
      inventory_item_id,
      inventory_items(name),
      orders!inner(
        id,
        workshop_id,
        workshops(name, avatar_url),
        customers!inner(id, user_id)
      )
    )
  ''';

  @override
  Future<List<AppointmentModel>> getAppointmentsByWorkshop({
    required String workshopId,
    required String customerId,
  }) async {
    return _getAppointments(
      select: _customerAppointmentSelect,
      fallbackSelect: _appointmentBaseSelect,
      filters: (query) => query
          .eq('order_services.orders.workshop_id', workshopId)
          .eq('order_services.orders.customers.user_id', customerId)
          .order('scheduled_datetime'),
    );
  }

  @override
  Future<List<AppointmentModel>> getCustomerAppointments({
    required String customerId,
  }) async {
    return _getAppointments(
      select: _customerAppointmentSelect,
      fallbackSelect: _appointmentBaseSelect,
      filters: (query) => query
          .eq('order_services.orders.customers.user_id', customerId)
          .order('scheduled_datetime'),
    );
  }

  @override
  Future<AppointmentModel> cancelAppointment({
    required String appointmentId,
    required String customerId,
    required String reason,
    String? comments,
  }) async {
    await _getAppointmentById(appointmentId, customerId: customerId);

    await client.rpc<void>(
      'cancel_customer_appointment',
      params: {
        'p_appointment_id': appointmentId,
        'p_reason': reason,
        'p_comments': comments,
      },
    );

    return _getAppointmentById(appointmentId, customerId: customerId);
  }

  @override
  Future<AppointmentModel> rescheduleAppointment({
    required String appointmentId,
    required String customerId,
    required DateTime scheduledAt,
  }) async {
    await client.rpc<void>(
      'reschedule_customer_appointment',
      params: {
        'p_appointment_id': appointmentId,
        'p_scheduled_datetime': costaRicaLocalTimeToUtc(
          scheduledAt,
        ).toIso8601String(),
      },
    );

    return _getAppointmentById(appointmentId, customerId: customerId);
  }

  Future<AppointmentModel> _getAppointmentById(
    String id, {
    required String customerId,
  }) async {
    final response = await client
        .from('appointments')
        .select(_customerAppointmentSelect)
        .eq('id', id)
        .eq('order_services.orders.customers.user_id', customerId)
        .single();

    return AppointmentModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<List<AppointmentModel>> _getAppointments({
    required String select,
    required String fallbackSelect,
    required PostgrestTransformBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    )
    filters,
  }) async {
    try {
      return _modelsFromResponse(await filters(_selectAppointments(select)));
    } on PostgrestException catch (error) {
      if (!_isRelationshipError(error)) {
        rethrow;
      }

      return _modelsFromResponse(
        await filters(_selectAppointments(fallbackSelect)),
      );
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _selectAppointments(
    String select,
  ) {
    return client.from('appointments').select(select);
  }

  List<AppointmentModel> _modelsFromResponse(
    List<Map<String, dynamic>> response,
  ) {
    return response
        .map(
          (item) => AppointmentModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  bool _isRelationshipError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST200' ||
        message.contains('relationship') ||
        message.contains('schema cache');
  }
}
