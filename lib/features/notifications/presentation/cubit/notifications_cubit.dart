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
       super(NotificationsState());

  final GetCustomerNotifications _getCustomerNotifications;
  final MarkNotificationAsRead _markNotificationAsRead;
  final WatchCustomerNotifications _watchCustomerNotifications;
  StreamSubscription? _notificationsSubscription;
  int _watchGeneration = 0;
  String? _activeUserId;

  Future<void> load() async {
    if (state.status == NotificationsStatus.loading) return;
    emit(
      state.copyWith(status: NotificationsStatus.loading, clearMessage: true),
    );

    final result = await _getCustomerNotifications();
    if (isClosed) return;
    final wasSuccessful = result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: NotificationsStatus.failure,
            message: failure.message,
          ),
        );
        return false;
      },
      (items) {
        emit(
          state.copyWith(
            status: NotificationsStatus.success,
            notifications: items,
            clearMessage: true,
          ),
        );
        return true;
      },
    );

    if (wasSuccessful) {
      final userId = _activeUserId;
      if (userId != null) await startWatching(userId: userId);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = state.notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index < 0 || state.notifications[index].isRead) return;

    final originalNotification = state.notifications[index];
    final updated = [...state.notifications];
    updated[index] = updated[index].copyWith(isRead: true);
    emit(state.copyWith(notifications: updated, clearMessage: true));

    final result = await _markNotificationAsRead(notificationId);
    if (isClosed) return;
    result.fold((failure) {
      final rolledBack = state.notifications
          .map(
            (item) => item.id == notificationId ? originalNotification : item,
          )
          .toList(growable: false);
      emit(state.copyWith(notifications: rolledBack, message: failure.message));
    }, (_) {});
  }

  Future<void> startWatching({required String userId}) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    _activeUserId = normalizedUserId;

    final generation = ++_watchGeneration;
    final previousSubscription = _notificationsSubscription;
    _notificationsSubscription = null;
    await previousSubscription?.cancel();

    if (isClosed || generation != _watchGeneration) return;

    _notificationsSubscription =
        _watchCustomerNotifications(userId: normalizedUserId).listen((result) {
          if (generation != _watchGeneration) return;
          if (isClosed) return;
          result.fold(
            (failure) {
              if (state.notifications.isEmpty) {
                emit(
                  state.copyWith(
                    status: NotificationsStatus.failure,
                    message: failure.message,
                    isRealtimeConnected: false,
                  ),
                );
              } else {
                emit(
                  state.copyWith(
                    message: failure.message,
                    isRealtimeConnected: false,
                  ),
                );
              }
            },
            (items) => emit(
              state.copyWith(
                status: NotificationsStatus.success,
                notifications: items,
                clearMessage: true,
                isRealtimeConnected: true,
              ),
            ),
          );
        });
  }

  Future<void> stopWatching() async {
    _watchGeneration++;
    final subscription = _notificationsSubscription;
    _notificationsSubscription = null;
    await subscription?.cancel();
  }

  Future<void> clear() async {
    await stopWatching();
    _activeUserId = null;
    if (isClosed) return;
    emit(NotificationsState());
  }

  @override
  Future<void> close() async {
    await stopWatching();
    return super.close();
  }
}
