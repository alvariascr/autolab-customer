import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/domain/services/workshop_text_search_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopTextSearchFilter', () {
    const filter = WorkshopTextSearchFilter();
    const workshops = [
      Workshop(
        id: '1',
        name: 'Autolab Escazu',
        description: 'Mantenimiento general y revision',
        locationAddress: 'Escazu Centro',
        avatarUrl: '',
        coverUrl: '',
        latitude: 9.9330,
        longitude: -84.0800,
        deliveryRadiusKm: 8,
      ),
      Workshop(
        id: '2',
        name: 'Frenos Heredia',
        description: 'Especialistas en frenos y suspension',
        locationAddress: 'Heredia Centro',
        avatarUrl: '',
        coverUrl: '',
        latitude: 10.0024,
        longitude: -84.1165,
        deliveryRadiusKm: 12,
      ),
    ];

    test('retorna todos los talleres cuando la busqueda esta vacia', () {
      expect(
        filter.filter(workshops: workshops, query: '   '),
        hasLength(workshops.length),
      );
    });

    test('filtra por nombre sin importar mayusculas', () {
      final result = filter.filter(workshops: workshops, query: 'AUTO');

      expect(result, hasLength(1));
      expect(result.single.id, '1');
    });

    test('filtra por descripcion o direccion', () {
      final byDescription = filter.filter(
        workshops: workshops,
        query: 'suspension',
      );
      final byAddress = filter.filter(workshops: workshops, query: 'escazu');

      expect(byDescription.single.id, '2');
      expect(byAddress.single.id, '1');
    });

    test('retorna lista vacia cuando no hay coincidencias', () {
      expect(filter.filter(workshops: workshops, query: 'llantas'), isEmpty);
    });
  });
}
