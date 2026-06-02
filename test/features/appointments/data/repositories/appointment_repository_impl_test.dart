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
      currentUserIdProvider: () => 'user-1',
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
    expect(customerId, 'user-1');
  });

  test(
    'getAppointmentsByWorkshop delega filtro por usuario al datasource',
    () async {
      when(
        () => remoteDataSource.getAppointmentsByWorkshop(
          workshopId: 'workshop-1',
          customerId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => [_appointment(id: 'appt-1', customerId: 'user-1')],
      );

      final result = await repository.getAppointmentsByWorkshop('workshop-1');
      final appointments = result.getOrElse(() => const []);

      expect(result.isRight(), isTrue);
      expect(appointments, hasLength(1));
      expect(appointments.first.id, 'appt-1');
      expect(appointments.first.customerId, 'user-1');
      verify(
        () => remoteDataSource.getAppointmentsByWorkshop(
          workshopId: 'workshop-1',
          customerId: 'user-1',
        ),
      ).called(1);
    },
  );

  test(
    'getCustomerAppointments delega filtro por usuario al datasource',
    () async {
      when(
        () => remoteDataSource.getCustomerAppointments(customerId: 'user-1'),
      ).thenAnswer(
        (_) async => [_appointment(id: 'appt-1', customerId: 'user-1')],
      );

      final result = await repository.getCustomerAppointments();
      final appointments = result.getOrElse(() => const []);

      expect(result.isRight(), isTrue);
      expect(appointments, hasLength(1));
      expect(appointments.first.customerId, 'user-1');
      verify(
        () => remoteDataSource.getCustomerAppointments(customerId: 'user-1'),
      ).called(1);
    },
  );

  test('getCustomerAppointments retorna fallo de auth sin usuario', () async {
    repository = AppointmentRepositoryImpl(
      remoteDataSource: remoteDataSource,
      errorHandler: errorHandler,
      featureLogger: featureLogger,
      currentUserIdProvider: () => null,
    );

    final result = await repository.getCustomerAppointments();

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
    scheduledAt: DateTime.utc(2026, 5, 28, 6, 15),
    status: 'pending',
  );
}
