import 'dart:async';
import 'dart:io';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/errors/customer_error_catalog.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/appointments/data/datasources/appointment_remote_data_source.dart';
import 'package:autolab_customer/features/appointments/data/models/appointment_model.dart';
import 'package:autolab_customer/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:autolab_customer/features/appointments/domain/entities/appointment.dart';
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
      () => remoteDataSource.createAppointment(any()),
    ).thenAnswer((_) async => _appointment());

    final result = await repository.createAppointment(_draft());

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => throw StateError('missing')).id, 'appt-1');
    verify(() => remoteDataSource.createAppointment(any())).called(1);
  });

  test(
    'getAppointmentsByWorkshop retorna solo citas del usuario actual',
    () async {
      when(
        () => remoteDataSource.getAppointmentsByWorkshop('workshop-1'),
      ).thenAnswer(
        (_) async => [
          _appointment(id: 'appt-1', customerId: 'user-1'),
          _appointment(id: 'appt-2', customerId: 'other-user'),
        ],
      );

      final result = await repository.getAppointmentsByWorkshop('workshop-1');
      final appointments = result.getOrElse(() => const []);

      expect(result.isRight(), isTrue);
      expect(appointments, hasLength(1));
      expect(appointments.first.id, 'appt-1');
      expect(appointments.first.customerId, 'user-1');
      verify(
        () => remoteDataSource.getAppointmentsByWorkshop('workshop-1'),
      ).called(1);
    },
  );

  test('createAppointment mapea timeout a Failure controlado', () async {
    when(
      () => remoteDataSource.createAppointment(any()),
    ).thenThrow(TimeoutException('timeout'));

    final result = await repository.createAppointment(_draft());

    expect(result.isLeft(), isTrue);
  });

  test('createAppointment mapea error de red a Failure controlado', () async {
    when(
      () => remoteDataSource.createAppointment(any()),
    ).thenThrow(const SocketException('sin conexion'));

    final result = await repository.createAppointment(_draft());

    expect(result.isLeft(), isTrue);
  });

  test(
    'createAppointment usa error item especifico para PostgrestException',
    () async {
      when(
        () => remoteDataSource.createAppointment(any()),
      ).thenThrow(const PostgrestException(message: 'server error'));

      final result = await repository.createAppointment(_draft());

      final failure = result.swap().getOrElse(
        () => throw StateError('expected failure'),
      );

      expect(failure.code, CustomerErrorCatalog.createAppointmentFailed.code);
      expect(failure.uiKey, CustomerErrorCatalog.createAppointmentFailed.uiKey);
    },
  );

  test(
    'createAppointment mapea error de parsing a Failure controlado',
    () async {
      final failure = const ValidationFailure(message: 'payload invalido');
      when(
        () => remoteDataSource.createAppointment(any()),
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
      () => remoteDataSource.createAppointment(any()),
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
        () => remoteDataSource.getAppointmentsByWorkshop('workshop-1'),
      ).thenThrow(TimeoutException('timeout'));

      final result = await repository.getAppointmentsByWorkshop('workshop-1');

      expect(result.isLeft(), isTrue);
    },
  );

  test(
    'getAppointmentsByWorkshop mapea error de red a Failure controlado',
    () async {
      when(
        () => remoteDataSource.getAppointmentsByWorkshop('workshop-1'),
      ).thenThrow(const SocketException('sin conexion'));

      final result = await repository.getAppointmentsByWorkshop('workshop-1');

      expect(result.isLeft(), isTrue);
    },
  );

  test(
    'getAppointmentsByWorkshop mapea error de servidor a Failure controlado',
    () async {
      when(
        () => remoteDataSource.getAppointmentsByWorkshop('workshop-1'),
      ).thenThrow(const PostgrestException(message: 'server error'));

      final result = await repository.getAppointmentsByWorkshop('workshop-1');

      expect(result.isLeft(), isTrue);
    },
  );

  test(
    'getAppointmentsByWorkshop mapea error de parsing a Failure controlado',
    () async {
      final failure = const ValidationFailure(message: 'payload invalido');
      when(
        () => remoteDataSource.getAppointmentsByWorkshop('workshop-1'),
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
