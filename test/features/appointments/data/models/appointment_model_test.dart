import 'package:autolab_customer/features/appointments/data/models/appointment_model.dart';
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
        'cancelled_at': '2026-05-27T13:00:00.000Z',
        'cancelled_by': 'user-1',
        'cancellation_reason': 'No podré asistir',
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
      expect(model.scheduledAt, DateTime(2026, 5, 28, 0, 15));
      expect(model.status, 'pending');
      expect(model.paymentMethod, 'sinpe');
      expect(model.notes, 'Llegar temprano');
      expect(model.totalAmount, 25000);
      expect(model.cancelledAt, DateTime(2026, 5, 27, 7));
      expect(model.cancelledBy, 'user-1');
      expect(model.cancellationReason, 'No podré asistir');
      expect(model.products, hasLength(1));
      expect(model.products.first.productId, 'product-1');
      expect(model.products.first.quantity, 2);
      expect(model.products.first.unitPrice, 5000);
    });

    test('parsea nombres de taller y servicio desde relaciones legacy', () {
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
        'inventory_items': {'name': 'Cambio de aceite'},
      });

      expect(model.workshopName, 'AutoFix San Jose');
      expect(model.workshopAvatarUrl, 'avatar.png');
      expect(model.serviceName, 'Cambio de aceite');
    });

    test('acepta auditoria de cancelacion ausente en citas existentes', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'customer_id': 'user-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'vehicle_type': 'AUTOMOVIL',
        'scheduled_at': '2026-05-28T06:15:00.000Z',
        'status': 'scheduled',
      });

      expect(model.cancelledAt, isNull);
      expect(model.cancelledBy, isNull);
      expect(model.cancellationReason, isNull);
    });

    test('acepta auditoria de cancelacion explicitamente nula', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'customer_id': 'user-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'vehicle_type': 'AUTOMOVIL',
        'scheduled_at': '2026-05-28T06:15:00.000Z',
        'status': 'scheduled',
        'cancelled_at': null,
        'cancelled_by': null,
        'cancellation_reason': null,
      });

      expect(model.cancelledAt, isNull);
      expect(model.cancelledBy, isNull);
      expect(model.cancellationReason, isNull);
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

    test('usa pending cuando status viene nulo', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'vehicle_type': 'AUTOMOVIL',
        'scheduled_at': '2026-05-28T06:15:00.000Z',
        'status': null,
      });

      expect(model.status, 'pending');
    });

    test(
      'parsea fecha desde scheduled_datetime cuando no viene scheduled_at',
      () {
        final model = AppointmentModel.fromMap({
          'id': 'appointment-1',
          'workshop_id': 'workshop-1',
          'service_id': 'service-1',
          'vehicle_type': 'AUTOMOVIL',
          'scheduled_datetime': '2026-05-28T06:15:00.000Z',
          'status': 'scheduled',
        });

        expect(model.scheduledAt, DateTime(2026, 5, 28, 0, 15));
      },
    );

    test('convierte scheduled_datetime UTC a hora civil de Costa Rica', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'vehicle_type': 'AUTOMOVIL',
        'scheduled_datetime': '2026-06-18T20:30:00.000Z',
        'status': 'scheduled',
      });

      expect(model.scheduledAt.year, 2026);
      expect(model.scheduledAt.month, 6);
      expect(model.scheduledAt.day, 18);
      expect(model.scheduledAt.hour, 14);
      expect(model.scheduledAt.minute, 30);
      expect(model.scheduledAt.isUtc, isFalse);
    });

    test('usa campos legacy cuando order_services viene nulo', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'vehicle_type': 'AUTOMOVIL',
        'scheduled_at': '2026-05-28T06:15:00.000Z',
        'status': 'scheduled',
        'order_services': null,
      });

      expect(model.workshopId, 'workshop-1');
      expect(model.serviceId, 'service-1');
      expect(model.vehicleType, 'AUTOMOVIL');
    });

    test('usa campos legacy cuando order_services viene vacio', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'vehicle_type': 'AUTOMOVIL',
        'scheduled_at': '2026-05-28T06:15:00.000Z',
        'status': 'scheduled',
        'order_services': const [],
      });

      expect(model.workshopId, 'workshop-1');
      expect(model.serviceId, 'service-1');
      expect(model.vehicleType, 'AUTOMOVIL');
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
        'vehicles': {'vehicle_type': 'AUTOMOVIL', 'license_plate': 'ABC123'},
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
      expect(model.vehiclePlate, 'ABC123');
      expect(model.status, 'scheduled');
      expect(model.scheduledAt, DateTime(2026, 5, 28, 0, 15));
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

    test('parsea relaciones del esquema actual cuando vienen como listas', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'order_service_id': 'order-service-1',
        'appointment_status': 'scheduled',
        'scheduled_datetime': '2026-05-28T06:15:00.000Z',
        'vehicles': [
          {'vehicle_type': 'AUTOMOVIL', 'license_plate': 'ABC123'},
        ],
        'order_services': [
          {
            'inventory_item_id': 'service-1',
            'inventory_items': [
              {'name': 'Cambio de aceite'},
            ],
            'orders': [
              {
                'workshop_id': 'workshop-1',
                'customers': [
                  {'user_id': 'user-1'},
                ],
                'workshops': [
                  {'name': 'AutoFix San Jose', 'avatar_url': 'avatar.png'},
                ],
              },
            ],
          },
        ],
      });

      expect(model.customerId, 'user-1');
      expect(model.workshopId, 'workshop-1');
      expect(model.serviceId, 'service-1');
      expect(model.vehicleType, 'AUTOMOVIL');
      expect(model.vehiclePlate, 'ABC123');
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

    test('permite cargar una cita sin tipo de vehiculo', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'scheduled_at': '2026-05-28T06:15:00.000Z',
        'status': 'pending',
      });

      expect(model.vehicleType, isNull);
    });

    test('serializa una cita con tipo de vehiculo presente', () {
      final model = AppointmentModel.fromMap({
        'id': 'appointment-1',
        'customer_id': 'user-1',
        'workshop_id': 'workshop-1',
        'service_id': 'service-1',
        'vehicle_type': 'AUTOMOVIL',
        'vehicle_plate': 'ABC123',
        'scheduled_at': '2026-05-28T06:15:00.000Z',
        'status': 'scheduled',
      });

      final map = model.toMap();

      expect(model.vehicleType, 'AUTOMOVIL');
      expect(map['id'], 'appointment-1');
      expect(map['customer_id'], 'user-1');
      expect(map['workshop_id'], 'workshop-1');
      expect(map['service_id'], 'service-1');
      expect(map['vehicle_type'], 'AUTOMOVIL');
      expect(map['vehicle_plate'], 'ABC123');
      expect(map['status'], 'scheduled');
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
