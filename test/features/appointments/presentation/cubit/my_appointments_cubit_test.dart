import 'dart:async';

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
      isA<MyAppointmentsState>().having(
        (state) => state.status,
        'status',
        MyAppointmentsStatus.loading,
      ),
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
    expect: () => [
      isA<MyAppointmentsState>().having(
        (state) => state.status,
        'status',
        MyAppointmentsStatus.loading,
      ),
      isA<MyAppointmentsState>()
          .having((state) => state.status, 'status', MyAppointmentsStatus.error)
          .having((state) => state.message, 'message', 'No se pudo cargar'),
    ],
  );

  blocTest<MyAppointmentsCubit, MyAppointmentsState>(
    'cancelAppointment reemplaza la cita cancelada',
    build: () {
      when(
        () => repository.cancelAppointment(
          appointmentId: 'appt-1',
          reason: 'No podre asistir',
          comments: 'Cambio de planes',
        ),
      ).thenAnswer(
        (_) async => Right(
          _appointment(
            id: 'appt-1',
            scheduledAt: DateTime.utc(2026, 6, 1),
            status: 'cancelled',
          ),
        ),
      );

      return MyAppointmentsCubit(repository);
    },
    seed: () => MyAppointmentsState(
      status: MyAppointmentsStatus.success,
      appointments: [
        _appointment(id: 'appt-1', scheduledAt: DateTime.utc(2026, 6, 1)),
      ],
    ),
    act: (cubit) => cubit.cancelAppointment(
      appointment: cubit.state.appointments.first,
      reason: 'No podre asistir',
      comments: 'Cambio de planes',
    ),
    expect: () => [
      isA<MyAppointmentsState>().having(
        (state) => state.cancelingAppointmentId,
        'canceling appointment id',
        'appt-1',
      ),
      isA<MyAppointmentsState>()
          .having(
            (state) => state.status,
            'status',
            MyAppointmentsStatus.success,
          )
          .having(
            (state) => state.appointments.first.status,
            'appointment status',
            'cancelled',
          ),
      isA<MyAppointmentsState>().having(
        (state) => state.cancelingAppointmentId,
        'canceling appointment id',
        isNull,
      ),
    ],
  );

  blocTest<MyAppointmentsCubit, MyAppointmentsState>(
    'cancelAppointment conserva la cita y expone el error cuando falla',
    build: () {
      when(
        () => repository.cancelAppointment(
          appointmentId: 'appt-1',
          reason: 'No podre asistir',
          comments: null,
        ),
      ).thenAnswer(
        (_) async => const Left(
          ServerFailure(
            message: 'No se pudo cancelar',
            code: 'APPOINTMENT_NOT_CANCELABLE',
          ),
        ),
      );

      return MyAppointmentsCubit(repository);
    },
    seed: () => MyAppointmentsState(
      status: MyAppointmentsStatus.success,
      appointments: [
        _appointment(id: 'appt-1', scheduledAt: DateTime.utc(2026, 6, 1)),
      ],
    ),
    act: (cubit) => cubit.cancelAppointment(
      appointment: cubit.state.appointments.first,
      reason: 'No podre asistir',
    ),
    expect: () => [
      isA<MyAppointmentsState>().having(
        (state) => state.cancelingAppointmentId,
        'canceling appointment id',
        'appt-1',
      ),
      isA<MyAppointmentsState>()
          .having(
            (state) => state.cancelingAppointmentId,
            'canceling appointment id',
            isNull,
          )
          .having(
            (state) => state.appointments.first.status,
            'appointment status',
            'pending',
          )
          .having((state) => state.message, 'message', 'No se pudo cancelar')
          .having((state) => state.code, 'code', 'APPOINTMENT_NOT_CANCELABLE'),
    ],
  );

  test('cancelAppointment bloquea una segunda solicitud simultanea', () async {
    final completer = Completer<Either<Failure, Appointment>>();
    final appointment = _appointment(
      id: 'appt-1',
      scheduledAt: DateTime.utc(2026, 6, 1),
    );
    when(
      () => repository.cancelAppointment(
        appointmentId: 'appt-1',
        reason: 'No podre asistir',
        comments: null,
      ),
    ).thenAnswer((_) => completer.future);
    final cubit = MyAppointmentsCubit(repository);

    final firstRequest = cubit.cancelAppointment(
      appointment: appointment,
      reason: 'No podre asistir',
    );
    final secondResult = await cubit.cancelAppointment(
      appointment: appointment,
      reason: 'No podre asistir',
    );

    expect(secondResult, isFalse);
    verify(
      () => repository.cancelAppointment(
        appointmentId: 'appt-1',
        reason: 'No podre asistir',
        comments: null,
      ),
    ).called(1);

    completer.complete(
      Right(
        _appointment(
          id: 'appt-1',
          scheduledAt: DateTime.utc(2026, 6, 1),
          status: 'cancelled',
        ),
      ),
    );
    expect(await firstRequest, isTrue);
    await cubit.close();
  });

  blocTest<MyAppointmentsCubit, MyAppointmentsState>(
    'rescheduleAppointment reemplaza la cita reagendada',
    build: () {
      final scheduledAt = DateTime.utc(2026, 6, 18, 15);
      when(
        () => repository.rescheduleAppointment(
          appointmentId: 'appt-1',
          scheduledAt: scheduledAt,
        ),
      ).thenAnswer(
        (_) async => Right(
          _appointment(
            id: 'appt-1',
            scheduledAt: scheduledAt,
            status: 'scheduled',
          ),
        ),
      );

      return MyAppointmentsCubit(repository);
    },
    seed: () => MyAppointmentsState(
      status: MyAppointmentsStatus.success,
      appointments: [
        _appointment(id: 'appt-1', scheduledAt: DateTime.utc(2026, 6, 1)),
      ],
    ),
    act: (cubit) => cubit.rescheduleAppointment(
      appointment: cubit.state.appointments.first,
      scheduledAt: DateTime.utc(2026, 6, 18, 15),
    ),
    expect: () => [
      isA<MyAppointmentsState>().having(
        (state) => state.reschedulingAppointmentId,
        'rescheduling appointment id',
        'appt-1',
      ),
      isA<MyAppointmentsState>()
          .having(
            (state) => state.status,
            'status',
            MyAppointmentsStatus.success,
          )
          .having(
            (state) => state.appointments.first.scheduledAt,
            'scheduled at',
            DateTime.utc(2026, 6, 18, 15),
          ),
      isA<MyAppointmentsState>().having(
        (state) => state.reschedulingAppointmentId,
        'rescheduling appointment id',
        isNull,
      ),
    ],
  );
}

Appointment _appointment({
  required String id,
  required DateTime scheduledAt,
  String status = 'pending',
}) {
  return Appointment(
    id: id,
    workshopId: 'workshop-1',
    serviceId: 'service-1',
    customerName: 'Cliente Autolab',
    customerPhone: '8888-8888',
    customerEmail: 'cliente@autolab.app',
    vehicleType: 'AUTOMOVIL',
    scheduledAt: scheduledAt,
    status: status,
  );
}
