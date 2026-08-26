import '../../domain/entities/customer_notification.dart';

class CustomerNotificationModel extends CustomerNotification {
  const CustomerNotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.isRead,
    required super.createdAt,
    super.workshopId,
  });

  factory CustomerNotificationModel.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.tryParse(map['created_at']?.toString() ?? '');

    return CustomerNotificationModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString().trim() ?? '',
      body: map['body']?.toString().trim() ?? '',
      type: _notificationTypeFromDatabase(map['type']),
      isRead: map['is_read'] == true,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      workshopId: map['workshop_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workshop_id': workshopId,
      'title': title,
      'body': body,
      'type': _notificationTypeToDatabase(type),
      'is_read': isRead,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  static NotificationType _notificationTypeFromDatabase(Object? value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'appointment' || 'cita' => NotificationType.appointment,
      'payment' || 'pago' => NotificationType.payment,
      'vehicle' || 'vehiculo' => NotificationType.vehicle,
      'message' || 'mensaje' => NotificationType.message,
      'promotion' || 'promocion' => NotificationType.promotion,
      _ => NotificationType.unknown,
    };
  }

  static String _notificationTypeToDatabase(NotificationType type) {
    return switch (type) {
      NotificationType.appointment => 'appointment',
      NotificationType.payment => 'payment',
      NotificationType.vehicle => 'vehicle',
      NotificationType.message => 'message',
      NotificationType.promotion => 'promotion',
      NotificationType.unknown => 'unknown',
    };
  }
}
