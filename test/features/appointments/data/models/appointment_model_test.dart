import 'package:autolab_customer/features/appointments/data/models/appointment_model.dart';
import 'package:autolab_customer/features/appointments/domain/entities/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentModel', () {
    test('parsea cita con productos asociados', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'customer_id': 'user-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'customer_name': 'Cliente Autolab',
        'customer_phone': '8888-8888',
        'customer_email': 'cliente@autolab.app',
        'vehicle_type': 'AUTOMOVIL',
        'scheduled_at': '2026-05-28T06:15:00.000Z',
        'status': 'pending',
        'payment_method': 'sinpe',
        'notes': 'Llegar temprano',
        'total_amount': '25000',
        'created_at': '2026-05-27T12:00:00.000Z',
        'appointment_products': [
          {'product_id': 'product-1', 'quantity': '2', 'unit_price': '5000'},
        ],
      });

      expect(model.id, 'appointment-1');
      expect(model.customerId, 'user-1');
      expect(model.workshopId, 'workshop-1');
      expect(model.serviceId, 'service-1');
      expect(model.customerName, 'Cliente Autolab');
      expect(model.customerPhone, '8888-8888');
      expect(model.customerEmail, 'cliente@autolab.app');
      expect(model.vehicleType, 'AUTOMOVIL');
      expect(model.scheduledAt, DateTime.parse('2026-05-28T06:15:00.000Z'));
      expect(model.status, 'pending');
      expect(model.paymentMethod, 'sinpe');
      expect(model.notes, 'Llegar temprano');
      expect(model.totalAmount, 25000);
      expect(model.products, hasLength(1));
      expect(model.products.first.productId, 'product-1');
      expect(model.products.first.quantity, 2);
      expect(model.products.first.unitPrice, 5000);
    });

    test('parsea nombres de taller y servicio desde relaciones', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'customer_id': 'user-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'customer_name': 'Cliente Autolab',
        'customer_phone': '8888-8888',
        'customer_email': 'cliente@autolab.app',
        'vehicle_type': 'AUTOMOVIL',
        'scheduled_at': '2026-05-28T06:15:00.000Z',
        'status': 'confirmed',
        'workshops': {'name': 'AutoFix San Jose', 'avatar_url': 'avatar.png'},
        'products': {'name': 'Cambio de aceite'},
      });

      expect(model.workshopName, 'AutoFix San Jose');
      expect(model.workshopAvatarUrl, 'avatar.png');
      expect(model.serviceName, 'Cambio de aceite');
    });

    test('convierte draft a parametros de RPC atomica', () {
      final draft = AppointmentDraft(
        workshopId: 'workshop-1',
        serviceId: 'service-1',
        customerName: 'Cliente Autolab',
        customerPhone: '8888-8888',
        customerEmail: 'cliente@autolab.app',
        vehicleType: 'AUTOMOVIL',
        scheduledAt: DateTime.utc(2026, 5, 28, 6, 15),
        paymentMethod: 'sinpe',
        totalAmount: 35000,
        products: const [
          AppointmentProductLine(
            productId: 'product-1',
            quantity: 2,
            unitPrice: 5000,
          ),
        ],
      );

      final params = AppointmentModel.toCreateRpcParams(draft);
      final products = params['p_products'] as List;
      final firstProduct = products.first as Map<String, dynamic>;

      expect(params['p_workshop_id'], 'workshop-1');
      expect(params['p_service_id'], 'service-1');
      expect(params['p_customer_name'], 'Cliente Autolab');
      expect(params['p_scheduled_at'], '2026-05-28T06:15:00.000Z');
      expect(params['p_payment_method'], 'sinpe');
      expect(params['p_total_amount'], 35000);
      expect(products, hasLength(1));
      expect(firstProduct['product_id'], 'product-1');
      expect(firstProduct['quantity'], 2);
      expect(firstProduct['unit_price'], 5000);
    });

    test('usa null cuando la cita no trae customer_id', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'customer_name': 'Cliente Autolab',
        'customer_phone': '8888-8888',
        'customer_email': 'cliente@autolab.app',
        'vehicle_type': 'AUTOMOVIL',
        'scheduled_at': '2026-05-28T06:15:00.000Z',
        'status': 'pending',
      });

      expect(model.customerId, isNull);
    });

    test('lanza FormatException cuando scheduled_at es invalido', () {
      expect(
        () => AppointmentModel.fromMap({
          'id': 'appointment-1',
          'workshop_id': 'workshop-1',
          'service_id': 'service-1',
          'customer_name': 'Cliente Autolab',
          'customer_phone': '8888-8888',
          'customer_email': 'cliente@autolab.app',
          'vehicle_type': 'AUTOMOVIL',
          'scheduled_at': 'fecha-invalida',
          'status': 'pending',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('parsea cita con el esquema actual de appointments', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'order_service_id': 'order-service-1',
        'appointment_status': 'scheduled',
        'scheduled_datetime': '2026-05-28T06:15:00.000Z',
        'note': 'Revisar frenos',
        'vehicle_id': 'vehicle-1',
        'vehicles': {'vehicle_type': 'AUTOMOVIL'},
        'order_services': {
          'inventory_item_id': 'service-1',
          'orders': {
            'workshop_id': 'workshop-1',
            'customers': {'user_id': 'user-1'},
          },
        },
      });

      expect(model.id, 'appointment-1');
      expect(model.customerId, 'user-1');
      expect(model.workshopId, 'workshop-1');
      expect(model.serviceId, 'service-1');
      expect(model.vehicleType, 'AUTOMOVIL');
      expect(model.status, 'scheduled');
      expect(model.scheduledAt, DateTime.parse('2026-05-28T06:15:00.000Z'));
      expect(model.notes, 'Revisar frenos');
    });

    test('parsea taller y servicio desde order_services', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'order_service_id': 'order-service-1',
        'appointment_status': 'scheduled',
        'scheduled_datetime': '2026-05-28T06:15:00.000Z',
        'vehicles': {'vehicle_type': 'AUTOMOVIL'},
        'order_services': {
          'inventory_item_id': 'service-1',
          'inventory_items': {'name': 'Cambio de aceite'},
          'orders': {
            'workshop_id': 'workshop-1',
            'customers': {'user_id': 'user-1'},
            'workshops': {
              'name': 'AutoFix San Jose',
              'avatar_url': 'avatar.png',
            },
          },
        },
      });

      expect(model.workshopName, 'AutoFix San Jose');
      expect(model.workshopAvatarUrl, 'avatar.png');
      expect(model.serviceName, 'Cambio de aceite');
    });

    test('lanza FormatException cuando falta fecha requerida', () {
      expect(
        () => AppointmentModel.fromMap({
          'id': 'appointment-1',
          'workshop_id': 'workshop-1',
          'service_id': 'service-1',
          'vehicle_type': 'AUTOMOVIL',
          'status': 'pending',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('lanza FormatException cuando falta taller requerido', () {
      expect(
        () => AppointmentModel.fromMap({
          'id': 'appointment-1',
          'service_id': 'service-1',
          'vehicle_type': 'AUTOMOVIL',
          'scheduled_at': '2026-05-28T06:15:00.000Z',
          'status': 'pending',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('lanza FormatException cuando falta servicio requerido', () {
      expect(
        () => AppointmentModel.fromMap({
          'id': 'appointment-1',
          'workshop_id': 'workshop-1',
          'vehicle_type': 'AUTOMOVIL',
          'scheduled_at': '2026-05-28T06:15:00.000Z',
          'status': 'pending',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('lanza FormatException cuando falta vehiculo requerido', () {
      expect(
        () => AppointmentModel.fromMap({
          'id': 'appointment-1',
          'workshop_id': 'workshop-1',
          'service_id': 'service-1',
          'scheduled_at': '2026-05-28T06:15:00.000Z',
          'status': 'pending',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('lanza FormatException cuando total_amount es malformado', () {
      expect(
        () => AppointmentModel.fromMap({
          'id': 'appointment-1',
          'workshop_id': 'workshop-1',
          'service_id': 'service-1',
          'customer_name': 'Cliente Autolab',
          'customer_phone': '8888-8888',
          'customer_email': 'cliente@autolab.app',
          'vehicle_type': 'AUTOMOVIL',
          'scheduled_at': '2026-05-28T06:15:00.000Z',
          'status': 'pending',
          'total_amount': 'monto-invalido',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('lanza FormatException cuando appointment_products no es lista', () {
      expect(
        () => AppointmentModel.fromMap({
          'id': 'appointment-1',
          'workshop_id': 'workshop-1',
          'service_id': 'service-1',
          'customer_name': 'Cliente Autolab',
          'customer_phone': '8888-8888',
          'customer_email': 'cliente@autolab.app',
          'vehicle_type': 'AUTOMOVIL',
          'scheduled_at': '2026-05-28T06:15:00.000Z',
          'status': 'pending',
          'appointment_products': 'producto-invalido',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('lanza FormatException cuando producto asociado es malformado', () {
      expect(
        () => AppointmentModel.fromMap({
          'id': 'appointment-1',
          'workshop_id': 'workshop-1',
          'service_id': 'service-1',
          'customer_name': 'Cliente Autolab',
          'customer_phone': '8888-8888',
          'customer_email': 'cliente@autolab.app',
          'vehicle_type': 'AUTOMOVIL',
          'scheduled_at': '2026-05-28T06:15:00.000Z',
          'status': 'pending',
          'appointment_products': [
            {'product_id': 'product-1', 'quantity': 0, 'unit_price': '5000'},
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
