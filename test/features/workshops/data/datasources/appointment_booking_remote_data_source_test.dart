import 'package:autolab_customer/core/utils/costa_rica_time.dart';
import 'package:autolab_customer/features/workshops/data/datasources/appointment_booking_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient('https://project.supabase.co', 'anon-key');
  });

  group('isAppointmentSlotAvailable', () {
    test('no hay cupo cuando la capacidad de empleados activos es 0', () async {
      final dataSource = SupabaseAppointmentBookingRemoteDataSource(
        client,
        employeeCapacityProvider: (_) async => 0,
        bookedAppointmentsQuery: (_, _, _) async => const [],
      );

      final available = await dataSource.isAppointmentSlotAvailable(
        workshopId: 'workshop-1',
        scheduledDateTime: DateTime(2026, 3, 10, 9),
      );

      expect(available, isFalse);
    });

    test('hay cupo cuando no hay citas reservadas que se solapen', () async {
      final dataSource = SupabaseAppointmentBookingRemoteDataSource(
        client,
        employeeCapacityProvider: (_) async => 1,
        bookedAppointmentsQuery: (_, _, _) async => const [],
      );

      final available = await dataSource.isAppointmentSlotAvailable(
        workshopId: 'workshop-1',
        scheduledDateTime: DateTime(2026, 3, 10, 9),
      );

      expect(available, isTrue);
    });

    test(
      'no hay cupo cuando la unica cita reservada llena la capacidad del taller',
      () async {
        final dataSource = SupabaseAppointmentBookingRemoteDataSource(
          client,
          employeeCapacityProvider: (_) async => 1,
          bookedAppointmentsQuery: (_, _, _) async => [
            _appointmentRow(start: DateTime(2026, 3, 10, 9)),
          ],
        );

        final available = await dataSource.isAppointmentSlotAvailable(
          workshopId: 'workshop-1',
          scheduledDateTime: DateTime(2026, 3, 10, 9),
        );

        expect(available, isFalse);
      },
    );

    test('ignora una cita cuya orden quedo sin pagar y ya vencio', () async {
      final dataSource = SupabaseAppointmentBookingRemoteDataSource(
        client,
        employeeCapacityProvider: (_) async => 1,
        bookedAppointmentsQuery: (_, _, _) async => [
          _appointmentRow(
            start: DateTime(2026, 3, 10, 9),
            paymentStatus: 'unpaid',
            paymentExpiresAt: DateTime.utc(2000, 1, 1),
          ),
        ],
      );

      final available = await dataSource.isAppointmentSlotAvailable(
        workshopId: 'workshop-1',
        scheduledDateTime: DateTime(2026, 3, 10, 9),
      );

      expect(available, isTrue);
    });

    test(
      'inspecciones usan el doble de capacidad agrupadas por hora',
      () async {
        final dataSource = SupabaseAppointmentBookingRemoteDataSource(
          client,
          employeeCapacityProvider: (_) async => 1,
          bookedAppointmentsQuery: (_, _, _) async => [
            _appointmentRow(
              start: DateTime(2026, 3, 10, 9, 0),
              serviceName: 'Inspección técnica',
            ),
          ],
        );

        final available = await dataSource.isAppointmentSlotAvailable(
          workshopId: 'workshop-1',
          scheduledDateTime: DateTime(2026, 3, 10, 9, 15),
          isInspectionService: true,
        );

        expect(available, isTrue);
      },
    );

    test(
      'bloquea la segunda inspeccion de la misma hora cuando ya se alcanzo el doble de capacidad',
      () async {
        final dataSource = SupabaseAppointmentBookingRemoteDataSource(
          client,
          employeeCapacityProvider: (_) async => 1,
          bookedAppointmentsQuery: (_, _, _) async => [
            _appointmentRow(
              start: DateTime(2026, 3, 10, 9, 0),
              serviceName: 'Inspección técnica',
            ),
            _appointmentRow(
              start: DateTime(2026, 3, 10, 9, 30),
              serviceName: 'Inspección técnica',
            ),
          ],
        );

        final available = await dataSource.isAppointmentSlotAvailable(
          workshopId: 'workshop-1',
          scheduledDateTime: DateTime(2026, 3, 10, 9, 45),
          isInspectionService: true,
        );

        expect(available, isFalse);
      },
    );
  });

  group('getBookedAppointmentSlots', () {
    test(
      'mapea las citas a hora local de Costa Rica y excluye las que no bloquean cupo',
      () async {
        final dataSource = SupabaseAppointmentBookingRemoteDataSource(
          client,
          bookedAppointmentsQuery: (_, _, _) async => [
            _appointmentRow(
              start: DateTime(2026, 3, 10, 9),
              serviceName: 'Cambio de aceite',
              durationHours: 1,
            ),
            _appointmentRow(
              start: DateTime(2026, 3, 10, 11),
              paymentStatus: 'unpaid',
              paymentExpiresAt: DateTime.utc(2000, 1, 1),
            ),
          ],
        );

        final slots = await dataSource.getBookedAppointmentSlots(
          workshopId: 'workshop-1',
          startDate: DateTime(2026, 3, 10),
          endDate: DateTime(2026, 3, 11),
        );

        expect(slots, hasLength(1));
        // Comparado por componentes en vez de con DateTime(...) == DateTime(...):
        // un DateTime "local" sin zona horaria explícita depende de la del
        // sistema donde corra el test, así que esto evita que la aserción
        // dependa de en qué zona horaria esté configurado el runner de CI.
        final start = slots.single.start;
        expect(start.year, 2026);
        expect(start.month, 3);
        expect(start.day, 10);
        expect(start.hour, 9);
        expect(start.minute, 0);
        expect(slots.single.durationMinutes, 60);
        expect(slots.single.isInspectionService, isFalse);
      },
    );
  });
}

Map<String, dynamic> _appointmentRow({
  required DateTime start,
  String serviceName = 'Cambio de aceite',
  double? durationHours,
  String paymentStatus = 'paid',
  DateTime? paymentExpiresAt,
}) {
  return {
    'scheduled_datetime': costaRicaLocalTimeToUtc(start).toIso8601String(),
    'order_services': {
      'inventory_items': {
        'name': serviceName,
        'estimated_duration_hours': durationHours,
      },
      'orders': {
        'workshop_id': 'workshop-1',
        'payment_status': paymentStatus,
        'payment_expires_at': paymentExpiresAt?.toIso8601String(),
      },
    },
  };
}
