import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/supabase_error_matchers.dart';
import '../models/product_model.dart';

class FavoriteInventoryItemsRemoteDataSource {
  const FavoriteInventoryItemsRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _productSelect = '''
    id,
    workshop_id,
    name,
    description,
    sku_number,
    barcode,
    item_type,
    status,
    is_schedulable,
    requires_appointment,
    estimated_duration_hours,
    current_stock,
    minimum_stock_alert,
    selling_price,
    primary_image_url,
    product_categories(name),
    product_brands(name),
    product_providers(name),
    workshops(name, avatar_url, delivery_fee)
  ''';

  Future<List<ProductModel>> getFavoriteProducts() {
    return _getFavoriteItemsByType('product');
  }

  Future<List<ProductModel>> getFavoriteServices() {
    return _getFavoriteItemsByType('service');
  }

  Future<bool> isFavoriteInventoryItem(String itemId) async {
    return _wrapStorageErrors(() async {
      final userId = _requireUserId();
      final response = await _client
          .from('customer_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('inventory_item_id', itemId)
          .maybeSingle();

      return response != null;
    });
  }

  Future<bool> toggleFavoriteInventoryItem(
    String itemId, {
    required String itemType,
  }) async {
    return _wrapStorageErrors(() async {
      _requireUserId();
      return _client.rpc<bool>(
        'toggle_customer_favorite_inventory_item',
        params: {
          'p_inventory_item_id': itemId,
          'p_favorite_type': _favoriteTypeFor(itemType),
        },
      );
    });
  }

  Future<void> removeFavoriteInventoryItem(String itemId) async {
    return _wrapStorageErrors(() async {
      final userId = _requireUserId();
      await _client
          .from('customer_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('inventory_item_id', itemId);
    });
  }

  Future<List<ProductModel>> _getFavoriteItemsByType(String itemType) async {
    return _wrapStorageErrors(() async {
      final userId = _requireUserId();
      final response = await _client
          .from('customer_favorites')
          .select('inventory_items!inner($_productSelect)')
          .eq('user_id', userId)
          .eq('favorite_type', itemType)
          .order('created_at', ascending: false);

      return response
          .whereType<Map<String, dynamic>>()
          .map((row) => row['inventory_items'])
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromMap)
          .toList(growable: false);
    });
  }

  Future<T> _wrapStorageErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FavoriteInventoryItemAuthRequiredException {
      rethrow;
    } on AuthException catch (_) {
      // Explicit failures from the Supabase Auth SDK itself (e.g. a
      // stale JWT that failed to refresh before the request went out).
      throw const FavoriteInventoryItemAuthRequiredException();
    } on PostgrestException catch (error, stackTrace) {
      if (isAuthRequiredError(error)) {
        throw const FavoriteInventoryItemAuthRequiredException();
      }
      throw FavoriteInventoryItemStorageException(error, stackTrace);
    } on SocketException catch (error, stackTrace) {
      throw FavoriteInventoryItemStorageException(error, stackTrace);
    } catch (error, stackTrace) {
      // Fallback so no unexpected error (JSON parsing, TypeError, etc.)
      // ever leaks past the datasource boundary unwrapped.
      throw FavoriteInventoryItemStorageException(error, stackTrace);
    }
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id.trim() ?? '';
    if (userId.isEmpty) {
      throw const FavoriteInventoryItemAuthRequiredException();
    }

    return userId;
  }

  String _favoriteTypeFor(String itemType) {
    return itemType.trim().toLowerCase() == 'service' ? 'service' : 'product';
  }
}

class FavoriteInventoryItemAuthRequiredException implements Exception {
  const FavoriteInventoryItemAuthRequiredException();
}

class FavoriteInventoryItemStorageException implements Exception {
  const FavoriteInventoryItemStorageException(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
