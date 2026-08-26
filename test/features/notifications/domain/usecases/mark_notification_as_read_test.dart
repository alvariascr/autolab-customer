import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/notifications/domain/entities/customer_notification.dart';
import 'package:autolab_customer/features/notifications/domain/repositories/notification_repository.dart';
import 'package:autolab_customer/features/notifications/domain/usecases/mark_notification_as_read.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeNotificationRepository repository;
  late MarkNotificationAsRead useCase;

  setUp(() {
    repository = _FakeNotificationRepository();
    useCase = MarkNotificationAsRead(repository);
  });

  test('rechaza identificadores vacíos sin llamar al repositorio', () async {
    final result = await useCase('   ');

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'INVALID_NOTIFICATION_ID',
    );
    expect(repository.markAsReadCalls, 0);
  });

  test('normaliza el identificador antes de llamar al repositorio', () async {
    final result = await useCase(' notification-1 ');

    expect(result.isRight(), isTrue);
    expect(repository.lastNotificationId, 'notification-1');
  });
}

class _FakeNotificationRepository implements NotificationRepository {
  int markAsReadCalls = 0;
  String? lastNotificationId;

  @override
  Future<Either<Failure, Unit>> markAsRead(String notificationId) async {
    markAsReadCalls++;
    lastNotificationId = notificationId;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<CustomerNotification>>> loadNotifications() {
    throw UnimplementedError();
  }

  @override
  Stream<Either<Failure, List<CustomerNotification>>> watchNotifications({
    required String userId,
  }) {
    throw UnimplementedError();
  }
}
