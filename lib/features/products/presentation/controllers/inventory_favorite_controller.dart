import 'package:flutter/foundation.dart';

import '../../domain/repositories/favorite_inventory_items_repository.dart';

enum InventoryFavoriteFailure { authRequired, storage }

class InventoryFavoriteToggleResult {
  const InventoryFavoriteToggleResult.success(this.isFavorite) : failure = null;

  const InventoryFavoriteToggleResult.failure(this.failure, this.isFavorite);

  final bool isFavorite;
  final InventoryFavoriteFailure? failure;

  bool get isSuccess => failure == null;
}

class InventoryFavoriteController extends ChangeNotifier {
  InventoryFavoriteController(this._repository);

  final FavoriteInventoryItemsRepository _repository;

  bool _isDisposed = false;
  bool _isFavorite = false;
  bool _isLoading = false;

  bool get isFavorite => _isFavorite;
  bool get isLoading => _isLoading;

  Future<void> load(String itemId) async {
    try {
      _isFavorite = await _repository.isFavoriteInventoryItem(itemId);
    } catch (_) {
      _isFavorite = false;
    }

    _notifySafely();
  }

  Future<InventoryFavoriteToggleResult> toggle({
    required String itemId,
    required String itemType,
  }) async {
    if (_isLoading) {
      return InventoryFavoriteToggleResult.success(_isFavorite);
    }

    final previousValue = _isFavorite;
    _isFavorite = !previousValue;
    _isLoading = true;
    _notifySafely();

    try {
      final nextValue = await _repository.toggleFavoriteInventoryItem(
        itemId,
        itemType: itemType,
      );
      _isFavorite = nextValue;
      return InventoryFavoriteToggleResult.success(nextValue);
    } on FavoriteInventoryItemsAuthException {
      _isFavorite = previousValue;
      return InventoryFavoriteToggleResult.failure(
        InventoryFavoriteFailure.authRequired,
        previousValue,
      );
    } catch (_) {
      _isFavorite = previousValue;
      return InventoryFavoriteToggleResult.failure(
        InventoryFavoriteFailure.storage,
        previousValue,
      );
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
