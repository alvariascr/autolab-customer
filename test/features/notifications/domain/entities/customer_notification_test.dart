import 'package:autolab_customer/features/notifications/domain/entities/customer_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith actualiza campos y permite limpiar workshopId', () {
    final notification = CustomerNotification(
      id: 'notification-1',
      title: 'Título original',
      body: 'Contenido original',
      type: 'message',
      isRead: false,
      createdAt: DateTime.utc(2026, 8, 25),
      workshopId: 'workshop-1',
    );

    final updated = notification.copyWith(
      title: 'Título actualizado',
      body: 'Contenido actualizado',
      type: 'appointment',
      isRead: true,
      createdAt: DateTime.utc(2026, 8, 26),
      clearWorkshopId: true,
    );

    expect(updated.id, notification.id);
    expect(updated.title, 'Título actualizado');
    expect(updated.body, 'Contenido actualizado');
    expect(updated.type, 'appointment');
    expect(updated.isRead, isTrue);
    expect(updated.createdAt, DateTime.utc(2026, 8, 26));
    expect(updated.workshopId, isNull);
  });
}
