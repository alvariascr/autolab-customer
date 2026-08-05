class Product {
  const Product({
    required this.id,
    required this.workshopId,
    required this.name,
    required this.description,
    required this.primaryImageUrl,
    required this.sellingPrice,
    required this.currentStock,
    required this.minimumStockAlert,
    required this.itemType,
    required this.status,
    required this.requiresAppointment,
    this.isSchedulable = false,
    this.estimatedDurationHours,
    required this.skuNumber,
    required this.barcode,
    required this.categoryName,
    required this.brandName,
    required this.providerName,
    required this.workshopName,
    required this.workshopAvatarUrl,
    this.workshopDeliveryFee = 0,
  });

  final String id;
  final String workshopId;
  final String name;
  final String description;
  final String primaryImageUrl;
  final double? sellingPrice;
  final int? currentStock;
  final int? minimumStockAlert;
  final String itemType;
  final String status;
  final bool requiresAppointment;
  final bool isSchedulable;
  final double? estimatedDurationHours;
  final String skuNumber;
  final String barcode;
  final String categoryName;
  final String brandName;
  final String providerName;
  final String workshopName;
  final String workshopAvatarUrl;
  final double workshopDeliveryFee;

  String get effectiveDescription {
    final trimmed = description.trim();
    return trimmed.isNotEmpty ? trimmed : 'Producto disponible en este taller.';
  }
}
