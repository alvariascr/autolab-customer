import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/customer_notification.dart';
import '../repositories/notification_repository.dart';

class WatchCustomerNotifications {
  const WatchCustomerNotifications(this.repository);

  final NotificationRepository repository;

  Stream<Either<Failure, List<CustomerNotification>>> call({
    required String userId,
  }) {
    return repository.watchNotifications(userId: userId);
  }
}
