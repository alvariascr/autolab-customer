import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/appointments/domain/entities/appointment.dart';
import 'package:autolab_customer/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:autolab_customer/features/appointments/presentation/cubit/my_appointments_cubit.dart';
import 'package:autolab_customer/features/appointments/presentation/cubit/my_appointments_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

void main() {
  late MockAppointmentRepository repository;

  setUp(() {
    repository = MockAppointmentRepository();
  });

  blocTest<MyAppointmentsCubit, MyAppointmentsState>(
    'load emite citas ordenadas por fecha',
    build: () {
      when(() => repository.getCustomerAppointments()).thenAnswer(
        (_) async => Right([
          _appointment(id: 'later', scheduledAt: DateTime.utc(2026, 6, 3)),
          _appointment(id: 'first', scheduledAt: DateTime.utc(2026, 6, 1)),
        ]),
      );

      return MyAppointmentsCubit(repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const MyAppointmentsState(status: MyAppointmentsStatus.loading),
      isA<MyAppointmentsState>()
          .having(
            (state) => state.status,
            'status',
            MyAppointmentsStatus.success,
          )
          .having(
            (state) => state.appointments.map((appointment) {
              return appointment.id;
            }).toList(),
            'IDs ordenados cronologicamente',
            ['first', 'later'],
          ),
    ],
  );

  blocTest<MyAppointmentsCubit, MyAppointmentsState>(
    'load emite error cuando repository falla',
    build: () {
      when(() => repository.getCustomerAppointments()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'No se pudo cargar')),
      );

      return MyAppointmentsCubit(repository);
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      MyAppointmentsState(status: MyAppointmentsStatus.loading),
      MyAppointmentsState(
        status: MyAppointmentsStatus.error,
        message: 'No se pudo cargar',
      ),
    ],
  );
}

Appointment _appointment({required String id, required DateTime scheduledAt}) {
  return Appointment(
    id: id,
    workshopId: 'workshop-1',
    serviceId: 'service-1',
    customerName: 'Cliente Autolab',
    customerPhone: '8888-8888',
    customerEmail: 'cliente@autolab.app',
    vehicleType: 'AUTOMOVIL',
    scheduledAt: scheduledAt,
    status: 'pending',
  );
}
