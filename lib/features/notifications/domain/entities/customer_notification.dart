import 'package:equatable/equatable.dart';

class CustomerNotification extends Equatable {
  const CustomerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.workshopId,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? workshopId;

  CustomerNotification copyWith({bool? isRead}) {
    return CustomerNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      workshopId: workshopId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    type,
    isRead,
    createdAt,
    workshopId,
  ];
}
