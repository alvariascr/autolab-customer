import 'package:supabase_flutter/supabase_flutter.dart';

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
    final userId = _requireUserId();
    final response = await _client
        .from('customer_favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('inventory_item_id', itemId)
        .maybeSingle();

    return response != null;
  }

  Future<bool> toggleFavoriteInventoryItem(
    String itemId, {
    required String itemType,
  }) async {
    _requireUserId();
    final response = await _client.rpc<bool>(
      'toggle_customer_favorite_inventory_item',
      params: {
        'p_inventory_item_id': itemId,
        'p_favorite_type': _favoriteTypeFor(itemType),
      },
    );

    return response;
  }

  Future<void> removeFavoriteInventoryItem(String itemId) async {
    final userId = _requireUserId();
    await _client
        .from('customer_favorites')
        .delete()
        .eq('user_id', userId)
        .eq('inventory_item_id', itemId);
  }

  Future<List<ProductModel>> _getFavoriteItemsByType(String itemType) async {
    final userId = _requireUserId();
    final response = await _client
        .from('customer_favorites')
        .select('inventory_items!inner($_productSelect)')
        .eq('user_id', userId)
        .eq('favorite_type', itemType)
        .eq('inventory_items.status', 'active')
        .order('created_at', ascending: false);

    return response
        .whereType<Map<String, dynamic>>()
        .map((row) => row['inventory_items'])
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromMap)
        .toList(growable: false);
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
