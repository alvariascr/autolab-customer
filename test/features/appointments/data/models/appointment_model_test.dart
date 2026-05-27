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

    test('convierte draft a payload de insercion', () {
      final draft = AppointmentDraft(
        workshopId: 'workshop-1',
        serviceId: 'service-1',
        customerName: 'Cliente Autolab',
        customerPhone: '8888-8888',
        customerEmail: 'cliente@autolab.app',
        vehicleType: 'AUTOMOVIL',
        scheduledAt: DateTime.utc(2026, 5, 28, 6, 15),
        paymentMethod: 'tarjeta',
        totalAmount: 30000,
        products: const [
          AppointmentProductLine(productId: 'product-1', quantity: 1),
        ],
      );

      final map = AppointmentModel.toInsertMap(draft);

      expect(map['workshop_id'], 'workshop-1');
      expect(map['service_id'], 'service-1');
      expect(map['customer_name'], 'Cliente Autolab');
      expect(map['scheduled_at'], '2026-05-28T06:15:00.000Z');
      expect(map['status'], 'pending');
      expect(map['payment_method'], 'tarjeta');
      expect(map['total_amount'], 30000);
      expect(map.containsKey('products'), isFalse);
      expect(map.containsKey('appointment_products'), isFalse);
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

    test('lanza FormatException cuando falta un campo requerido', () {
      expect(
        () => AppointmentModel.fromMap({
          'id': 'appointment-1',
          'service_id': 'service-1',
          'customer_name': 'Cliente Autolab',
          'customer_phone': '8888-8888',
          'customer_email': 'cliente@autolab.app',
          'vehicle_type': 'AUTOMOVIL',
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
