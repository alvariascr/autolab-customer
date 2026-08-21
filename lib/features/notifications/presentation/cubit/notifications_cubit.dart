import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_customer_notifications.dart';
import '../../domain/usecases/mark_notification_as_read.dart';
import '../../domain/usecases/watch_customer_notifications.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required GetCustomerNotifications getCustomerNotifications,
    required MarkNotificationAsRead markNotificationAsRead,
    required WatchCustomerNotifications watchCustomerNotifications,
  }) : _getCustomerNotifications = getCustomerNotifications,
       _markNotificationAsRead = markNotificationAsRead,
       _watchCustomerNotifications = watchCustomerNotifications,
       super(const NotificationsState());

  final GetCustomerNotifications _getCustomerNotifications;
  final MarkNotificationAsRead _markNotificationAsRead;
  final WatchCustomerNotifications _watchCustomerNotifications;
  StreamSubscription? _notificationsSubscription;

  Future<void> load() async {
    if (state.status == NotificationsStatus.loading) return;
    emit(
      state.copyWith(status: NotificationsStatus.loading, clearMessage: true),
    );

    final result = await _getCustomerNotifications();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          message: failure.message,
        ),
      ),
      (items) => emit(
        state.copyWith(
          status: NotificationsStatus.success,
          notifications: items,
          clearMessage: true,
        ),
      ),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final index = state.notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index < 0 || state.notifications[index].isRead) return;

    final previous = state.notifications;
    final updated = [...previous];
    updated[index] = updated[index].copyWith(isRead: true);
    emit(state.copyWith(notifications: updated, clearMessage: true));

    final result = await _markNotificationAsRead(notificationId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(notifications: previous, message: failure.message),
      ),
      (_) {},
    );
  }

  Future<void> startWatching() async {
    await _notificationsSubscription?.cancel();
    _notificationsSubscription = _watchCustomerNotifications().listen((result) {
      if (isClosed) return;
      result.fold(
        (failure) {
          if (state.notifications.isEmpty) {
            emit(
              state.copyWith(
                status: NotificationsStatus.failure,
                message: failure.message,
              ),
            );
          }
        },
        (items) => emit(
          state.copyWith(
            status: NotificationsStatus.success,
            notifications: items,
            clearMessage: true,
          ),
        ),
      );
    });
  }

  Future<void> stopWatching() async {
    await _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
  }

  void clear() {
    unawaited(stopWatching());
    emit(const NotificationsState());
  }

  @override
  Future<void> close() async {
    await stopWatching();
    return super.close();
  }
}
