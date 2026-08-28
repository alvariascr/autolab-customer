import '../../domain/entities/product.dart';
import '../../domain/repositories/favorite_inventory_items_repository.dart';
import '../datasources/favorite_inventory_items_remote_data_source.dart';

class FavoriteInventoryItemsRepositoryImpl
    implements FavoriteInventoryItemsRepository {
  const FavoriteInventoryItemsRepositoryImpl(this._remoteDataSource);

  final FavoriteInventoryItemsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Product>> getFavoriteProducts() {
    return _mapDataSourceException(_remoteDataSource.getFavoriteProducts);
  }

  @override
  Future<List<Product>> getFavoriteServices() {
    return _mapDataSourceException(_remoteDataSource.getFavoriteServices);
  }

  @override
  Future<bool> isFavoriteInventoryItem(String itemId) async {
    final trimmedItemId = itemId.trim();
    if (trimmedItemId.isEmpty) {
      return false;
    }

    return _mapDataSourceException(
      () => _remoteDataSource.isFavoriteInventoryItem(trimmedItemId),
    );
  }

  @override
  Future<bool> toggleFavoriteInventoryItem(
    String itemId, {
    required String itemType,
  }) async {
    final trimmedItemId = itemId.trim();
    final trimmedItemType = itemType.trim();
    if (trimmedItemId.isEmpty) {
      return false;
    }

    return _mapDataSourceException(
      () => _remoteDataSource.toggleFavoriteInventoryItem(
        trimmedItemId,
        itemType: trimmedItemType,
      ),
    );
  }

  @override
  Future<void> removeFavoriteInventoryItem(String itemId) async {
    final trimmedItemId = itemId.trim();
    if (trimmedItemId.isEmpty) {
      return;
    }

    return _mapDataSourceException(
      () => _remoteDataSource.removeFavoriteInventoryItem(trimmedItemId),
    );
  }

  Future<T> _mapDataSourceException<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FavoriteInventoryItemAuthRequiredException {
      throw const FavoriteInventoryItemsAuthException();
    } on FavoriteInventoryItemStorageException catch (error) {
      throw FavoriteInventoryItemsStorageException(
        error.error,
        error.stackTrace,
      );
    }
  }
}
