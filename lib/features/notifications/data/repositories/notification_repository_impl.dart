import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/customer_notification.dart';
import '../../domain/exceptions/notification_unauthenticated_exception.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.currentUserIdProvider,
  });

  final NotificationRemoteDataSource remoteDataSource;
  final String? Function() currentUserIdProvider;

  @override
  Future<Either<Failure, List<CustomerNotification>>>
  loadNotifications() async {
    try {
      final userId = _currentUserId();
      final notifications = await remoteDataSource.loadNotifications(
        userId: userId,
      );
      return Right(notifications);
    } on NotificationUnauthenticatedException catch (error, stackTrace) {
      return Left(_unauthenticatedFailure(error, stackTrace));
    } catch (error, stackTrace) {
      return Left(
        Failure(
          'No fue posible cargar las notificaciones.',
          code: 'NOTIFICATIONS_LOAD_FAILED',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Stream<Either<Failure, List<CustomerNotification>>> watchNotifications({
    required String userId,
  }) {
    try {
      final normalizedUserId = userId.trim();
      if (normalizedUserId.isEmpty) {
        throw const NotificationUnauthenticatedException();
      }

      return remoteDataSource
          .watchNotifications(userId: normalizedUserId)
          .map<Either<Failure, List<CustomerNotification>>>(Right.new)
          .transform(
            StreamTransformer.fromHandlers(
              handleError: (error, stackTrace, sink) {
                sink.add(Left(_watchFailure(error, stackTrace)));
              },
            ),
          );
    } on NotificationUnauthenticatedException catch (error, stackTrace) {
      return Stream.value(Left(_unauthenticatedFailure(error, stackTrace)));
    } catch (error, stackTrace) {
      return Stream.value(Left(_watchFailure(error, stackTrace)));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(String notificationId) async {
    try {
      _currentUserId();
      await remoteDataSource.markAsRead(notificationId: notificationId);
      return const Right(unit);
    } on NotificationUnauthenticatedException catch (error, stackTrace) {
      return Left(_unauthenticatedFailure(error, stackTrace));
    } catch (error, stackTrace) {
      return Left(
        Failure(
          'No fue posible actualizar la notificación.',
          code: 'NOTIFICATION_UPDATE_FAILED',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  String _currentUserId() {
    final userId = currentUserIdProvider()?.trim();
    if (userId == null || userId.isEmpty) {
      throw const NotificationUnauthenticatedException();
    }
    return userId;
  }

  Failure _unauthenticatedFailure(Object error, StackTrace stackTrace) {
    return Failure(
      'Debes iniciar sesión para consultar tus notificaciones.',
      code: 'NOTIFICATIONS_UNAUTHENTICATED',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  Failure _watchFailure(Object error, StackTrace stackTrace) {
    return Failure(
      'No fue posible actualizar las notificaciones.',
      code: 'NOTIFICATIONS_WATCH_FAILED',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
