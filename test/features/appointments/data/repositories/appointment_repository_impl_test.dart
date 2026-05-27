import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/appointments/data/datasources/appointment_remote_data_source.dart';
import 'package:autolab_customer/features/appointments/data/models/appointment_model.dart';
import 'package:autolab_customer/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:autolab_customer/features/appointments/domain/entities/appointment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
  });

  setUp(() {
    remoteDataSource = MockAppointmentRemoteDataSource();
    errorHandler = MockGlobalErrorHandler();
    featureLogger = MockFeatureLogger();
    repository = AppointmentRepositoryImpl(
      remoteDataSource: remoteDataSource,
      errorHandler: errorHandler,
      featureLogger: featureLogger,
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

  test('getAppointmentsByWorkshop retorna citas del datasource', () async {
    when(
      () => remoteDataSource.getAppointmentsByWorkshop('workshop-1'),
    ).thenAnswer((_) async => [_appointment()]);

    final result = await repository.getAppointmentsByWorkshop('workshop-1');

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => const []), hasLength(1));
    verify(
      () => remoteDataSource.getAppointmentsByWorkshop('workshop-1'),
    ).called(1);
  });

  test('createAppointment mapea timeout a Failure controlado', () async {
    when(
      () => remoteDataSource.createAppointment(any()),
    ).thenThrow(TimeoutException('timeout'));

    final result = await repository.createAppointment(_draft());

    expect(result.isLeft(), isTrue);
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

AppointmentModel _appointment() {
  return AppointmentModel(
    id: 'appt-1',
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
