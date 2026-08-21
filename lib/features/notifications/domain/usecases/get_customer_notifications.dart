import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/customer_notification.dart';
import '../repositories/notification_repository.dart';

class GetCustomerNotifications {
  const GetCustomerNotifications(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, List<CustomerNotification>>> call() {
    return repository.loadNotifications();
  }
}
