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
    required this.vehicleType,
    required this.scheduledAt,
    required this.status,
    this.workshopName,
    this.serviceName,
    this.workshopAvatarUrl,
    this.paymentMethod,
    this.notes,
    this.totalAmount,
    this.createdAt,
    this.products = const [],
  });

  final String id;
  final String? customerId;
  final String workshopId;
  final String serviceId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String vehicleType;
  final DateTime scheduledAt;
  final String status;
  final String? workshopName;
  final String? serviceName;
  final String? workshopAvatarUrl;
  final String? paymentMethod;
  final String? notes;
  final double? totalAmount;
  final DateTime? createdAt;
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
    scheduledAt,
    status,
    workshopName,
    serviceName,
    workshopAvatarUrl,
    paymentMethod,
    notes,
    totalAmount,
    createdAt,
    products,
  ];
}

class AppointmentDraft extends Equatable {
  const AppointmentDraft({
    required this.workshopId,
    required this.serviceId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.vehicleType,
    required this.scheduledAt,
    this.paymentMethod,
    this.notes,
    this.totalAmount,
    this.products = const [],
  });

  final String workshopId;
  final String serviceId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String vehicleType;
  final DateTime scheduledAt;
  final String? paymentMethod;
  final String? notes;
  final double? totalAmount;
  final List<AppointmentProductLine> products;

  @override
  List<Object?> get props => [
    workshopId,
    serviceId,
    customerName,
    customerPhone,
    customerEmail,
    vehicleType,
    scheduledAt,
    paymentMethod,
    notes,
    totalAmount,
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
