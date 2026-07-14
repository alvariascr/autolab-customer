import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/workshops/data/datasources/workshop_remote_data_source.dart';
import 'package:autolab_customer/features/workshops/data/models/workshop_model.dart';
import 'package:autolab_customer/features/workshops/data/repositories/workshop_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkshopRemoteDataSource extends Mock
    implements WorkshopRemoteDataSource {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class MockFeatureLogger extends Mock implements FeatureLogger {}

void main() {
  group('WorkshopRepositoryImpl', () {
    late MockWorkshopRemoteDataSource remoteDataSource;
    late MockGlobalErrorHandler errorHandler;
    late MockFeatureLogger featureLogger;
    late WorkshopRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockWorkshopRemoteDataSource();
      errorHandler = MockGlobalErrorHandler();
      featureLogger = MockFeatureLogger();

      when(
        () => featureLogger.info(
          feature: any(named: 'feature'),
          action: any(named: 'action'),
          code: any(named: 'code'),
          context: any(named: 'context'),
        ),
      ).thenReturn(null);

      repository = WorkshopRepositoryImpl(
        remoteDataSource: remoteDataSource,
        errorHandler: errorHandler,
        featureLogger: featureLogger,
      );
    });

    test('reutiliza talleres en memoria despues de la primera carga', () async {
      when(
        () => remoteDataSource.getWorkshops(),
      ).thenAnswer((_) async => _workshops);

      final firstResult = await repository.getWorkshops();
      final secondResult = await repository.getWorkshops();

      verify(() => remoteDataSource.getWorkshops()).called(1);
      expect(firstResult.getOrElse(() => const []), _workshops);
      expect(secondResult.getOrElse(() => const []), _workshops);
    });

    test('deduplica llamadas concurrentes de talleres', () async {
      final completer = Completer<List<WorkshopModel>>();
      when(
        () => remoteDataSource.getWorkshops(),
      ).thenAnswer((_) => completer.future);

      final firstRequest = repository.getWorkshops();
      final secondRequest = repository.getWorkshops();

      completer.complete(_workshops);

      final firstResult = await firstRequest;
      final secondResult = await secondRequest;

      verify(() => remoteDataSource.getWorkshops()).called(1);
      expect(firstResult.getOrElse(() => const []), _workshops);
      expect(secondResult.getOrElse(() => const []), _workshops);
    });
  });
}

const _workshops = [
  WorkshopModel(
    id: 'workshop-1',
    name: 'Taller Central',
    description: 'Servicio general',
    locationAddress: 'San Jose',
    avatarUrl: '',
    coverUrl: '',
    latitude: 9.93,
    longitude: -84.08,
    deliveryRadiusKm: 10,
  ),
];
