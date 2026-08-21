import 'package:equatable/equatable.dart';

import '../../domain/entities/customer_notification.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.message,
  });

  final NotificationsStatus status;
  final List<CustomerNotification> notifications;
  final String? message;

  bool get hasUnread =>
      notifications.any((notification) => !notification.isRead);

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<CustomerNotification>? notifications,
    String? message,
    bool clearMessage = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, notifications, message];
}
