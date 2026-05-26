import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AppointmentBookingRemoteDataSource {
  Future<List<AppointmentVehicleRecord>> getCustomerVehicles({
    required String workshopId,
  });

  Future<AppointmentVehicleRecord?> getCustomerVehicleByPlate({
    required String workshopId,
    required String licensePlate,
  });

  Future<bool> isAppointmentSlotAvailable({
    required String workshopId,
    required DateTime scheduledDateTime,
  });

  Future<List<DateTime>> getBookedAppointmentSlots({
    required String workshopId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<String> bookServiceAppointment({
    required String workshopId,
    required String inventoryItemId,
    required DateTime scheduledDateTime,
    String? note,
    String? vehicleId,
    String? licensePlate,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    int? vehicleYear,
    String? vehicleColor,
    String? fuelType,
    String? transmissionType,
  });
}

class AppointmentVehicleRecord {
  const AppointmentVehicleRecord({
    required this.id,
    required this.licensePlate,
    this.vehicleType,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.fuelType,
    this.transmissionType,
  });

  factory AppointmentVehicleRecord.fromMap(Map<String, dynamic> map) {
    return AppointmentVehicleRecord(
      id: map['id']?.toString() ?? '',
      licensePlate: map['license_plate']?.toString() ?? '',
      vehicleType: map['vehicle_type']?.toString(),
      brand: map['brand']?.toString(),
      model: map['model']?.toString(),
      year: map['year'] is int ? map['year'] as int : null,
      color: map['color']?.toString(),
      fuelType: map['fuel_type']?.toString(),
      transmissionType: map['transmission_type']?.toString(),
    );
  }

  final String id;
  final String licensePlate;
  final String? vehicleType;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final String? fuelType;
  final String? transmissionType;
}

class SupabaseAppointmentBookingRemoteDataSource
    implements AppointmentBookingRemoteDataSource {
  const SupabaseAppointmentBookingRemoteDataSource(this.client);

  final SupabaseClient client;

  static const _vehicleSelect = '''
    id,
    license_plate,
    vehicle_type,
    brand,
    model,
    year,
    color,
    fuel_type,
    transmission_type,
    customers!inner(user_id, workshop_id)
  ''';

  @override
  Future<List<AppointmentVehicleRecord>> getCustomerVehicles({
    required String workshopId,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    final response = await client
        .from('vehicles')
        .select(_vehicleSelect)
        .eq('is_active', true)
        .eq('customers.user_id', userId)
        .eq('customers.workshop_id', workshopId)
        .order('updated_at', ascending: false);

    return response
        .map((item) => AppointmentVehicleRecord.fromMap(item))
        .toList();
  }

  @override
  Future<AppointmentVehicleRecord?> getCustomerVehicleByPlate({
    required String workshopId,
    required String licensePlate,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final response = await client
        .from('vehicles')
        .select(_vehicleSelect)
        .eq('license_plate', licensePlate.trim().toUpperCase())
        .eq('is_active', true)
        .eq('customers.user_id', userId)
        .eq('customers.workshop_id', workshopId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return AppointmentVehicleRecord.fromMap(response);
  }

  @override
  Future<bool> isAppointmentSlotAvailable({
    required String workshopId,
    required DateTime scheduledDateTime,
  }) async {
    final response = await client
        .from('appointments')
        .select('id, order_services!inner(orders!inner(workshop_id))')
        .eq('scheduled_datetime', scheduledDateTime.toUtc().toIso8601String())
        .eq('order_services.orders.workshop_id', workshopId)
        .not('appointment_status', 'in', '(cancelled,no_show)')
        .limit(1);

    return response.isEmpty;
  }

  @override
  Future<List<DateTime>> getBookedAppointmentSlots({
    required String workshopId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await client
        .from('appointments')
        .select(
          'scheduled_datetime, order_services!inner(orders!inner(workshop_id))',
        )
        .gte('scheduled_datetime', startDate.toUtc().toIso8601String())
        .lt('scheduled_datetime', endDate.toUtc().toIso8601String())
        .eq('order_services.orders.workshop_id', workshopId)
        .not('appointment_status', 'in', '(cancelled,no_show)');

    return response
        .map((item) => DateTime.tryParse(item['scheduled_datetime'].toString()))
        .whereType<DateTime>()
        .toList();
  }

  @override
  Future<String> bookServiceAppointment({
    required String workshopId,
    required String inventoryItemId,
    required DateTime scheduledDateTime,
    String? note,
    String? vehicleId,
    String? licensePlate,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    int? vehicleYear,
    String? vehicleColor,
    String? fuelType,
    String? transmissionType,
  }) async {
    final response = await client.rpc(
      'book_service_appointment',
      params: {
        'p_workshop_id': workshopId,
        'p_inventory_item_id': inventoryItemId,
        'p_scheduled_datetime': scheduledDateTime.toUtc().toIso8601String(),
        'p_note': note,
        'p_vehicle_id': vehicleId,
        'p_license_plate': licensePlate,
        'p_vehicle_type': vehicleType,
        'p_vehicle_brand': vehicleBrand,
        'p_vehicle_model': vehicleModel,
        'p_vehicle_year': vehicleYear,
        'p_vehicle_color': vehicleColor,
        'p_fuel_type': fuelType,
        'p_transmission_type': transmissionType,
      },
    );

    return response.toString();
  }
}
