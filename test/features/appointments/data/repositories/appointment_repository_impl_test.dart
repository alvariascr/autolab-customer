import 'dart:async';
import 'dart:io';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/errors/customer_error_catalog.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/appointments/data/datasources/appointment_remote_data_source.dart';
import 'package:autolab_customer/features/appointments/data/models/appointment_model.dart';
import 'package:autolab_customer/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:autolab_customer/features/appointments/domain/entities/appointment.dart';
import 'package:autolab_customer/features/auth/domain/errors/auth_error_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _currentUserId = 'user-1';

class MockAppointmentRemoteDataSource extends Mock
    implements AppointmentRemoteDataSource {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class MockFeatureLogger extends Mock implements FeatureLogger {}

void main() {
  late MockAppointmentRemoteDataSource remoteDataSource;
  late MockGlobalErrorHandler errorHandler;
  late MockFeatureLogger featureLogger;
  late AppointmentRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_draft());
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(StackTrace.current);
  });

  setUp(() {
    remoteDataSource = MockAppointmentRemoteDataSource();
    errorHandler = MockGlobalErrorHandler();
    featureLogger = MockFeatureLogger();
    repository = AppointmentRepositoryImpl(
      remoteDataSource: remoteDataSource,
      errorHandler: errorHandler,
      featureLogger: featureLogger,
      currentUserIdProvider: () => _currentUserId,
    );
  });

  test('createAppointment retorna Right cuando datasource responde', () async {
    when(
      () => remoteDataSource.createAppointment(
        rpcParams: any(named: 'rpcParams'),
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer((_) async => _appointment());

    final result = await repository.createAppointment(_draft());
    final verification = verify(
      () => remoteDataSource.createAppointment(
        rpcParams: captureAny(named: 'rpcParams'),
        customerId: captureAny(named: 'customerId'),
      ),
    );
    final payload = verification.captured.first as Map<String, dynamic>;
    final customerId = verification.captured.last as String;

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => throw StateError('missing')).id, 'appt-1');
    expect(payload['p_workshop_id'], 'workshop-1');
    expect(payload['p_service_id'], 'service-1');
    expect(payload['p_scheduled_at'], '2026-05-28T06:15:00.000Z');
    expect(customerId, _currentUserId);
  });

  test(
    'getAppointmentsByWorkshop delega filtro por usuario al datasource',
    () async {
      when(
        () => remoteDataSource.getAppointmentsByWorkshop(
          workshopId: 'workshop-1',
          customerId: _currentUserId,
        ),
      ).thenAnswer(
        (_) async => [_appointment(id: 'appt-1', customerId: _currentUserId)],
      );

      final result = await repository.getAppointmentsByWorkshop('workshop-1');
      final appointments = result.getOrElse(() => const []);

      expect(result.isRight(), isTrue);
      expect(appointments, hasLength(1));
      expect(appointments.first.id, 'appt-1');
      expect(appointments.first.customerId, _currentUserId);
      verify(
        () => remoteDataSource.getAppointmentsByWorkshop(
          workshopId: 'workshop-1',
          customerId: _currentUserId,
        ),
      ).called(1);
    },
  );

  test(
    'getCustomerAppointments delega filtro por usuario al datasource',
    () async {
      when(
        () => remoteDataSource.getCustomerAppointments(
          customerId: _currentUserId,
        ),
      ).thenAnswer(
        (_) async => [_appointment(id: 'appt-1', customerId: _currentUserId)],
      );

      final result = await repository.getCustomerAppointments();
      final appointments = result.getOrElse(() => const []);

      expect(result.isRight(), isTrue);
      expect(appointments, hasLength(1));
      expect(appointments.first.customerId, _currentUserId);
      verify(
        () => remoteDataSource.getCustomerAppointments(
          customerId: _currentUserId,
        ),
      ).called(1);
    },
  );

  test('getCustomerAppointments retorna fallo de auth sin usuario', () async {
    final unauthenticatedRepository = AppointmentRepositoryImpl(
      remoteDataSource: remoteDataSource,
      errorHandler: errorHandler,
      featureLogger: featureLogger,
      currentUserIdProvider: () => null,
    );

    final result = await unauthenticatedRepository.getCustomerAppointments();

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.code, AuthErrorCatalog.sessionExpired.code),
      (_) => fail('expected auth failure'),
    );
    verifyNever(
      () => remoteDataSource.getCustomerAppointments(
        customerId: any(named: 'customerId'),
      ),
    );
  });

  test(
    'cancelAppointment delega cancelacion con usuario autenticado',
    () async {
      when(
        () => remoteDataSource.cancelAppointment(
          appointmentId: 'appt-1',
          customerId: _currentUserId,
          reason: 'No podre asistir',
          comments: 'Cambio de planes',
        ),
      ).thenAnswer(
        (_) async => _appointment(
          id: 'appt-1',
          customerId: _currentUserId,
          status: 'cancelled',
        ),
      );

      final result = await repository.cancelAppointment(
        appointmentId: 'appt-1',
        reason: 'No podre asistir',
        comments: 'Cambio de planes',
      );
      final appointment = result.getOrElse(() => throw StateError('missing'));

      expect(result.isRight(), isTrue);
      expect(appointment.status, 'cancelled');
      verify(
        () => remoteDataSource.cancelAppointment(
          appointmentId: 'appt-1',
          customerId: _currentUserId,
          reason: 'No podre asistir',
          comments: 'Cambio de planes',
        ),
      ).called(1);
    },
  );

  test('cancelAppointment retorna fallo de auth sin usuario', () async {
    final unauthenticatedRepository = AppointmentRepositoryImpl(
      remoteDataSource: remoteDataSource,
      errorHandler: errorHandler,
      featureLogger: featureLogger,
      currentUserIdProvider: () => null,
    );

    final result = await unauthenticatedRepository.cancelAppointment(
      appointmentId: 'appt-1',
      reason: 'No podre asistir',
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.code, AuthErrorCatalog.sessionExpired.code),
      (_) => fail('expected auth failure'),
    );
    verifyNever(
      () => remoteDataSource.cancelAppointment(
        appointmentId: any(named: 'appointmentId'),
        customerId: any(named: 'customerId'),
        reason: any(named: 'reason'),
        comments: any(named: 'comments'),
      ),
    );
  });

  test('cancelAppointment mapea error de RPC a Failure controlado', () async {
    final failure = const ServerFailure(message: 'No se pudo cancelar');
    when(
      () => remoteDataSource.cancelAppointment(
        appointmentId: 'appt-1',
        customerId: _currentUserId,
        reason: 'No podre asistir',
        comments: null,
      ),
    ).thenThrow(
      const PostgrestException(message: 'appointment_not_cancelable'),
    );
    when(() => errorHandler.handle(any(), any())).thenReturn(failure);

    final result = await repository.cancelAppointment(
      appointmentId: 'appt-1',
      reason: 'No podre asistir',
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (actual) => expect(actual, failure),
      (_) => fail('expected cancellation failure'),
    );
    verify(() => errorHandler.handle(any(), any())).called(1);
  });

  test(
    'rescheduleAppointment delega nueva fecha con usuario autenticado',
    () async {
      final scheduledAt = DateTime.utc(2026, 6, 18, 15);
      when(
        () => remoteDataSource.rescheduleAppointment(
          appointmentId: 'appt-1',
          customerId: _currentUserId,
          scheduledAt: scheduledAt,
        ),
      ).thenAnswer(
        (_) async => _appointment(
          id: 'appt-1',
          customerId: _currentUserId,
          scheduledAt: scheduledAt,
        ),
      );

      final result = await repository.rescheduleAppointment(
        appointmentId: 'appt-1',
        scheduledAt: scheduledAt,
      );
      final appointment = result.getOrElse(() => throw StateError('missing'));

      expect(result.isRight(), isTrue);
      expect(appointment.scheduledAt, scheduledAt);
      verify(
        () => remoteDataSource.rescheduleAppointment(
          appointmentId: 'appt-1',
          customerId: _currentUserId,
          scheduledAt: scheduledAt,
        ),
      ).called(1);
    },
  );

  test('rescheduleAppointment retorna fallo de auth sin usuario', () async {
    final unauthenticatedRepository = AppointmentRepositoryImpl(
      remoteDataSource: remoteDataSource,
      errorHandler: errorHandler,
      featureLogger: featureLogger,
      currentUserIdProvider: () => null,
    );
    final scheduledAt = DateTime.utc(2026, 6, 18, 15);

    final result = await unauthenticatedRepository.rescheduleAppointment(
      appointmentId: 'appt-1',
      scheduledAt: scheduledAt,
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.code, AuthErrorCatalog.sessionExpired.code),
      (_) => fail('expected auth failure'),
    );
    verifyNever(
      () => remoteDataSource.rescheduleAppointment(
        appointmentId: any(named: 'appointmentId'),
        customerId: any(named: 'customerId'),
        scheduledAt: any(named: 'scheduledAt'),
      ),
    );
  });

  test(
    'rescheduleAppointment mapea error de RPC a Failure controlado',
    () async {
      final scheduledAt = DateTime.utc(2026, 6, 18, 15);
      final failure = const ServerFailure(message: 'No se pudo reagendar');
      when(
        () => remoteDataSource.rescheduleAppointment(
          appointmentId: 'appt-1',
          customerId: _currentUserId,
          scheduledAt: scheduledAt,
        ),
      ).thenThrow(
        const PostgrestException(message: 'appointment_not_reschedulable'),
      );
      when(() => errorHandler.handle(any(), any())).thenReturn(failure);

      final result = await repository.rescheduleAppointment(
        appointmentId: 'appt-1',
        scheduledAt: scheduledAt,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (actual) => expect(actual, failure),
        (_) => fail('expected rescheduling failure'),
      );
      verify(() => errorHandler.handle(any(), any())).called(1);
    },
  );

  test('createAppointment mapea timeout a Failure controlado', () async {
    when(
      () => remoteDataSource.createAppointment(
        rpcParams: any(named: 'rpcParams'),
        customerId: any(named: 'customerId'),
      ),
    ).thenThrow(TimeoutException('timeout'));

    final result = await repository.createAppointment(_draft());

    expect(result.isLeft(), isTrue);
  });

  test('createAppointment mapea error de red a Failure controlado', () async {
    when(
      () => remoteDataSource.createAppointment(
        rpcParams: any(named: 'rpcParams'),
        customerId: any(named: 'customerId'),
      ),
    ).thenThrow(const SocketException('sin conexion'));

    final result = await repository.createAppointment(_draft());

    expect(result.isLeft(), isTrue);
  });

  test(
    'createAppointment delega PostgrestException al error handler',
    () async {
      final failure = ServerFailure.fromErrorItem(
        CustomerErrorCatalog.createAppointmentFailed,
      );
      when(
        () => remoteDataSource.createAppointment(
          rpcParams: any(named: 'rpcParams'),
          customerId: any(named: 'customerId'),
        ),
      ).thenThrow(const PostgrestException(message: 'server error'));
      when(() => errorHandler.handle(any(), any())).thenReturn(failure);

      final result = await repository.createAppointment(_draft());

      expect(result.isLeft(), isTrue);
      expect(result.swap().getOrElse(() => failure), failure);
      verify(() => errorHandler.handle(any(), any())).called(1);
    },
  );

  test(
    'createAppointment mapea error de parsing a Failure controlado',
    () async {
      final failure = const ValidationFailure(message: 'payload invalido');
      when(
        () => remoteDataSource.createAppointment(
          rpcParams: any(named: 'rpcParams'),
          customerId: any(named: 'customerId'),
        ),
      ).thenThrow(const FormatException('payload invalido'));
      when(() => errorHandler.handle(any(), any())).thenReturn(failure);

      final result = await repository.createAppointment(_draft());

      expect(result.isLeft(), isTrue);
      expect(result.swap().getOrElse(() => failure), failure);
      verify(() => errorHandler.handle(any(), any())).called(1);
    },
  );

  test('createAppointment reporta error cuando datasource falla', () async {
    final failure = const UnknownFailure(message: 'missing appointment id');
    when(
      () => remoteDataSource.createAppointment(
        rpcParams: any(named: 'rpcParams'),
        customerId: any(named: 'customerId'),
      ),
    ).thenThrow(StateError('missing appointment id'));
    when(() => errorHandler.handle(any(), any())).thenReturn(failure);

    final result = await repository.createAppointment(_draft());

    expect(result.isLeft(), isTrue);
    expect(result.swap().getOrElse(() => failure), failure);
    verify(() => errorHandler.handle(any(), any())).called(1);
  });

  test(
    'getAppointmentsByWorkshop mapea timeout a Failure controlado',
    () async {
      when(
        () => remoteDataSource.getAppointmentsByWorkshop(
          workshopId: 'workshop-1',
          customerId: 'user-1',
        ),
      ).thenThrow(TimeoutException('timeout'));

      final result = await repository.getAppointmentsByWorkshop('workshop-1');

      expect(result.isLeft(), isTrue);
    },
  );

  test(
    'getAppointmentsByWorkshop mapea error de red a Failure controlado',
    () async {
      when(
        () => remoteDataSource.getAppointmentsByWorkshop(
          workshopId: 'workshop-1',
          customerId: 'user-1',
        ),
      ).thenThrow(const SocketException('sin conexion'));

      final result = await repository.getAppointmentsByWorkshop('workshop-1');

      expect(result.isLeft(), isTrue);
    },
  );

  test(
    'getAppointmentsByWorkshop mapea error de servidor a Failure controlado',
    () async {
      final failure = const ServerFailure(message: 'server error');
      when(
        () => remoteDataSource.getAppointmentsByWorkshop(
          workshopId: 'workshop-1',
          customerId: 'user-1',
        ),
      ).thenThrow(const PostgrestException(message: 'server error'));
      when(() => errorHandler.handle(any(), any())).thenReturn(failure);

      final result = await repository.getAppointmentsByWorkshop('workshop-1');

      expect(result.isLeft(), isTrue);
      expect(result.swap().getOrElse(() => failure), failure);
      verify(() => errorHandler.handle(any(), any())).called(1);
    },
  );

  test(
    'getAppointmentsByWorkshop mapea error de parsing a Failure controlado',
    () async {
      final failure = const ValidationFailure(message: 'payload invalido');
      when(
        () => remoteDataSource.getAppointmentsByWorkshop(
          workshopId: 'workshop-1',
          customerId: 'user-1',
        ),
      ).thenThrow(const FormatException('payload invalido'));
      when(() => errorHandler.handle(any(), any())).thenReturn(failure);

      final result = await repository.getAppointmentsByWorkshop('workshop-1');

      expect(result.isLeft(), isTrue);
      expect(result.swap().getOrElse(() => failure), failure);
      verify(() => errorHandler.handle(any(), any())).called(1);
    },
  );
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

AppointmentModel _appointment({
  String id = 'appt-1',
  String customerId = 'user-1',
  String status = 'pending',
  DateTime? scheduledAt,
}) {
  return AppointmentModel(
    id: id,
    customerId: customerId,
    workshopId: 'workshop-1',
    serviceId: 'service-1',
    customerName: 'Cliente Autolab',
    customerPhone: '8888-8888',
    customerEmail: 'cliente@autolab.app',
    vehicleType: 'AUTOMOVIL',
    scheduledAt: scheduledAt ?? DateTime.utc(2026, 5, 28, 6, 15),
    status: status,
  );
}
