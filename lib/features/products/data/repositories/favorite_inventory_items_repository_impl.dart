import '../../domain/entities/product.dart';
import '../../domain/repositories/favorite_inventory_items_repository.dart';
import '../datasources/favorite_inventory_items_remote_data_source.dart';

class FavoriteInventoryItemsRepositoryImpl
    implements FavoriteInventoryItemsRepository {
  const FavoriteInventoryItemsRepositoryImpl(this._remoteDataSource);

  final FavoriteInventoryItemsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Product>> getFavoriteProducts() {
    return _remoteDataSource.getFavoriteProducts();
  }

  @override
  Future<List<Product>> getFavoriteServices() {
    return _remoteDataSource.getFavoriteServices();
  }

  @override
  Future<bool> isFavoriteInventoryItem(String itemId) {
    final trimmedItemId = itemId.trim();
    if (trimmedItemId.isEmpty) {
      return Future.value(false);
    }

    return _remoteDataSource.isFavoriteInventoryItem(trimmedItemId);
  }

  @override
  Future<bool> toggleFavoriteInventoryItem(
    String itemId, {
    required String itemType,
  }) {
    final trimmedItemId = itemId.trim();
    if (trimmedItemId.isEmpty) {
      return Future.value(false);
    }

    return _remoteDataSource.toggleFavoriteInventoryItem(
      trimmedItemId,
      itemType: itemType,
    );
  }

  @override
  Future<void> removeFavoriteInventoryItem(String itemId) {
    final trimmedItemId = itemId.trim();
    if (trimmedItemId.isEmpty) {
      return Future.value();
    }

    return _remoteDataSource.removeFavoriteInventoryItem(trimmedItemId);
  }
}
