import 'package:autolab_customer/features/products/data/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductModel', () {
    test('parsea producto con relaciones del taller', () {
      final model = ProductModel.fromMap({
        'id': 'product-1',
        'workshop_id': 'workshop-1',
        'name': 'Aceite 10W-30',
        'description': 'Aceite sintetico para motor',
        'sku_number': 'ACE-10W30',
        'barcode': '744100000001',
        'item_type': 'product',
        'status': 'active',
        'is_schedulable': true,
        'requires_appointment': true,
        'estimated_duration_hours': '1.5',
        'current_stock': 12,
        'minimum_stock_alert': '3',
        'selling_price': '18500',
        'primary_image_url': 'https://example.com/oil.png',
        'product_categories': {'name': 'Lubricantes'},
        'product_brands': {'name': 'Motul'},
        'product_providers': {'name': 'Repuestos CR'},
        'workshops': {
          'name': 'Autolab Escazu',
          'avatar_url': 'https://example.com/avatar.png',
        },
      });

      expect(model.id, 'product-1');
      expect(model.workshopId, 'workshop-1');
      expect(model.name, 'Aceite 10W-30');
      expect(model.skuNumber, 'ACE-10W30');
      expect(model.barcode, '744100000001');
      expect(model.categoryName, 'Lubricantes');
      expect(model.brandName, 'Motul');
      expect(model.providerName, 'Repuestos CR');
      expect(model.workshopName, 'Autolab Escazu');
      expect(model.workshopAvatarUrl, 'https://example.com/avatar.png');
      expect(model.requiresAppointment, isTrue);
      expect(model.isSchedulable, isTrue);
      expect(model.estimatedDurationHours, 1.5);
      expect(model.currentStock, 12);
      expect(model.minimumStockAlert, 3);
      expect(model.sellingPrice, 18500);
    });
  });
}
