import 'package:equatable/equatable.dart';

import '../../domain/entities/customer_notification.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  NotificationsState({
    this.status = NotificationsStatus.initial,
    List<CustomerNotification> notifications = const [],
    this.message,
    this.isRealtimeConnected = true,
  }) : notifications = List.unmodifiable(notifications);

  final NotificationsStatus status;
  final List<CustomerNotification> notifications;
  final String? message;
  final bool isRealtimeConnected;

  bool get hasUnread =>
      notifications.any((notification) => !notification.isRead);

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<CustomerNotification>? notifications,
    String? message,
    bool? isRealtimeConnected,
    bool clearMessage = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      message: clearMessage ? null : message ?? this.message,
      isRealtimeConnected: isRealtimeConnected ?? this.isRealtimeConnected,
    );
  }

  @override
  List<Object?> get props => [
    status,
    notifications,
    message,
    isRealtimeConnected,
  ];
}
