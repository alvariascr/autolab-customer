import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../products/domain/entities/product.dart';
import '../../products/domain/usecases/get_additional_products_by_workshop.dart';
import '../../products/domain/usecases/get_schedulable_services_by_workshop.dart';
import '../domain/repositories/workshop_repository.dart';
import 'appointment_state.dart';

class AppointmentCubit extends Cubit<AppointmentState> {
  AppointmentCubit({
    required WorkshopRepository workshopRepository,
    required GetSchedulableServicesByWorkshop getSchedulableServices,
    required GetAdditionalProductsByWorkshop getAdditionalProducts,
  }) : _workshopRepository = workshopRepository,
       _getSchedulableServices = getSchedulableServices,
       _getAdditionalProducts = getAdditionalProducts,
       super(const AppointmentState());

  final WorkshopRepository _workshopRepository;
  final GetSchedulableServicesByWorkshop _getSchedulableServices;
  final GetAdditionalProductsByWorkshop _getAdditionalProducts;

  Future<void> load(String workshopId) async {
    emit(
      state.copyWith(
        workshopId: workshopId,
        workshopStatus: AppointmentLoadStatus.loading,
        servicesStatus: AppointmentLoadStatus.loading,
        productsStatus: AppointmentLoadStatus.loading,
      ),
    );

    await Future.wait([
      _loadWorkshop(workshopId),
      _loadServices(workshopId),
      _loadProducts(workshopId),
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

  void goBack() {
    if (state.currentStep == 0) {
      return;
    }

    emit(state.copyWith(currentStep: state.currentStep - 1));
  }

  void goNext() {
    emit(state.copyWith(currentStep: state.currentStep + 1));
  }

  void selectVehicle(String vehicle) {
    emit(state.copyWith(selectedVehicle: vehicle));
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
  }

  void selectTime(String time) {
    emit(state.copyWith(selectedTime: time));
  }

  void selectPaymentMethod(String method) {
    emit(state.copyWith(selectedPaymentMethod: method));
  }
}
