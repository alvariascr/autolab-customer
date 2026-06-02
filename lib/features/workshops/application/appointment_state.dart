import 'package:equatable/equatable.dart';

import '../../products/domain/entities/product.dart';
import '../domain/entities/appointment_vehicle.dart';
import '../domain/entities/workshop.dart';

enum AppointmentLoadStatus { initial, loading, success, failure }

enum AppointmentSubmitStatus { initial, submitting, success, failure }

enum AppointmentSubmitError {
  dateUnavailable,
  scheduleRequired,
  slotUnavailable,
  scheduleValidationFailed,
  vehiclePlateRequired,
  vehiclePlateConflict,
  vehicleValidationFailed,
  bookingIncomplete,
  authRequired,
  dateTimeInPast,
  customerNameRequired,
  customerPhoneRequired,
  serviceNotSchedulable,
  vehicleNotOwned,
  vehiclePlateRequiredForBooking,
  bookingConfigurationFailed,
  bookingFailed,
}

class AppointmentState extends Equatable {
  const AppointmentState({
    this.workshopId = '',
    this.workshop,
    this.workshopStatus = AppointmentLoadStatus.initial,
    this.services = const [],
    this.servicesStatus = AppointmentLoadStatus.initial,
    this.products = const [],
    this.productsStatus = AppointmentLoadStatus.initial,
    this.vehicles = const [],
    this.vehiclesStatus = AppointmentLoadStatus.initial,
    this.unavailableDates = const [],
    this.unavailableTimesByDate = const {},
    this.availableTimesByDate = const {},
    this.availabilityStatus = AppointmentLoadStatus.initial,
    this.selectedVehicleId,
    this.currentStep = 0,
    this.vehicleLicensePlate = '',
    this.vehicleType = '',
    this.vehicleBrand = '',
    this.vehicleModel = '',
    this.vehicleYear = '',
    this.vehicleColor = '',
    this.vehicleFuelType,
    this.vehicleTransmissionType,
    this.selectedService,
    this.includeProducts = false,
    this.selectedProducts = const [],
    this.selectedDate,
    this.selectedTime,
    this.focusedDate,
    this.selectedPaymentMethod = 'Tarjeta',
    this.submitStatus = AppointmentSubmitStatus.initial,
    this.submitError,
    this.createdAppointmentId,
    this.submitErrorMessage,
  });

  final String workshopId;
  final Workshop? workshop;
  final AppointmentLoadStatus workshopStatus;
  final List<Product> services;
  final AppointmentLoadStatus servicesStatus;
  final List<Product> products;
  final AppointmentLoadStatus productsStatus;
  final List<AppointmentVehicleRecord> vehicles;
  final AppointmentLoadStatus vehiclesStatus;
  final List<DateTime> unavailableDates;
  final Map<DateTime, Set<String>> unavailableTimesByDate;
  final Map<DateTime, List<String>> availableTimesByDate;
  final AppointmentLoadStatus availabilityStatus;
  final String? selectedVehicleId;
  final int currentStep;
  final String vehicleLicensePlate;
  final String vehicleType;
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleYear;
  final String vehicleColor;
  final String? vehicleFuelType;
  final String? vehicleTransmissionType;
  final Product? selectedService;
  final bool includeProducts;
  final List<AppointmentSelectedProduct> selectedProducts;
  final DateTime? selectedDate;
  final String? selectedTime;
  final DateTime? focusedDate;
  final String selectedPaymentMethod;
  final AppointmentSubmitStatus submitStatus;
  final AppointmentSubmitError? submitError;
  final String? createdAppointmentId;
  final String? submitErrorMessage;

  AppointmentState copyWith({
    String? workshopId,
    Workshop? workshop,
    bool clearWorkshop = false,
    AppointmentLoadStatus? workshopStatus,
    List<Product>? services,
    AppointmentLoadStatus? servicesStatus,
    List<Product>? products,
    AppointmentLoadStatus? productsStatus,
    List<AppointmentVehicleRecord>? vehicles,
    AppointmentLoadStatus? vehiclesStatus,
    List<DateTime>? unavailableDates,
    Map<DateTime, Set<String>>? unavailableTimesByDate,
    Map<DateTime, List<String>>? availableTimesByDate,
    AppointmentLoadStatus? availabilityStatus,
    String? selectedVehicleId,
    bool clearSelectedVehicleId = false,
    int? currentStep,
    String? vehicleLicensePlate,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleYear,
    String? vehicleColor,
    String? vehicleFuelType,
    bool clearVehicleFuelType = false,
    String? vehicleTransmissionType,
    bool clearVehicleTransmissionType = false,
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
    AppointmentSubmitStatus? submitStatus,
    AppointmentSubmitError? submitError,
    bool clearSubmitError = false,
    String? createdAppointmentId,
    bool clearCreatedAppointmentId = false,
    String? submitErrorMessage,
    bool clearSubmitErrorMessage = false,
  }) {
    return AppointmentState(
      workshopId: workshopId ?? this.workshopId,
      workshop: clearWorkshop ? null : workshop ?? this.workshop,
      workshopStatus: workshopStatus ?? this.workshopStatus,
      services: services ?? this.services,
      servicesStatus: servicesStatus ?? this.servicesStatus,
      products: products ?? this.products,
      productsStatus: productsStatus ?? this.productsStatus,
      vehicles: vehicles ?? this.vehicles,
      vehiclesStatus: vehiclesStatus ?? this.vehiclesStatus,
      unavailableDates: unavailableDates ?? this.unavailableDates,
      unavailableTimesByDate:
          unavailableTimesByDate ?? this.unavailableTimesByDate,
      availableTimesByDate: availableTimesByDate ?? this.availableTimesByDate,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      selectedVehicleId: clearSelectedVehicleId
          ? null
          : selectedVehicleId ?? this.selectedVehicleId,
      currentStep: currentStep ?? this.currentStep,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleFuelType: clearVehicleFuelType
          ? null
          : vehicleFuelType ?? this.vehicleFuelType,
      vehicleTransmissionType: clearVehicleTransmissionType
          ? null
          : vehicleTransmissionType ?? this.vehicleTransmissionType,
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
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
      createdAppointmentId: clearCreatedAppointmentId
          ? null
          : createdAppointmentId ?? this.createdAppointmentId,
      submitErrorMessage: clearSubmitErrorMessage
          ? null
          : submitErrorMessage ?? this.submitErrorMessage,
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
    vehicles,
    vehiclesStatus,
    unavailableDates,
    unavailableTimesByDate,
    availableTimesByDate,
    availabilityStatus,
    selectedVehicleId,
    currentStep,
    vehicleLicensePlate,
    vehicleType,
    vehicleBrand,
    vehicleModel,
    vehicleYear,
    vehicleColor,
    vehicleFuelType,
    vehicleTransmissionType,
    selectedService,
    includeProducts,
    selectedProducts,
    selectedDate,
    selectedTime,
    focusedDate,
    selectedPaymentMethod,
    submitStatus,
    submitError,
    createdAppointmentId,
    submitErrorMessage,
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
