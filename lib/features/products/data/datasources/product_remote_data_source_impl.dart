import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';
import 'product_remote_data_source.dart';

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  ProductRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

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

  @override
  Future<List<ProductModel>> getActiveProducts() async {
    try {
      return await _getActiveProductsFilteredByStatus();
    } on PostgrestException catch (error) {
      if (!_isMissingStatusColumn(error)) {
        rethrow;
      }

      return _getActiveProductsFilteredByIsActive();
    }
  }

  @override
  Future<List<ProductModel>> getActiveProductsByWorkshop(
    String workshopId,
  ) async {
    try {
      return await _getProductsFilteredByStatus(workshopId);
    } on PostgrestException catch (error) {
      if (!_isMissingStatusColumn(error)) {
        rethrow;
      }

      return _getProductsFilteredByIsActive(workshopId);
    }
  }

  Future<List<ProductModel>> _getActiveProductsFilteredByStatus() async {
    final response = await client
        .from('inventory_items')
        .select(_productSelect)
        .eq('status', 'active')
        .order('name');

    return response.map((item) => ProductModel.fromMap(item)).toList();
  }

  Future<List<ProductModel>> _getActiveProductsFilteredByIsActive() async {
    final response = await client
        .from('inventory_items')
        .select(_productSelect)
        .eq('is_active', true)
        .order('name');

    return response.map((item) => ProductModel.fromMap(item)).toList();
  }

  Future<List<ProductModel>> _getProductsFilteredByStatus(
    String workshopId,
  ) async {
    final response = await client
        .from('inventory_items')
        .select(_productSelect)
        .eq('workshop_id', workshopId)
        .eq('status', 'active')
        .order('name');

    return response.map((item) => ProductModel.fromMap(item)).toList();
  }

  Future<List<ProductModel>> _getProductsFilteredByIsActive(
    String workshopId,
  ) async {
    final response = await client
        .from('inventory_items')
        .select(_productSelect)
        .eq('workshop_id', workshopId)
        .eq('is_active', true)
        .order('name');

    return response.map((item) => ProductModel.fromMap(item)).toList();
  }

  bool _isMissingStatusColumn(PostgrestException error) {
    return error.code == '42703' ||
        error.message.toLowerCase().contains('status');
  }
}
