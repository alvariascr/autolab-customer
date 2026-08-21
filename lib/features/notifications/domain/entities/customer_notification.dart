import 'package:equatable/equatable.dart';

class CustomerNotification extends Equatable {
  const CustomerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.updatedAt,
    this.workshopId,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime updatedAt;
  final String? workshopId;

  CustomerNotification copyWith({bool? isRead}) {
    return CustomerNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      updatedAt: updatedAt,
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
    updatedAt,
    workshopId,
  ];
}
