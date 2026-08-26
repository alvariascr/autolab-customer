import 'package:autolab_customer/features/notifications/data/models/customer_notification_model.dart';
import 'package:autolab_customer/features/notifications/domain/entities/customer_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toMap conserva los campos usados por fromMap', () {
    final notification = CustomerNotificationModel(
      id: 'notification-1',
      workshopId: 'workshop-1',
      title: 'Cita confirmada',
      body: 'Tu cita fue confirmada.',
      type: NotificationType.appointment,
      isRead: false,
      createdAt: DateTime.utc(2026, 8, 25, 14, 30),
    );

    final restored = CustomerNotificationModel.fromMap(notification.toMap());

    expect(restored, notification);
  });

  test('fromMap usa unknown para tipos no soportados', () {
    final notification = CustomerNotificationModel.fromMap({
      'id': 'notification-2',
      'title': 'Nuevo evento',
      'body': 'Contenido',
      'type': 'future_event',
      'is_read': false,
      'created_at': '2026-08-25T14:30:00Z',
    });

    expect(notification.type, NotificationType.unknown);
  });
}
