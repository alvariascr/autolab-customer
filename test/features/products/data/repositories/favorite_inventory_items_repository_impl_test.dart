import 'package:autolab_customer/features/products/data/datasources/favorite_inventory_items_remote_data_source.dart';
import 'package:autolab_customer/features/products/data/repositories/favorite_inventory_items_repository_impl.dart';
import 'package:autolab_customer/features/products/domain/repositories/favorite_inventory_items_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavoriteInventoryItemsRemoteDataSource extends Mock
    implements FavoriteInventoryItemsRemoteDataSource {}

void main() {
  late _MockFavoriteInventoryItemsRemoteDataSource remoteDataSource;
  late FavoriteInventoryItemsRepositoryImpl repository;

  setUp(() {
    remoteDataSource = _MockFavoriteInventoryItemsRemoteDataSource();
    repository = FavoriteInventoryItemsRepositoryImpl(remoteDataSource);
  });

  test('maps auth datasource exceptions to domain auth exceptions', () async {
    when(
      () => remoteDataSource.toggleFavoriteInventoryItem(
        'item-1',
        itemType: 'product',
      ),
    ).thenThrow(const FavoriteInventoryItemAuthRequiredException());

    await expectLater(
      repository.toggleFavoriteInventoryItem('item-1', itemType: 'product'),
      throwsA(isA<FavoriteInventoryItemsAuthException>()),
    );
  });

  test('maps storage datasource exceptions to domain storage exceptions', () {
    when(() => remoteDataSource.getFavoriteProducts()).thenThrow(
      FavoriteInventoryItemStorageException('network', StackTrace.current),
    );

    expect(
      repository.getFavoriteProducts(),
      throwsA(isA<FavoriteInventoryItemsStorageException>()),
    );
  });

  test('does not call datasource when item id is empty', () async {
    final result = await repository.toggleFavoriteInventoryItem(
      '   ',
      itemType: 'product',
    );

    expect(result, isFalse);
    verifyNever(
      () => remoteDataSource.toggleFavoriteInventoryItem(
        any(),
        itemType: any(named: 'itemType'),
      ),
    );
  });

  test('trims item id and item type before delegating', () async {
    when(
      () => remoteDataSource.toggleFavoriteInventoryItem(
        'item-1',
        itemType: 'service',
      ),
    ).thenAnswer((_) async => true);

    final result = await repository.toggleFavoriteInventoryItem(
      ' item-1 ',
      itemType: ' service ',
    );

    expect(result, isTrue);
    verify(
      () => remoteDataSource.toggleFavoriteInventoryItem(
        'item-1',
        itemType: 'service',
      ),
    ).called(1);
  });
}
