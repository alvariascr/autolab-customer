import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/costa_rica_time.dart';
import '../../domain/entities/appointment_product_selection.dart';
import '../../domain/entities/appointment_vehicle.dart';
import '../../domain/entities/booked_appointment_slot.dart';
import '../../domain/services/appointment_service_classifier.dart';

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
    double? serviceDurationHours,
    bool isInspectionService = false,
  });

  Future<List<BookedAppointmentSlot>> getBookedAppointmentSlots({
    required String workshopId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<String> bookServiceAppointment({
    required String workshopId,
    required String inventoryItemId,
    required DateTime scheduledDateTime,
    List<AppointmentProductSelection> products = const [],
    String? note,
    String? vehicleId,
    String? garageVehicleId,
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
    transmission_type
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
        .from('garage_vehicles')
        .select(_vehicleSelect)
        .eq('is_active', true)
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return response.map((item) => _appointmentVehicleFromMap(item)).toList();
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
        .from('garage_vehicles')
        .select(_vehicleSelect)
        .eq('license_plate', licensePlate.trim().toUpperCase())
        .eq('is_active', true)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _appointmentVehicleFromMap(response);
  }

  @override
  Future<bool> isAppointmentSlotAvailable({
    required String workshopId,
    required DateTime scheduledDateTime,
    double? serviceDurationHours,
    bool isInspectionService = false,
  }) async {
    final employeeCapacity = await _activeEmployeeCapacityFor(workshopId);
    if (employeeCapacity <= 0) {
      return false;
    }

    final appointmentEnd = scheduledDateTime.add(
      _serviceDuration(serviceDurationHours),
    );
    final startDate = DateTime(
      scheduledDateTime.year,
      scheduledDateTime.month,
      scheduledDateTime.day,
    );
    final endDate = startDate.add(const Duration(days: 1));
    final response = await client
        .from('appointments')
        .select(
          'scheduled_datetime, order_services!inner(inventory_items!inner(name, estimated_duration_hours), orders!inner(workshop_id, payment_status, payment_expires_at))',
        )
        .gte(
          'scheduled_datetime',
          costaRicaLocalTimeToUtc(startDate).toIso8601String(),
        )
        .lt(
          'scheduled_datetime',
          costaRicaLocalTimeToUtc(endDate).toIso8601String(),
        )
        .eq('order_services.orders.workshop_id', workshopId)
        .not('appointment_status', 'in', '(cancelled,no_show)');

    final bookedSlots = response
        .where(_isBlockingAppointment)
        .map(_bookedAppointmentSlotFromMap)
        .whereType<BookedAppointmentSlot>()
        .toList();

    return _hasCapacityForServiceWindow(
      slotStart: scheduledDateTime,
      slotEnd: appointmentEnd,
      bookedSlots: bookedSlots,
      capacity: isInspectionService ? employeeCapacity * 2 : employeeCapacity,
      isInspectionService: isInspectionService,
    );
  }

  @override
  Future<List<BookedAppointmentSlot>> getBookedAppointmentSlots({
    required String workshopId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await client
        .from('appointments')
        .select(
          'scheduled_datetime, order_services!inner(inventory_items!inner(name, estimated_duration_hours), orders!inner(workshop_id, payment_status, payment_expires_at))',
        )
        .gte(
          'scheduled_datetime',
          costaRicaLocalTimeToUtc(startDate).toIso8601String(),
        )
        .lt(
          'scheduled_datetime',
          costaRicaLocalTimeToUtc(endDate).toIso8601String(),
        )
        .eq('order_services.orders.workshop_id', workshopId)
        .not('appointment_status', 'in', '(cancelled,no_show)');

    return response
        .where(_isBlockingAppointment)
        .map(_bookedAppointmentSlotFromMap)
        .whereType<BookedAppointmentSlot>()
        .toList();
  }

  @override
  Future<String> bookServiceAppointment({
    required String workshopId,
    required String inventoryItemId,
    required DateTime scheduledDateTime,
    List<AppointmentProductSelection> products = const [],
    String? note,
    String? vehicleId,
    String? garageVehicleId,
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
        'p_scheduled_date': _formatDate(scheduledDateTime),
        'p_scheduled_time': _formatTime(scheduledDateTime),
        'p_products': products
            .map(
              (product) => {
                'inventoryItemId': product.inventoryItemId,
                'quantity': product.quantity,
              },
            )
            .toList(growable: false),
        'p_note': note,
        'p_vehicle_id': vehicleId,
        'p_garage_vehicle_id': garageVehicleId,
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:00';
  }

  Future<int> _activeEmployeeCapacityFor(String workshopId) async {
    final response = await client.rpc(
      'get_workshop_active_employee_count',
      params: {'p_workshop_id': workshopId},
    );

    if (response is int) {
      return response;
    }

    return int.tryParse(response?.toString() ?? '') ?? 0;
  }

  Duration _serviceDuration(double? serviceDurationHours) {
    final minutes =
        serviceDurationHours == null ||
            !serviceDurationHours.isFinite ||
            serviceDurationHours <= 0
        ? 30
        : (serviceDurationHours * Duration.minutesPerHour).ceil();

    return Duration(minutes: minutes);
  }

  bool _hasCapacityForServiceWindow({
    required DateTime slotStart,
    required DateTime slotEnd,
    required List<BookedAppointmentSlot> bookedSlots,
    required int capacity,
    required bool isInspectionService,
  }) {
    const slotInterval = Duration(minutes: 30);

    if (isInspectionService) {
      final hourStart = DateTime(
        slotStart.year,
        slotStart.month,
        slotStart.day,
        slotStart.hour,
      );
      final hourEnd = hourStart.add(const Duration(hours: 1));
      final sameHourInspectionCount = bookedSlots.where((slot) {
        return slot.isInspectionService &&
            !slot.start.isBefore(hourStart) &&
            slot.start.isBefore(hourEnd);
      }).length;

      return sameHourInspectionCount < capacity;
    }

    for (
      var segmentStart = slotStart;
      segmentStart.isBefore(slotEnd);
      segmentStart = segmentStart.add(slotInterval)
    ) {
      final segmentEnd = segmentStart.add(slotInterval).isAfter(slotEnd)
          ? slotEnd
          : segmentStart.add(slotInterval);
      final overlapping = bookedSlots.where((slot) {
        if (slot.isInspectionService) {
          return false;
        }

        final bookedEnd = slot.start.add(
          Duration(minutes: slot.durationMinutes ?? 30),
        );
        return slot.start.isBefore(segmentEnd) &&
            bookedEnd.isAfter(segmentStart);
      }).length;

      if (overlapping >= capacity) {
        return false;
      }
    }

    return true;
  }
}

BookedAppointmentSlot? _bookedAppointmentSlotFromMap(Map<String, dynamic> map) {
  final scheduledDateTime = DateTime.tryParse(
    map['scheduled_datetime'].toString(),
  );
  if (scheduledDateTime == null) {
    return null;
  }

  final orderService = map['order_services'];
  final inventoryItem = orderService is Map<String, dynamic>
      ? orderService['inventory_items']
      : null;
  final durationHours = inventoryItem is Map<String, dynamic>
      ? _parseDouble(inventoryItem['estimated_duration_hours'])
      : null;
  final serviceName = inventoryItem is Map<String, dynamic>
      ? inventoryItem['name']?.toString() ?? ''
      : '';

  return BookedAppointmentSlot(
    start: utcToCostaRicaLocalTime(scheduledDateTime),
    durationMinutes: durationHours == null || durationHours <= 0
        ? null
        : (durationHours * Duration.minutesPerHour).ceil(),
    isInspectionService: AppointmentServiceClassifier.isInspectionText(
      serviceName,
    ),
  );
}

bool _isBlockingAppointment(Map<String, dynamic> map) {
  final orderService = map['order_services'];
  final order = orderService is Map<String, dynamic>
      ? orderService['orders']
      : null;
  if (order is! Map<String, dynamic>) {
    return true;
  }

  final paymentStatus = order['payment_status']?.toString();
  final paymentExpiresAt = DateTime.tryParse(
    order['payment_expires_at']?.toString() ?? '',
  );

  if (paymentStatus == 'unpaid' &&
      paymentExpiresAt != null &&
      !paymentExpiresAt.toUtc().isAfter(DateTime.now().toUtc())) {
    return false;
  }

  return true;
}

double? _parseDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '');
}

AppointmentVehicleRecord _appointmentVehicleFromMap(Map<String, dynamic> map) {
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
