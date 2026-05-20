import 'package:equatable/equatable.dart';

import '../../products/domain/entities/product.dart';
import '../domain/entities/workshop.dart';

enum AppointmentLoadStatus { initial, loading, success, failure }

class AppointmentState extends Equatable {
  const AppointmentState({
    this.workshopId = '',
    this.workshop,
    this.workshopStatus = AppointmentLoadStatus.initial,
    this.services = const [],
    this.servicesStatus = AppointmentLoadStatus.initial,
    this.products = const [],
    this.productsStatus = AppointmentLoadStatus.initial,
    this.currentStep = 0,
    this.selectedVehicle = 'AUTOMOVIL',
    this.selectedService,
    this.includeProducts = false,
    this.selectedProducts = const [],
    this.selectedDate,
    this.selectedTime,
    this.focusedDate,
    this.selectedPaymentMethod = 'Tarjeta',
  });

  final String workshopId;
  final Workshop? workshop;
  final AppointmentLoadStatus workshopStatus;
  final List<Product> services;
  final AppointmentLoadStatus servicesStatus;
  final List<Product> products;
  final AppointmentLoadStatus productsStatus;
  final int currentStep;
  final String? selectedVehicle;
  final Product? selectedService;
  final bool includeProducts;
  final List<AppointmentSelectedProduct> selectedProducts;
  final DateTime? selectedDate;
  final String? selectedTime;
  final DateTime? focusedDate;
  final String selectedPaymentMethod;

  AppointmentState copyWith({
    String? workshopId,
    Workshop? workshop,
    bool clearWorkshop = false,
    AppointmentLoadStatus? workshopStatus,
    List<Product>? services,
    AppointmentLoadStatus? servicesStatus,
    List<Product>? products,
    AppointmentLoadStatus? productsStatus,
    int? currentStep,
    String? selectedVehicle,
    Product? selectedService,
    bool clearSelectedService = false,
    bool? includeProducts,
    List<AppointmentSelectedProduct>? selectedProducts,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    String? selectedTime,
    bool clearSelectedTime = false,
    DateTime? focusedDate,
    String? selectedPaymentMethod,
  }) {
    return AppointmentState(
      workshopId: workshopId ?? this.workshopId,
      workshop: clearWorkshop ? null : workshop ?? this.workshop,
      workshopStatus: workshopStatus ?? this.workshopStatus,
      services: services ?? this.services,
      servicesStatus: servicesStatus ?? this.servicesStatus,
      products: products ?? this.products,
      productsStatus: productsStatus ?? this.productsStatus,
      currentStep: currentStep ?? this.currentStep,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      selectedService: clearSelectedService
          ? null
          : selectedService ?? this.selectedService,
      includeProducts: includeProducts ?? this.includeProducts,
      selectedProducts: selectedProducts ?? this.selectedProducts,
      selectedDate: clearSelectedDate
          ? null
          : selectedDate ?? this.selectedDate,
      selectedTime: clearSelectedTime
          ? null
          : selectedTime ?? this.selectedTime,
      focusedDate: focusedDate ?? this.focusedDate,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
    );
  }

  @override
  List<Object?> get props => [
    workshopId,
    workshop,
    workshopStatus,
    services,
    servicesStatus,
    products,
    productsStatus,
    currentStep,
    selectedVehicle,
    selectedService,
    includeProducts,
    selectedProducts,
    selectedDate,
    selectedTime,
    focusedDate,
    selectedPaymentMethod,
  ];
}

class AppointmentSelectedProduct extends Equatable {
  const AppointmentSelectedProduct({required this.product, this.quantity = 1});

  final Product product;
  final int quantity;

  AppointmentSelectedProduct copyWith({int? quantity}) {
    return AppointmentSelectedProduct(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}
