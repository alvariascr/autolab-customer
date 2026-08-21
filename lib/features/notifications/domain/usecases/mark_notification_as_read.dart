import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/notification_repository.dart';

class MarkNotificationAsRead {
  const MarkNotificationAsRead(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, Unit>> call(String notificationId) {
    return repository.markAsRead(notificationId);
  }
}
