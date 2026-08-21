import '../../domain/entities/customer_notification.dart';

class CustomerNotificationModel extends CustomerNotification {
  const CustomerNotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.isRead,
    required super.updatedAt,
    super.workshopId,
  });

  factory CustomerNotificationModel.fromMap(Map<String, dynamic> map) {
    final updatedAt = DateTime.tryParse(map['updated_at']?.toString() ?? '');

    return CustomerNotificationModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString().trim() ?? '',
      body: map['body']?.toString().trim() ?? '',
      type: map['type']?.toString().trim() ?? 'message',
      isRead: map['is_read'] == true,
      updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      workshopId: map['workshop_id']?.toString(),
    );
  }
}
