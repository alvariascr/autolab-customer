import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.workshopId,
    required super.name,
    required super.description,
    required super.primaryImageUrl,
    required super.sellingPrice,
    required super.currentStock,
    required super.minimumStockAlert,
    required super.itemType,
    required super.status,
    required super.requiresAppointment,
    super.isSchedulable,
    super.estimatedDurationHours,
    required super.skuNumber,
    required super.barcode,
    required super.categoryName,
    required super.brandName,
    required super.providerName,
    required super.workshopName,
    required super.workshopAvatarUrl,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id']?.toString() ?? '',
      workshopId: map['workshop_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      primaryImageUrl: map['primary_image_url']?.toString() ?? '',
      sellingPrice: _nullableDouble(map['selling_price']),
      currentStock: _nullableInt(map['current_stock']),
      minimumStockAlert: _nullableInt(map['minimum_stock_alert']),
      itemType: map['item_type']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      requiresAppointment: map['requires_appointment'] == true,
      isSchedulable: map['is_schedulable'] == true,
      estimatedDurationHours: _nullableDouble(map['estimated_duration_hours']),
      skuNumber: map['sku_number']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      categoryName: _relationName(map['product_categories']),
      brandName: _relationName(map['product_brands']),
      providerName: _relationName(map['product_providers']),
      workshopName: _relationName(map['workshops']),
      workshopAvatarUrl: _relationValue(map['workshops'], 'avatar_url'),
    );
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static String _relationName(dynamic relation) {
    return _relationValue(relation, 'name');
  }

  static String _relationValue(dynamic relation, String key) {
    if (relation is Map<String, dynamic>) {
      return relation[key]?.toString() ?? '';
    }

    if (relation is List && relation.isNotEmpty) {
      final first = relation.first;
      if (first is Map<String, dynamic>) {
        return first[key]?.toString() ?? '';
      }
    }

    return '';
  }
}
