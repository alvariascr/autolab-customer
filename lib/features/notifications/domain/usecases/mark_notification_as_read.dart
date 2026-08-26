import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/notification_repository.dart';

class MarkNotificationAsRead {
  const MarkNotificationAsRead(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, Unit>> call(String notificationId) {
    final normalizedId = notificationId.trim();
    if (normalizedId.isEmpty) {
      return Future.value(
        Left(
          Failure(
            'El identificador de la notificación es requerido.',
            code: 'INVALID_NOTIFICATION_ID',
          ),
        ),
      );
    }

    return repository.markAsRead(normalizedId);
  }
}
