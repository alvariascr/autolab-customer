import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/core/logging/feature_logger.dart';
import 'package:autolab_customer/features/products/data/datasources/product_remote_data_source.dart';
import 'package:autolab_customer/features/products/data/models/product_model.dart';
import 'package:autolab_customer/features/products/data/repositories/product_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRemoteDataSource extends Mock
    implements ProductRemoteDataSource {}

class MockGlobalErrorHandler extends Mock implements GlobalErrorHandler {}

class MockFeatureLogger extends Mock implements FeatureLogger {}

void main() {
  group('ProductRepositoryImpl', () {
    late MockProductRemoteDataSource remoteDataSource;
    late MockGlobalErrorHandler errorHandler;
    late MockFeatureLogger featureLogger;
    late ProductRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockProductRemoteDataSource();
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

      repository = ProductRepositoryImpl(
        remoteDataSource: remoteDataSource,
        errorHandler: errorHandler,
        featureLogger: featureLogger,
      );
    });

    test('reutiliza productos activos despues de la primera carga', () async {
      when(
        () => remoteDataSource.getActiveProducts(),
      ).thenAnswer((_) async => _products);

      final firstResult = await repository.getActiveProducts();
      final secondResult = await repository.getActiveProducts();

      verify(() => remoteDataSource.getActiveProducts()).called(1);
      expect(firstResult.getOrElse(() => const []), _products);
      expect(secondResult.getOrElse(() => const []), _products);
    });

    test('deduplica llamadas concurrentes de productos activos', () async {
      final completer = Completer<List<ProductModel>>();
      when(
        () => remoteDataSource.getActiveProducts(),
      ).thenAnswer((_) => completer.future);

      final firstRequest = repository.getActiveProducts();
      final secondRequest = repository.getActiveProducts();

      completer.complete(_products);

      final firstResult = await firstRequest;
      final secondResult = await secondRequest;

      verify(() => remoteDataSource.getActiveProducts()).called(1);
      expect(firstResult.getOrElse(() => const []), _products);
      expect(secondResult.getOrElse(() => const []), _products);
    });

    test('cachea productos por taller de forma independiente', () async {
      when(
        () => remoteDataSource.getActiveProductsByWorkshop('workshop-1'),
      ).thenAnswer((_) async => _products);
      when(
        () => remoteDataSource.getActiveProductsByWorkshop('workshop-2'),
      ).thenAnswer((_) async => const <ProductModel>[]);

      await repository.getActiveProductsByWorkshop('workshop-1');
      await repository.getActiveProductsByWorkshop('workshop-1');
      await repository.getActiveProductsByWorkshop('workshop-2');

      verify(
        () => remoteDataSource.getActiveProductsByWorkshop('workshop-1'),
      ).called(1);
      verify(
        () => remoteDataSource.getActiveProductsByWorkshop('workshop-2'),
      ).called(1);
    });
  });
}

const _products = [
  ProductModel(
    id: 'product-1',
    workshopId: 'workshop-1',
    name: 'Filtro de aceite',
    description: 'Filtro demo',
    primaryImageUrl: '',
    sellingPrice: 6500,
    currentStock: 4,
    minimumStockAlert: 1,
    itemType: 'product',
    status: 'active',
    requiresAppointment: false,
    skuNumber: 'SKU-1',
    barcode: '123',
    categoryName: 'Repuestos',
    brandName: 'Demo',
    providerName: 'Proveedor',
    workshopName: 'Taller Central',
    workshopAvatarUrl: '',
  ),
];
