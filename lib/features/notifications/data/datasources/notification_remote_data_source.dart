import '../models/customer_notification_model.dart';

abstract interface class NotificationRemoteDataSource {
  Future<List<CustomerNotificationModel>> loadNotifications({
    required String userId,
  });

  Stream<List<CustomerNotificationModel>> watchNotifications({
    required String userId,
  });

  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  });
}
