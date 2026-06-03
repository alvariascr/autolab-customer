import 'package:autolab_customer/features/workshops/data/models/workshop_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopModel', () {
    test('parsea datos extendidos del perfil del taller', () {
      final model = WorkshopModel.fromMap({
        'id': 'workshop-1',
        'name': 'Autolab Escazu',
        'description': 'Mantenimiento general',
        'location_address': 'Escazu Centro',
        'phone': '+506 2222-3333',
        'avatar_url': 'https://example.com/avatar.png',
        'cover_url': 'https://example.com/cover.png',
        'location_lat': '9.933',
        'location_lng': -84.08,
        'delivery_radius_km': 8,
        'offers_home_service': true,
        'business_hours': [
          {
            'day_of_week': 2,
            'open_time': '08:00:00',
            'close_time': '17:00:00',
            'is_closed': false,
            'slot_capacity': 3,
          },
          {
            'day_of_week': 1,
            'open_time': null,
            'close_time': null,
            'is_closed': true,
          },
        ],
        'workshop_service_categories': [
          {
            'workshop_categories': {'name': 'Frenos'},
          },
          {
            'workshop_categories': {'name': 'Mantenimiento'},
          },
        ],
        'workshop_payment_methods': [
          {
            'payment_methods': {'name': 'Tarjeta'},
          },
          {
            'payment_methods': {'name': 'Efectivo'},
          },
        ],
      });

      expect(model.id, 'workshop-1');
      expect(model.phone, '+506 2222-3333');
      expect(model.latitude, 9.933);
      expect(model.longitude, -84.08);
      expect(model.deliveryRadiusKm, 8);
      expect(model.offersHomeService, isTrue);
      expect(model.businessHours.map((hour) => hour.dayOfWeek), [1, 2]);
      expect(model.businessHours.first.isClosed, isTrue);
      expect(model.businessHours.first.slotCapacity, 1);
      expect(model.businessHours.last.slotCapacity, 3);
      expect(model.serviceCategories, ['Frenos', 'Mantenimiento']);
      expect(model.paymentMethods, ['Tarjeta', 'Efectivo']);
    });
  });
}
