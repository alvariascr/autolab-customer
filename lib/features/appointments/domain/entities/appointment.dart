import 'package:equatable/equatable.dart';

class Appointment extends Equatable {
  const Appointment({
    required this.id,
    this.customerId,
    required this.workshopId,
    required this.serviceId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.vehicleType,
    this.vehiclePlate,
    required this.scheduledAt,
    required this.status,
    this.workshopName,
    this.serviceName,
    this.workshopAvatarUrl,
    this.paymentMethod,
    this.notes,
    this.totalAmount,
    this.createdAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    this.products = const [],
  });

  final String id;
  final String? customerId;
  final String workshopId;
  final String serviceId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String? vehicleType;
  final String? vehiclePlate;
  final DateTime scheduledAt;
  final String status;
  final String? workshopName;
  final String? serviceName;
  final String? workshopAvatarUrl;
  final String? paymentMethod;
  final String? notes;
  final double? totalAmount;
  final DateTime? createdAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final List<AppointmentProductLine> products;

  @override
  List<Object?> get props => [
    id,
    customerId,
    workshopId,
    serviceId,
    customerName,
    customerPhone,
    customerEmail,
    vehicleType,
    vehiclePlate,
    scheduledAt,
    status,
    workshopName,
    serviceName,
    workshopAvatarUrl,
    paymentMethod,
    notes,
    totalAmount,
    createdAt,
    cancelledAt,
    cancelledBy,
    cancellationReason,
    products,
  ];
}

class AppointmentProductLine extends Equatable {
  const AppointmentProductLine({
    required this.productId,
    required this.quantity,
    this.unitPrice,
  }) : assert(productId != '', 'productId must not be empty'),
       assert(quantity > 0, 'quantity must be greater than zero'),
       assert(
         unitPrice == null || unitPrice >= 0,
         'unitPrice must be positive',
       );

  final String productId;
  final int quantity;
  final double? unitPrice;

  @override
  List<Object?> get props => [productId, quantity, unitPrice];
}
