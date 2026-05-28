import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/appointments/domain/entities/appointment.dart';
import 'package:autolab_customer/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:autolab_customer/features/appointments/presentation/cubit/create_appointment_cubit.dart';
import 'package:autolab_customer/features/appointments/presentation/cubit/create_appointment_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppointmentRepository extends Mock implements AppointmentRepository {}

void main() {
  late MockAppointmentRepository repository;

  setUpAll(() {
    registerFallbackValue(_draft());
  });

  setUp(() {
    repository = MockAppointmentRepository();
  });

  blocTest<CreateAppointmentCubit, CreateAppointmentState>(
    'create emite submitting y success cuando repository responde',
    build: () {
      when(
        () => repository.createAppointment(any()),
      ).thenAnswer((_) async => Right(_appointment()));

      return CreateAppointmentCubit(repository);
    },
    act: (cubit) => cubit.create(_draft()),
    expect: () => [
      const CreateAppointmentState(status: CreateAppointmentStatus.submitting),
      CreateAppointmentState(
        status: CreateAppointmentStatus.success,
        appointment: _appointment(),
      ),
    ],
  );

  blocTest<CreateAppointmentCubit, CreateAppointmentState>(
    'create emite submitting y error cuando repository falla',
    build: () {
      when(() => repository.createAppointment(any())).thenAnswer(
        (_) async => const Left(
          ServerFailure(
            message: 'No se pudo crear la cita',
            code: 'CUS_APT_001',
            uiKey: 'appointmentCreateFailed',
          ),
        ),
      );

      return CreateAppointmentCubit(repository);
    },
    act: (cubit) => cubit.create(_draft()),
    expect: () => const [
      CreateAppointmentState(status: CreateAppointmentStatus.submitting),
      CreateAppointmentState(
        status: CreateAppointmentStatus.error,
        message: 'No se pudo crear la cita',
        code: 'CUS_APT_001',
        uiKey: 'appointmentCreateFailed',
      ),
    ],
  );

  test('create ignora reenvios mientras esta submitting', () async {
    final cubit = CreateAppointmentCubit(repository);
    final completer = Completer<Either<Failure, Appointment>>();
    when(
      () => repository.createAppointment(any()),
    ).thenAnswer((_) => completer.future);

    final firstCall = cubit.create(_draft());
    await Future<void>.delayed(Duration.zero);

    await cubit.create(_draft());
    completer.complete(Right(_appointment()));
    await firstCall;

    verify(() => repository.createAppointment(any())).called(1);
    expect(cubit.state.status, CreateAppointmentStatus.success);
    await cubit.close();
  });
}

AppointmentDraft _draft() {
  return AppointmentDraft(
    workshopId: 'workshop-1',
    serviceId: 'service-1',
    customerName: 'Cliente Autolab',
    customerPhone: '8888-8888',
    customerEmail: 'cliente@autolab.app',
    vehicleType: 'AUTOMOVIL',
    scheduledAt: DateTime.utc(2026, 5, 28, 6, 15),
  );
}

Appointment _appointment() {
  return Appointment(
    id: 'appointment-1',
    workshopId: 'workshop-1',
    serviceId: 'service-1',
    customerName: 'Cliente Autolab',
    customerPhone: '8888-8888',
    customerEmail: 'cliente@autolab.app',
    vehicleType: 'AUTOMOVIL',
    scheduledAt: DateTime.utc(2026, 5, 28, 6, 15),
    status: 'pending',
  );
}
