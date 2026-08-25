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
      type: map['type']?.toString().trim() ?? 'message',
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
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
