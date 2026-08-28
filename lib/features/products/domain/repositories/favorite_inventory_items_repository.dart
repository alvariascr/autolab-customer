import '../entities/product.dart';

abstract interface class FavoriteInventoryItemsRepository {
  Future<List<Product>> getFavoriteProducts();

  Future<List<Product>> getFavoriteServices();

  Future<bool> isFavoriteInventoryItem(String itemId);

  Future<bool> toggleFavoriteInventoryItem(
    String itemId, {
    required String itemType,
  });

  Future<void> removeFavoriteInventoryItem(String itemId);
}

class FavoriteInventoryItemsAuthException implements Exception {
  const FavoriteInventoryItemsAuthException();
}

class FavoriteInventoryItemsStorageException implements Exception {
  const FavoriteInventoryItemsStorageException(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
