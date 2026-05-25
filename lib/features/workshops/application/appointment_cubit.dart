import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../products/domain/entities/product.dart';
import '../../products/domain/usecases/get_additional_products_by_workshop.dart';
import '../../products/domain/usecases/get_schedulable_services_by_workshop.dart';
import '../data/datasources/appointment_booking_remote_data_source.dart';
import '../domain/repositories/workshop_repository.dart';
import 'appointment_state.dart';

class AppointmentCubit extends Cubit<AppointmentState> {
  AppointmentCubit({
    required WorkshopRepository workshopRepository,
    required GetSchedulableServicesByWorkshop getSchedulableServices,
    required GetAdditionalProductsByWorkshop getAdditionalProducts,
    required AppointmentBookingRemoteDataSource bookingRemoteDataSource,
  }) : _workshopRepository = workshopRepository,
       _getSchedulableServices = getSchedulableServices,
       _getAdditionalProducts = getAdditionalProducts,
       _bookingRemoteDataSource = bookingRemoteDataSource,
       super(const AppointmentState());

  final WorkshopRepository _workshopRepository;
  final GetSchedulableServicesByWorkshop _getSchedulableServices;
  final GetAdditionalProductsByWorkshop _getAdditionalProducts;
  final AppointmentBookingRemoteDataSource _bookingRemoteDataSource;
  static const _bookingTimes = [
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  Future<void> load(String workshopId) async {
    emit(
      state.copyWith(
        workshopId: workshopId,
        workshopStatus: AppointmentLoadStatus.loading,
        servicesStatus: AppointmentLoadStatus.loading,
        productsStatus: AppointmentLoadStatus.loading,
        vehiclesStatus: AppointmentLoadStatus.loading,
      ),
    );

    await Future.wait([
      _loadWorkshop(workshopId),
      _loadServices(workshopId),
      _loadProducts(workshopId),
      _loadVehicles(workshopId),
      _loadUnavailableDatesForMonth(workshopId, DateTime.now()),
    ]);
  }

  Future<void> _loadWorkshop(String workshopId) async {
    final result = await _workshopRepository.getWorkshopById(workshopId);

    result.fold(
      (_) =>
          emit(state.copyWith(workshopStatus: AppointmentLoadStatus.failure)),
      (workshop) => emit(
        state.copyWith(
          workshop: workshop,
          workshopStatus: AppointmentLoadStatus.success,
        ),
      ),
    );
  }

  Future<void> _loadServices(String workshopId) async {
    final result = await _getSchedulableServices.call(workshopId);

    result.fold(
      (_) =>
          emit(state.copyWith(servicesStatus: AppointmentLoadStatus.failure)),
      (services) => emit(
        state.copyWith(
          services: services,
          servicesStatus: AppointmentLoadStatus.success,
        ),
      ),
    );
  }

  Future<void> _loadProducts(String workshopId) async {
    final result = await _getAdditionalProducts.call(workshopId);

    result.fold(
      (_) =>
          emit(state.copyWith(productsStatus: AppointmentLoadStatus.failure)),
      (products) => emit(
        state.copyWith(
          products: products,
          productsStatus: AppointmentLoadStatus.success,
        ),
      ),
    );
  }

  Future<void> _loadVehicles(String workshopId) async {
    try {
      final vehicles = await _bookingRemoteDataSource.getCustomerVehicles(
        workshopId: workshopId,
      );

      emit(
        state.copyWith(
          vehicles: vehicles,
          vehiclesStatus: AppointmentLoadStatus.success,
        ),
      );
    } catch (_) {
      emit(state.copyWith(vehiclesStatus: AppointmentLoadStatus.failure));
    }
  }

  void goBack() {
    if (state.currentStep == 0) {
      return;
    }

    emit(state.copyWith(currentStep: state.currentStep - 1));
  }

  void goNext() {
    emit(state.copyWith(currentStep: state.currentStep + 1));
  }

  void updateVehicleLicensePlate(String licensePlate) {
    emit(state.copyWith(vehicleLicensePlate: licensePlate.toUpperCase()));
  }

  void updateVehicleType(String vehicleType) {
    emit(state.copyWith(vehicleType: vehicleType));
  }

  void updateVehicleBrand(String brand) {
    emit(state.copyWith(vehicleBrand: brand));
  }

  void updateVehicleModel(String model) {
    emit(state.copyWith(vehicleModel: model));
  }

  void updateVehicleYear(String year) {
    emit(state.copyWith(vehicleYear: year));
  }

  void updateVehicleColor(String color) {
    emit(state.copyWith(vehicleColor: color));
  }

  void updateVehicleFuelType(String? fuelType) {
    emit(state.copyWith(vehicleFuelType: fuelType));
  }

  void updateVehicleTransmissionType(String? transmissionType) {
    emit(state.copyWith(vehicleTransmissionType: transmissionType));
  }

  void selectExistingVehicle(AppointmentVehicleRecord vehicle) {
    emit(
      state.copyWith(
        selectedVehicleId: vehicle.id,
        vehicleLicensePlate: vehicle.licensePlate,
        vehicleType: vehicle.vehicleType ?? '',
        vehicleBrand: vehicle.brand ?? '',
        vehicleModel: vehicle.model ?? '',
        vehicleYear: vehicle.year?.toString() ?? '',
        vehicleColor: vehicle.color ?? '',
        vehicleFuelType: vehicle.fuelType,
        vehicleTransmissionType: vehicle.transmissionType,
      ),
    );
  }

  void startNewVehicle() {
    emit(
      state.copyWith(
        clearSelectedVehicleId: true,
        vehicleLicensePlate: '',
        vehicleType: '',
        vehicleBrand: '',
        vehicleModel: '',
        vehicleYear: '',
        vehicleColor: '',
        clearVehicleFuelType: true,
        clearVehicleTransmissionType: true,
      ),
    );
  }

  void selectService(Product service) {
    emit(
      state.copyWith(
        selectedService: service,
        includeProducts: false,
        selectedProducts: const [],
        clearSelectedDate: true,
        clearSelectedTime: true,
      ),
    );
  }

  void setIncludeProducts(bool value) {
    emit(
      state.copyWith(
        includeProducts: value,
        selectedProducts: value ? state.selectedProducts : const [],
      ),
    );
  }

  void toggleProduct(Product product) {
    final selectedProducts = [...state.selectedProducts];
    final existingIndex = selectedProducts.indexWhere(
      (selected) => selected.product.id == product.id,
    );

    if (existingIndex >= 0) {
      selectedProducts.removeAt(existingIndex);
    } else {
      selectedProducts.add(AppointmentSelectedProduct(product: product));
    }

    emit(state.copyWith(selectedProducts: selectedProducts));
  }

  void changeProductQuantity(Product product, int delta) {
    final selectedProducts = [...state.selectedProducts];
    final existingIndex = selectedProducts.indexWhere(
      (selected) => selected.product.id == product.id,
    );

    if (existingIndex < 0) {
      if (delta > 0) {
        selectedProducts.add(AppointmentSelectedProduct(product: product));
      }
      emit(state.copyWith(selectedProducts: selectedProducts));
      return;
    }

    final selected = selectedProducts[existingIndex];
    final nextQuantity = selected.quantity + delta;

    if (nextQuantity <= 0) {
      selectedProducts.removeAt(existingIndex);
    } else {
      selectedProducts[existingIndex] = selected.copyWith(
        quantity: nextQuantity,
      );
    }

    emit(state.copyWith(selectedProducts: selectedProducts));
  }

  void selectDate(DateTime date) {
    if (_isUnavailableDate(date)) {
      emit(
        state.copyWith(
          clearSelectedDate: true,
          clearSelectedTime: true,
          submitStatus: AppointmentSubmitStatus.failure,
          submitError: AppointmentSubmitError.dateUnavailable,
          submitErrorMessage: 'date_unavailable',
        ),
      );
      return;
    }

    final shouldClearDate = isSameDay(state.selectedDate, date);

    emit(
      state.copyWith(
        selectedDate: shouldClearDate ? null : date,
        clearSelectedDate: shouldClearDate,
        clearSelectedTime: true,
      ),
    );
  }

  void focusDate(DateTime date) {
    emit(state.copyWith(focusedDate: date));
    final workshopId = state.workshopId;
    if (workshopId.isNotEmpty) {
      _loadUnavailableDatesForMonth(workshopId, date);
    }
  }

  void selectTime(String time) {
    emit(state.copyWith(selectedTime: time));
  }

  void selectPaymentMethod(String method) {
    emit(state.copyWith(selectedPaymentMethod: method));
  }

  Future<bool> validateSelectedScheduleForBooking() async {
    final selectedService = state.selectedService;
    final selectedDate = state.selectedDate;
    final selectedTime = state.selectedTime;
    final workshopId = state.workshopId.isNotEmpty
        ? state.workshopId
        : selectedService?.workshopId ?? '';

    if (workshopId.isEmpty ||
        selectedService == null ||
        selectedDate == null ||
        selectedTime == null) {
      emit(
        state.copyWith(
          submitStatus: AppointmentSubmitStatus.failure,
          submitError: AppointmentSubmitError.scheduleRequired,
          submitErrorMessage: 'schedule_required',
        ),
      );
      return false;
    }

    try {
      final isAvailable = await _bookingRemoteDataSource
          .isAppointmentSlotAvailable(
            workshopId: workshopId,
            scheduledDateTime: _combineDateAndTime(selectedDate, selectedTime),
          );

      if (isAvailable) {
        emit(state.copyWith(clearSubmitErrorMessage: true));
        return true;
      }

      emit(
        state.copyWith(
          submitStatus: AppointmentSubmitStatus.failure,
          submitError: AppointmentSubmitError.slotUnavailable,
          submitErrorMessage: 'slot_unavailable',
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          submitStatus: AppointmentSubmitStatus.failure,
          submitError: AppointmentSubmitError.scheduleValidationFailed,
          submitErrorMessage: 'schedule_validation_failed',
        ),
      );
      return false;
    }
  }

  Future<bool> validateVehicleForBooking() async {
    if (state.selectedVehicleId != null) {
      return true;
    }

    if (state.vehicleLicensePlate.trim().isEmpty) {
      emit(
        state.copyWith(
          submitStatus: AppointmentSubmitStatus.failure,
          submitError: AppointmentSubmitError.vehiclePlateRequired,
          submitErrorMessage: 'vehicle_plate_required',
        ),
      );
      return false;
    }

    final workshopId = state.workshopId.isNotEmpty
        ? state.workshopId
        : state.selectedService?.workshopId ?? '';

    if (workshopId.isEmpty) {
      return true;
    }

    try {
      final vehicle = await _bookingRemoteDataSource.getCustomerVehicleByPlate(
        workshopId: workshopId,
        licensePlate: state.vehicleLicensePlate,
      );

      if (vehicle == null || _vehicleMatchesInput(vehicle)) {
        emit(state.copyWith(clearSubmitErrorMessage: true));
        return true;
      }

      emit(
        state.copyWith(
          submitStatus: AppointmentSubmitStatus.failure,
          submitError: AppointmentSubmitError.vehiclePlateConflict,
          submitErrorMessage: 'vehicle_plate_conflict',
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          submitStatus: AppointmentSubmitStatus.failure,
          submitError: AppointmentSubmitError.vehicleValidationFailed,
          submitErrorMessage: 'vehicle_validation_failed',
        ),
      );
      return false;
    }
  }

  Future<String?> submitBooking() async {
    final selectedService = state.selectedService;
    final selectedDate = state.selectedDate;
    final selectedTime = state.selectedTime;
    final workshopId = state.workshopId.isNotEmpty
        ? state.workshopId
        : selectedService?.workshopId ?? '';

    if (state.submitStatus == AppointmentSubmitStatus.submitting) {
      return null;
    }

    if (workshopId.isEmpty ||
        selectedService == null ||
        selectedDate == null ||
        selectedTime == null ||
        state.vehicleLicensePlate.trim().isEmpty) {
      emit(
        state.copyWith(
          submitStatus: AppointmentSubmitStatus.failure,
          submitError: AppointmentSubmitError.bookingIncomplete,
          submitErrorMessage: 'booking_incomplete',
          clearCreatedAppointmentId: true,
        ),
      );
      return null;
    }

    emit(
      state.copyWith(
        submitStatus: AppointmentSubmitStatus.submitting,
        clearSubmitError: true,
        clearCreatedAppointmentId: true,
        clearSubmitErrorMessage: true,
      ),
    );

    try {
      final appointmentId = await _bookingRemoteDataSource
          .bookServiceAppointment(
            workshopId: workshopId,
            inventoryItemId: selectedService.id,
            scheduledDateTime: _combineDateAndTime(selectedDate, selectedTime),
            note: _buildBookingNote(),
            vehicleId: state.selectedVehicleId,
            licensePlate: state.selectedVehicleId == null
                ? state.vehicleLicensePlate.trim().toUpperCase()
                : null,
            vehicleType: state.selectedVehicleId == null
                ? _trimOrNull(state.vehicleType)
                : null,
            vehicleBrand: state.selectedVehicleId == null
                ? _trimOrNull(state.vehicleBrand)
                : null,
            vehicleModel: state.selectedVehicleId == null
                ? _trimOrNull(state.vehicleModel)
                : null,
            vehicleYear: state.selectedVehicleId == null
                ? int.tryParse(state.vehicleYear.trim())
                : null,
            vehicleColor: state.selectedVehicleId == null
                ? _trimOrNull(state.vehicleColor)
                : null,
            fuelType: state.selectedVehicleId == null
                ? state.vehicleFuelType
                : null,
            transmissionType: state.selectedVehicleId == null
                ? state.vehicleTransmissionType
                : null,
          );

      emit(
        state.copyWith(
          submitStatus: AppointmentSubmitStatus.success,
          clearSubmitError: true,
          createdAppointmentId: appointmentId,
          clearSubmitErrorMessage: true,
        ),
      );
      return appointmentId;
    } catch (error) {
      emit(
        state.copyWith(
          submitStatus: AppointmentSubmitStatus.failure,
          submitError: _bookingErrorCode(error),
          submitErrorMessage: _bookingErrorMessage(error),
          clearCreatedAppointmentId: true,
        ),
      );
      return null;
    }
  }

  DateTime _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _loadUnavailableDatesForMonth(
    String workshopId,
    DateTime focusedDate,
  ) async {
    try {
      final startDate = DateTime(focusedDate.year, focusedDate.month);
      final endDate = DateTime(focusedDate.year, focusedDate.month + 1);
      final bookedSlots = await _bookingRemoteDataSource
          .getBookedAppointmentSlots(
            workshopId: workshopId,
            startDate: startDate,
            endDate: endDate,
          );
      final bookedByDate = <DateTime, Set<String>>{};

      for (final slot in bookedSlots) {
        final localSlot = slot.toLocal();
        final dateKey = DateTime(
          localSlot.year,
          localSlot.month,
          localSlot.day,
        );
        final timeKey =
            '${localSlot.hour.toString().padLeft(2, '0')}:${localSlot.minute.toString().padLeft(2, '0')}';

        if (_bookingTimes.contains(timeKey)) {
          bookedByDate.putIfAbsent(dateKey, () => <String>{}).add(timeKey);
        }
      }

      final unavailableDates = bookedByDate.entries
          .where((entry) => entry.value.length >= _bookingTimes.length)
          .map((entry) => entry.key)
          .toList();

      emit(
        state.copyWith(
          unavailableDates: unavailableDates,
          unavailableTimesByDate: bookedByDate,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          unavailableDates: const [],
          unavailableTimesByDate: const {},
        ),
      );
    }
  }

  bool _isUnavailableDate(DateTime date) {
    return state.unavailableDates.any((unavailableDate) {
      return isSameDay(unavailableDate, date);
    });
  }

  String _buildBookingNote() {
    final lines = <String>[
      'Placa: ${state.vehicleLicensePlate.trim().toUpperCase()}',
      if (state.vehicleType.trim().isNotEmpty)
        'Tipo: ${state.vehicleType.trim()}',
      if (state.vehicleBrand.trim().isNotEmpty)
        'Marca: ${state.vehicleBrand.trim()}',
      if (state.vehicleModel.trim().isNotEmpty)
        'Modelo: ${state.vehicleModel.trim()}',
      if (state.vehicleYear.trim().isNotEmpty) 'Anio: ${state.vehicleYear}',
      if (state.vehicleColor.trim().isNotEmpty)
        'Color: ${state.vehicleColor.trim()}',
      if (state.vehicleFuelType != null)
        'Combustible: ${state.vehicleFuelType}',
      if (state.vehicleTransmissionType != null)
        'Transmision: ${state.vehicleTransmissionType}',
      'Metodo de pago: ${state.selectedPaymentMethod}',
    ];

    if (state.includeProducts && state.selectedProducts.isNotEmpty) {
      final products = state.selectedProducts
          .map((selected) => '${selected.product.name} x${selected.quantity}')
          .join(', ');
      lines.add('Productos adicionales: $products');
    }

    return lines.join('\n');
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool _vehicleMatchesInput(AppointmentVehicleRecord vehicle) {
    return _textMatchesIfProvided(vehicle.vehicleType, state.vehicleType) &&
        _textMatchesIfProvided(vehicle.brand, state.vehicleBrand) &&
        _textMatchesIfProvided(vehicle.model, state.vehicleModel) &&
        _intMatchesIfProvided(vehicle.year, state.vehicleYear) &&
        _textMatchesIfProvided(vehicle.color, state.vehicleColor) &&
        _textMatchesIfProvided(vehicle.fuelType, state.vehicleFuelType) &&
        _textMatchesIfProvided(
          vehicle.transmissionType,
          state.vehicleTransmissionType,
        );
  }

  bool _textMatchesIfProvided(String? existingValue, String? inputValue) {
    final input = inputValue?.trim();
    if (input == null || input.isEmpty) {
      return true;
    }

    return (existingValue ?? '').trim().toLowerCase() == input.toLowerCase();
  }

  bool _intMatchesIfProvided(int? existingValue, String inputValue) {
    final input = int.tryParse(inputValue.trim());
    if (input == null) {
      return true;
    }

    return existingValue == input;
  }

  String _bookingErrorMessage(Object error) {
    return switch (_bookingErrorCode(error)) {
      AppointmentSubmitError.authRequired => 'auth_required',
      AppointmentSubmitError.dateTimeInPast => 'datetime_in_past',
      AppointmentSubmitError.customerNameRequired => 'customer_name_required',
      AppointmentSubmitError.customerPhoneRequired => 'customer_phone_required',
      AppointmentSubmitError.serviceNotSchedulable => 'service_not_schedulable',
      AppointmentSubmitError.slotUnavailable => 'slot_unavailable',
      AppointmentSubmitError.vehicleNotOwned => 'vehicle_not_owned',
      AppointmentSubmitError.vehiclePlateRequiredForBooking =>
        'vehicle_plate_required',
      AppointmentSubmitError.vehiclePlateConflict => 'vehicle_plate_conflict',
      _ => 'booking_failed',
    };
  }

  AppointmentSubmitError _bookingErrorCode(Object error) {
    final rawMessage = error is PostgrestException
        ? error.message
        : error.toString();

    if (rawMessage.contains('appointment_auth_required') ||
        rawMessage.contains('authenticated')) {
      return AppointmentSubmitError.authRequired;
    }

    if (rawMessage.contains('appointment_datetime_in_past')) {
      return AppointmentSubmitError.dateTimeInPast;
    }

    if (rawMessage.contains('appointment_customer_name_required')) {
      return AppointmentSubmitError.customerNameRequired;
    }

    if (rawMessage.contains('appointment_customer_phone_required')) {
      return AppointmentSubmitError.customerPhoneRequired;
    }

    if (rawMessage.contains('appointment_service_not_schedulable')) {
      return AppointmentSubmitError.serviceNotSchedulable;
    }

    if (rawMessage.contains('appointment_slot_unavailable')) {
      return AppointmentSubmitError.slotUnavailable;
    }

    if (rawMessage.contains('appointment_vehicle_not_owned_by_customer')) {
      return AppointmentSubmitError.vehicleNotOwned;
    }

    if (rawMessage.contains('appointment_vehicle_required')) {
      return AppointmentSubmitError.vehiclePlateRequiredForBooking;
    }

    if (rawMessage.contains('appointment_vehicle_plate_conflict')) {
      return AppointmentSubmitError.vehiclePlateConflict;
    }

    return AppointmentSubmitError.bookingFailed;
  }
}
