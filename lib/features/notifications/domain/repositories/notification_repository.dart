import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/customer_notification.dart';

abstract interface class NotificationRepository {
  Future<Either<Failure, List<CustomerNotification>>> loadNotifications();

  Stream<Either<Failure, List<CustomerNotification>>> watchNotifications();

  Future<Either<Failure, Unit>> markAsRead(String notificationId);
}
