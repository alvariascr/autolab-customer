import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../payments/application/laropay_checkout_launcher.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/widgets/product_price_text.dart';
import '../../application/appointment_cubit.dart';
import '../../application/appointment_state.dart';
import '../../domain/entities/appointment_vehicle.dart';

class WorkshopAppointmentPage extends StatefulWidget {
  const WorkshopAppointmentPage({
    super.key,
    required this.workshopId,
    required this.initialServiceId,
    this.initialSelection,
  });

  final String workshopId;
  final String initialServiceId;
  final WorkshopAppointmentInitialSelection? initialSelection;

  @override
  State<WorkshopAppointmentPage> createState() =>
      _WorkshopAppointmentPageState();
}

class _WorkshopAppointmentPageState extends State<WorkshopAppointmentPage> {
  static const ink = AutolabCustomer.secondary;
  static const muted = AutolabCustomer.gray;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppointmentCubit>()
        ..load(
          widget.workshopId,
          initialServiceId: widget.initialServiceId,
          initialService: widget.initialSelection?.service,
          initialProducts: widget.initialSelection?.products,
        ),
      child: BlocBuilder<AppointmentCubit, AppointmentState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          final steps = _appointmentSteps(l10n);
          final isDesktop = MediaQuery.sizeOf(context).width >= 900;

          return Scaffold(
            backgroundColor: AutolabCustomer.customerBackgroundColor(context),
            body: SafeArea(
              child: isDesktop
                  ? Row(
                      children: [
                        SizedBox(
                          width: 430,
                          child: _DesktopRail(
                            steps: steps,
                            currentStep: state.currentStep,
                            workshopName: _workshopName(state),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: _pageBody(
                            context: context,
                            state: state,
                            steps: steps,
                            isDesktop: true,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: _pageBody(
                            context: context,
                            state: state,
                            steps: steps,
                            isDesktop: false,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _pageBody({
    required BuildContext context,
    required AppointmentState state,
    required List<_AppointmentStep> steps,
    required bool isDesktop,
  }) {
    final isSubmitting =
        state.submitStatus == AppointmentSubmitStatus.submitting;
    final isBusy = isSubmitting;
    final horizontalPadding = isDesktop
        ? AutolabCustomer.responsiveDouble(
            context,
            compact: 56,
            regular: 72,
            tablet: 92,
          )
        : AutolabCustomer.responsiveScreenMargin(context);
    final topPadding = isDesktop
        ? AutolabCustomer.responsiveDouble(
            context,
            compact: 56,
            regular: 72,
            tablet: 96,
          )
        : AutolabCustomer.responsiveDouble(
            context,
            compact: AutolabCustomer.spacingSmd,
            regular: AutolabCustomer.spacingLg,
            tablet: AutolabCustomer.spacingXl,
          );

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1224),
                    child: _buildStepContent(
                      context: context,
                      state: state,
                      steps: steps,
                      isDesktop: isDesktop,
                    ),
                  ),
                ),
              ),
            ),
            _FooterActions(
              canGoBack: state.currentStep > 0,
              isLastStep: state.currentStep == steps.length - 1,
              isSubmitting: isBusy,
              onBack: () => _handleBack(context, state),
              onNext: () => _goNextStep(context, state, steps.length),
            ),
          ],
        ),
        if (isBusy) const _BookingSubmittingOverlay(),
      ],
    );
  }

  Widget _buildStepContent({
    required BuildContext context,
    required AppointmentState state,
    required List<_AppointmentStep> steps,
    required bool isDesktop,
  }) {
    switch (state.currentStep) {
      case 0:
        return _DateTimeMock(
          title: steps[state.currentStep].title,
          selectedDate: state.selectedDate,
          selectedTime: state.selectedTime,
          focusedDate: state.focusedDate ?? DateTime.now(),
          unavailableDates: state.unavailableDates,
          unavailableTimesByDate: state.unavailableTimesByDate,
          availableTimesByDate: state.availableTimesByDate,
          availabilityStatus: state.availabilityStatus,
          onDaySelected: context.read<AppointmentCubit>().selectDate,
          onFocusedDateChanged: context.read<AppointmentCubit>().focusDate,
          onSelected: context.read<AppointmentCubit>().selectTime,
        );
      case 1:
        return _BookingReviewStep(
          title: steps[state.currentStep].title,
          workshopName: _workshopName(state),
          service: state.selectedService,
          licensePlate: state.vehicleLicensePlate,
          products: state.selectedProducts,
          date: state.selectedDate,
          time: state.selectedTime ?? '9:00 AM',
          onNoteChanged: context.read<AppointmentCubit>().updateCustomerNote,
          note: state.customerNote,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _workshopName(AppointmentState state) {
    final name = state.workshop?.name.trim();
    return name == null || name.isEmpty ? 'Taller Autolab' : name;
  }

  void _handleBack(BuildContext context, AppointmentState state) {
    if (state.currentStep == 0) {
      _closeAppointmentFlow(context);
      return;
    }

    context.read<AppointmentCubit>().goBack();
  }

  void _closeAppointmentFlow(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    _goToWorkshopProfileOrHome(context);
  }

  void _goToWorkshopProfileOrHome(BuildContext context) {
    final workshopId = widget.workshopId.trim();
    context.go(
      workshopId.isEmpty ? '/home-customer' : '/workshops/$workshopId',
    );
  }

  Future<void> _goNextStep(
    BuildContext context,
    AppointmentState state,
    int stepCount,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (state.currentStep == stepCount - 1) {
      final cubit = context.read<AppointmentCubit>();
      final appointmentId = await cubit.submitBooking();

      if (!context.mounted) {
        return;
      }

      final submitState = cubit.state;
      if (appointmentId != null) {
        if (_hasChargeableProducts(submitState)) {
          try {
            await sl<LaropayCheckoutLauncher>().launch(
              appointmentId: appointmentId,
              workshopName: _workshopName(submitState),
            );
          } on LaropayCheckoutLaunchException catch (_) {
            if (!context.mounted) {
              return;
            }

            _showAppointmentMessage(
              context,
              message: l10n.laropayPaymentStartError,
              type: _AppointmentMessageType.error,
            );
            _goToWorkshopProfileOrHome(context);
          }
          return;
        }

        _showAppointmentMessage(
          context,
          message: l10n.appointmentCreatedSuccess,
          type: _AppointmentMessageType.success,
        );
        _goToWorkshopProfileOrHome(context);
      } else {
        _showAppointmentMessage(
          context,
          message: _appointmentSubmitErrorMessage(submitState, l10n),
          type: _AppointmentMessageType.error,
        );
      }
      return;
    }

    if (state.currentStep == 0) {
      final cubit = context.read<AppointmentCubit>();
      final isVehicleValid = await cubit.validateVehicleForBooking();

      if (!context.mounted) {
        return;
      }

      if (!isVehicleValid) {
        _showAppointmentMessage(
          context,
          message: _appointmentSubmitErrorMessage(cubit.state, l10n),
          type: _AppointmentMessageType.warning,
        );
        return;
      }
    }

    if (state.selectedService == null) {
      _showAppointmentMessage(
        context,
        message: l10n.appointmentNoSchedulableServices,
        type: _AppointmentMessageType.warning,
      );
      return;
    }

    if (state.currentStep == 0) {
      if (state.selectedDate == null || state.selectedTime == null) {
        _showAppointmentMessage(
          context,
          message: l10n.appointmentSelectDateTimeRequired,
          type: _AppointmentMessageType.warning,
        );
        return;
      }

      final cubit = context.read<AppointmentCubit>();
      final isScheduleAvailable = await cubit
          .validateSelectedScheduleForBooking();

      if (!context.mounted) {
        return;
      }

      if (!isScheduleAvailable) {
        _showAppointmentMessage(
          context,
          message: _appointmentSubmitErrorMessage(cubit.state, l10n),
          type: _AppointmentMessageType.warning,
        );
        return;
      }
    }

    context.read<AppointmentCubit>().goNext();
  }

  bool _hasChargeableProducts(AppointmentState state) {
    return state.includeProducts &&
        state.selectedProducts.any(
          (item) =>
              item.quantity > 0 &&
              item.product.sellingPrice != null &&
              item.product.sellingPrice! > 0,
        );
  }

  void _showAppointmentMessage(
    BuildContext context, {
    required String message,
    required _AppointmentMessageType type,
  }) {
    final theme = Theme.of(context);
    final config = switch (type) {
      _AppointmentMessageType.success => (
        icon: Icons.check_circle_outline,
        color: const Color(0xFF167A3A),
        background: const Color(0xFFEAF7EF),
      ),
      _AppointmentMessageType.warning => (
        icon: Icons.info_outline,
        color: const Color(0xFFB26A00),
        background: const Color(0xFFFFF5DF),
      ),
      _AppointmentMessageType.error => (
        icon: Icons.error_outline,
        color: _appointmentPrimary(context),
        background: const Color(0xFFFFECEA),
      ),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 4),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: config.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: config.color.withValues(alpha: 0.35)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(config.icon, color: config.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AutolabCustomer.secondary,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class WorkshopAppointmentInitialSelection {
  const WorkshopAppointmentInitialSelection({
    required this.service,
    this.products = const [],
  });

  final Product service;
  final List<AppointmentSelectedProduct> products;
}

enum _AppointmentMessageType { success, warning, error }

List<_AppointmentStep> _appointmentSteps(AppLocalizations l10n) {
  return [
    _AppointmentStep(l10n.appointmentStepDateTime, Icons.event_outlined),
    _AppointmentStep(
      l10n.appointmentStepConfirmation,
      Icons.check_circle_outline,
    ),
  ];
}

String _appointmentSubmitErrorMessage(
  AppointmentState state,
  AppLocalizations l10n,
) {
  return switch (state.submitError) {
    AppointmentSubmitError.dateUnavailable => l10n.appointmentDateUnavailable,
    AppointmentSubmitError.scheduleRequired => l10n.appointmentScheduleRequired,
    AppointmentSubmitError.slotUnavailable => l10n.appointmentSlotUnavailable,
    AppointmentSubmitError.scheduleValidationFailed =>
      l10n.appointmentScheduleValidationFailed,
    AppointmentSubmitError.vehiclePlateRequired =>
      l10n.appointmentVehiclePlateRequired,
    AppointmentSubmitError.vehiclePlateConflict =>
      l10n.appointmentVehiclePlateConflict,
    AppointmentSubmitError.vehicleValidationFailed =>
      l10n.appointmentVehicleValidationFailedDetailed,
    AppointmentSubmitError.bookingIncomplete =>
      l10n.appointmentBookingIncomplete,
    AppointmentSubmitError.authRequired => l10n.appointmentAuthRequired,
    AppointmentSubmitError.dateTimeInPast => l10n.appointmentDateTimeInPast,
    AppointmentSubmitError.invalidSlotInterval =>
      l10n.appointmentInvalidSlotInterval,
    AppointmentSubmitError.businessHoursUnavailable =>
      l10n.appointmentBusinessHoursUnavailable,
    AppointmentSubmitError.workshopClosed => l10n.appointmentWorkshopClosed,
    AppointmentSubmitError.outsideBusinessHours =>
      l10n.appointmentOutsideBusinessHours,
    AppointmentSubmitError.serviceNotSchedulable =>
      l10n.appointmentServiceNotSchedulable,
    AppointmentSubmitError.serviceDurationRequired =>
      l10n.appointmentServiceDurationRequired,
    AppointmentSubmitError.noActiveEmployees =>
      l10n.appointmentNoActiveEmployees,
    AppointmentSubmitError.vehicleNotOwned => l10n.appointmentVehicleNotOwned,
    AppointmentSubmitError.vehiclePlateRequiredForBooking =>
      l10n.appointmentVehiclePlateRequiredForBooking,
    AppointmentSubmitError.productsInvalid => l10n.appointmentProductsInvalid,
    AppointmentSubmitError.bookingConfigurationFailed =>
      l10n.appointmentBookingConfigurationFailed,
    AppointmentSubmitError.bookingFailed => l10n.appointmentCreateFailed,
    null => state.submitErrorMessage ?? l10n.appointmentCreateFailed,
  };
}

Color _appointmentPrimary(BuildContext context) {
  return Theme.of(context).colorScheme.primary;
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.steps,
    required this.currentStep,
    required this.workshopName,
  });

  final List<_AppointmentStep> steps;
  final int currentStep;
  final String workshopName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 38, 32, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AutolabLogo(large: true),
          const SizedBox(height: 64),
          ...List.generate(steps.length, (index) {
            return _DesktopStepItem(
              number: index + 1,
              title: steps[index].title,
              active: index == currentStep,
              done: index < currentStep,
              showLine: index < steps.length - 1,
            );
          }),
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.appointmentStepWorkshop,
            style: TextStyle(
              color: _appointmentPrimary(context),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            workshopName,
            style: TextStyle(
              color: _WorkshopAppointmentPageState.ink,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(
              context,
            )!.appointmentWorkshopFallbackDescription,
            style: const TextStyle(color: _WorkshopAppointmentPageState.muted),
          ),
          const SizedBox(height: 8),
          const Text(
            'Autolab Customer',
            style: TextStyle(color: _WorkshopAppointmentPageState.muted),
          ),
        ],
      ),
    );
  }
}

class _DesktopStepItem extends StatelessWidget {
  const _DesktopStepItem({
    required this.number,
    required this.title,
    required this.active,
    required this.done,
    required this.showLine,
  });

  final int number;
  final String title;
  final bool active;
  final bool done;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final color = active || done
        ? _appointmentPrimary(context)
        : AutolabCustomer.gray;
    final titleColor = active || done
        ? _appointmentPrimary(context)
        : _WorkshopAppointmentPageState.muted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active || done ? color : Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '$number',
                style: TextStyle(
                  color: active || done ? Colors.white : color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (showLine)
              Container(width: 1, height: 48, color: AutolabCustomer.border),
          ],
        ),
        const SizedBox(width: 30),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _MobileHeader extends StatefulWidget {
  const _MobileHeader({
    required this.steps,
    required this.currentStep,
    required this.onBack,
  });

  final List<_AppointmentStep> steps;
  final int currentStep;
  final VoidCallback onBack;

  @override
  State<_MobileHeader> createState() => _MobileHeaderState();
}

class _MobileHeaderState extends State<_MobileHeader> {
  final _scrollController = ScrollController();
  late List<GlobalKey> _stepKeys;

  @override
  void initState() {
    super.initState();
    _stepKeys = List.generate(widget.steps.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrentStep());
  }

  @override
  void didUpdateWidget(_MobileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.steps.length != widget.steps.length) {
      _stepKeys = List.generate(widget.steps.length, (_) => GlobalKey());
    }

    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.steps.length != widget.steps.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrentStep());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerCurrentStep() {
    if (!mounted || widget.currentStep >= _stepKeys.length) {
      return;
    }

    final itemContext = _stepKeys[widget.currentStep].currentContext;
    if (itemContext == null || !_scrollController.hasClients) {
      return;
    }

    final itemBox = itemContext.findRenderObject() as RenderBox?;
    final listBox = context.findRenderObject() as RenderBox?;
    if (itemBox == null || listBox == null) {
      return;
    }

    final itemOffset = itemBox.localToGlobal(Offset.zero, ancestor: listBox);
    final itemCenter = itemOffset.dx + itemBox.size.width / 2;
    final viewportCenter = listBox.size.width / 2;
    final rawOffset = _scrollController.offset + itemCenter - viewportCenter;
    final targetOffset = rawOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white),
      child: Container(
        height: 84,
        color: const Color(0xFFF6F6F6),
        alignment: Alignment.centerLeft,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 18),
          scrollDirection: Axis.horizontal,
          itemCount: widget.steps.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final active = index == widget.currentStep;

            return AnimatedContainer(
              key: _stepKeys[index],
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: active ? 20 : 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? _appointmentPrimary(context)
                      : AutolabCustomer.border,
                  width: active ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.steps[index].icon,
                    size: active ? 20 : 22,
                    color: active
                        ? _appointmentPrimary(context)
                        : _WorkshopAppointmentPageState.ink,
                  ),
                  if (active) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.steps[index].title,
                      style: TextStyle(
                        color: _appointmentPrimary(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Kept temporarily as a reusable fallback for a future change-vehicle flow.
// ignore: unused_element
class _VehicleStep extends StatelessWidget {
  const _VehicleStep({
    required this.title,
    required this.vehicles,
    required this.vehiclesStatus,
    required this.selectedVehicleId,
    required this.licensePlate,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.fuelType,
    required this.transmissionType,
    required this.onExistingVehicleSelected,
    required this.onNewVehicleSelected,
    required this.onLicensePlateChanged,
    required this.onVehicleTypeChanged,
    required this.onBrandChanged,
    required this.onModelChanged,
    required this.onYearChanged,
    required this.onColorChanged,
    required this.onFuelTypeChanged,
    required this.onTransmissionTypeChanged,
    required this.isDesktop,
  });

  final String title;
  final List<AppointmentVehicleRecord> vehicles;
  final AppointmentLoadStatus vehiclesStatus;
  final String? selectedVehicleId;
  final String licensePlate;
  final String vehicleType;
  final String brand;
  final String model;
  final String year;
  final String color;
  final String? fuelType;
  final String? transmissionType;
  final ValueChanged<AppointmentVehicleRecord> onExistingVehicleSelected;
  final VoidCallback onNewVehicleSelected;
  final ValueChanged<String> onLicensePlateChanged;
  final ValueChanged<String> onVehicleTypeChanged;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String?> onFuelTypeChanged;
  final ValueChanged<String?> onTransmissionTypeChanged;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VehiclePickerStrip(
          vehicles: vehicles,
          status: vehiclesStatus,
          selectedVehicleId: selectedVehicleId,
          onSelected: onExistingVehicleSelected,
          onNewVehicle: onNewVehicleSelected,
        ),
        const SizedBox(height: 20),
        _VehicleFormCard(
          key: ValueKey(selectedVehicleId ?? 'new-vehicle-form'),
          readOnly: selectedVehicleId != null,
          licensePlate: licensePlate,
          vehicleType: vehicleType,
          brand: brand,
          model: model,
          year: year,
          color: color,
          fuelType: fuelType,
          transmissionType: transmissionType,
          onLicensePlateChanged: onLicensePlateChanged,
          onVehicleTypeChanged: onVehicleTypeChanged,
          onBrandChanged: onBrandChanged,
          onModelChanged: onModelChanged,
          onYearChanged: onYearChanged,
          onColorChanged: onColorChanged,
          onFuelTypeChanged: onFuelTypeChanged,
          onTransmissionTypeChanged: onTransmissionTypeChanged,
        ),
      ],
    );
  }
}

class _VehicleFormCard extends StatelessWidget {
  const _VehicleFormCard({
    super.key,
    required this.readOnly,
    required this.licensePlate,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.fuelType,
    required this.transmissionType,
    required this.onLicensePlateChanged,
    required this.onVehicleTypeChanged,
    required this.onBrandChanged,
    required this.onModelChanged,
    required this.onYearChanged,
    required this.onColorChanged,
    required this.onFuelTypeChanged,
    required this.onTransmissionTypeChanged,
  });

  final bool readOnly;
  final String licensePlate;
  final String vehicleType;
  final String brand;
  final String model;
  final String year;
  final String color;
  final String? fuelType;
  final String? transmissionType;
  final ValueChanged<String> onLicensePlateChanged;
  final ValueChanged<String> onVehicleTypeChanged;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onYearChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String?> onFuelTypeChanged;
  final ValueChanged<String?> onTransmissionTypeChanged;

  static const _vehicleTypeValues = {
    'car',
    'motorcycle',
    'pickup',
    'suv',
    'truck',
    'bus',
    'trailer',
    'special_equipment',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AutolabCustomer.border),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: _appointmentPrimary(context), width: 2),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutolabCustomer.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            key: ValueKey('plate-$readOnly'),
            initialValue: licensePlate,
            readOnly: readOnly,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.appointmentVehiclePlateLabel,
              hintText: l10n.appointmentVehiclePlateHint,
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
            onChanged: onLicensePlateChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('vehicle-type-$vehicleType-$readOnly'),
            initialValue: _vehicleTypeValues.contains(vehicleType)
                ? vehicleType
                : null,
            decoration: InputDecoration(
              labelText: l10n.appointmentVehicleTypeLabel,
              prefixIcon: const Icon(Icons.category_outlined),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
            items: [
              DropdownMenuItem(
                value: 'car',
                child: Text(l10n.appointmentVehicleTypeCar),
              ),
              DropdownMenuItem(
                value: 'motorcycle',
                child: Text(l10n.appointmentVehicleTypeMotorcycle),
              ),
              DropdownMenuItem(
                value: 'pickup',
                child: Text(l10n.appointmentVehicleTypePickup),
              ),
              DropdownMenuItem(
                value: 'suv',
                child: Text(l10n.appointmentVehicleTypeSuv),
              ),
              DropdownMenuItem(
                value: 'truck',
                child: Text(l10n.appointmentVehicleTypeTruck),
              ),
              DropdownMenuItem(
                value: 'bus',
                child: Text(l10n.appointmentVehicleTypeBus),
              ),
              DropdownMenuItem(
                value: 'trailer',
                child: Text(l10n.appointmentVehicleTypeTrailer),
              ),
              DropdownMenuItem(
                value: 'special_equipment',
                child: Text(l10n.appointmentVehicleTypeSpecialEquipment),
              ),
            ],
            onChanged: readOnly
                ? null
                : (value) {
                    if (value != null) {
                      onVehicleTypeChanged(value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('brand-$readOnly'),
            initialValue: brand,
            readOnly: readOnly,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.appointmentVehicleBrandLabel,
              hintText: l10n.appointmentVehicleBrandHint,
              prefixIcon: const Icon(Icons.directions_car_outlined),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
            onChanged: onBrandChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('model-$readOnly'),
            initialValue: model,
            readOnly: readOnly,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.appointmentVehicleModelLabel,
              hintText: l10n.appointmentVehicleModelHint,
              prefixIcon: const Icon(Icons.badge_outlined),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
            onChanged: onModelChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('year-$readOnly'),
                  initialValue: year,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.appointmentVehicleYearLabel,
                    hintText: l10n.appointmentVehicleYearHint,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: border,
                    enabledBorder: border,
                    focusedBorder: focusedBorder,
                  ),
                  onChanged: onYearChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: ValueKey('color-$readOnly'),
                  initialValue: color,
                  readOnly: readOnly,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.appointmentVehicleColorLabel,
                    hintText: l10n.appointmentVehicleColorHint,
                    prefixIcon: const Icon(Icons.palette_outlined),
                    border: border,
                    enabledBorder: border,
                    focusedBorder: focusedBorder,
                  ),
                  onChanged: onColorChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('fuel-$fuelType-$readOnly'),
            initialValue: fuelType,
            decoration: InputDecoration(
              labelText: l10n.appointmentVehicleFuelLabel,
              prefixIcon: const Icon(Icons.local_gas_station_outlined),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
            items: [
              DropdownMenuItem(
                value: 'gasoline',
                child: Text(l10n.appointmentVehicleFuelGasoline),
              ),
              DropdownMenuItem(
                value: 'diesel',
                child: Text(l10n.appointmentVehicleFuelDiesel),
              ),
              DropdownMenuItem(
                value: 'electric',
                child: Text(l10n.appointmentVehicleFuelElectric),
              ),
              DropdownMenuItem(
                value: 'hybrid',
                child: Text(l10n.appointmentVehicleFuelHybrid),
              ),
            ],
            onChanged: readOnly ? null : onFuelTypeChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('transmission-$transmissionType-$readOnly'),
            initialValue: transmissionType,
            decoration: InputDecoration(
              labelText: l10n.appointmentVehicleTransmissionLabel,
              prefixIcon: const Icon(Icons.settings_outlined),
              border: border,
              enabledBorder: border,
              focusedBorder: focusedBorder,
            ),
            items: [
              DropdownMenuItem(
                value: 'manual',
                child: Text(l10n.appointmentVehicleTransmissionManual),
              ),
              DropdownMenuItem(
                value: 'automatic',
                child: Text(l10n.appointmentVehicleTransmissionAutomatic),
              ),
            ],
            onChanged: readOnly ? null : onTransmissionTypeChanged,
          ),
        ],
      ),
    );
  }
}

class _VehiclePickerStrip extends StatelessWidget {
  const _VehiclePickerStrip({
    required this.vehicles,
    required this.status,
    required this.selectedVehicleId,
    required this.onSelected,
    required this.onNewVehicle,
  });

  final List<AppointmentVehicleRecord> vehicles;
  final AppointmentLoadStatus status;
  final String? selectedVehicleId;
  final ValueChanged<AppointmentVehicleRecord> onSelected;
  final VoidCallback onNewVehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (status == AppointmentLoadStatus.loading) {
      return const SizedBox(
        height: 126,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.appointmentMyVehiclesTitle,
                style: const TextStyle(
                  color: _WorkshopAppointmentPageState.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _AddVehiclePill(
              label: l10n.appointmentAddVehicleShortAction,
              onTap: onNewVehicle,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (vehicles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AutolabCustomer.border),
            ),
            child: Text(
              l10n.appointmentNoVehiclesForWorkshop,
              style: const TextStyle(
                color: _WorkshopAppointmentPageState.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          SizedBox(
            height: 178,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vehicles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return SizedBox(
                  width: 152,
                  child: _ExistingVehicleCard(
                    vehicle: vehicle,
                    selected: selectedVehicleId == vehicle.id,
                    onTap: () => onSelected(vehicle),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AddVehiclePill extends StatelessWidget {
  const _AddVehiclePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _appointmentPrimary(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: _appointmentPrimary(context),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: _appointmentPrimary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExistingVehicleCard extends StatelessWidget {
  const _ExistingVehicleCard({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final AppointmentVehicleRecord vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = [
      vehicle.brand,
      vehicle.model,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');
    final subtitle = [
      vehicle.licensePlate,
      if (vehicle.year != null) vehicle.year.toString(),
    ].join(' ');

    final typeLabel = _localizedVehicleTypeLabel(context, vehicle.vehicleType);

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 178,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? _appointmentPrimary(context)
                  : AutolabCustomer.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 92,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: selected
                      ? AutolabCustomer.background
                      : const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.directions_car_filled_outlined,
                        color: _appointmentPrimary(context),
                        size: 42,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? _appointmentPrimary(context)
                            : AutolabCustomer.gray,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title.isEmpty ? vehicle.licensePlate : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _WorkshopAppointmentPageState.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                [
                  subtitle,
                  if (typeLabel != null && typeLabel.isNotEmpty) typeLabel,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _WorkshopAppointmentPageState.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _localizedVehicleTypeLabel(BuildContext context, String? vehicleType) {
  final normalizedType = vehicleType?.trim();
  if (normalizedType == null || normalizedType.isEmpty) {
    return null;
  }

  final l10n = AppLocalizations.of(context)!;
  return switch (normalizedType) {
    'car' => l10n.appointmentVehicleTypeCar,
    'motorcycle' => l10n.appointmentVehicleTypeMotorcycle,
    'pickup' => l10n.appointmentVehicleTypePickup,
    'suv' => l10n.appointmentVehicleTypeSuv,
    'truck' => l10n.appointmentVehicleTypeTruck,
    'bus' => l10n.appointmentVehicleTypeBus,
    'trailer' => l10n.appointmentVehicleTypeTrailer,
    'special_equipment' => l10n.appointmentVehicleTypeSpecialEquipment,
    _ => null,
  };
}

class _ProductsSelectionStep extends StatefulWidget {
  const _ProductsSelectionStep({
    required this.products,
    required this.status,
    required this.includeProducts,
    required this.selectedProducts,
    required this.onIncludeChanged,
    required this.onProductToggled,
    required this.onQuantityChanged,
  });

  final List<Product> products;
  final AppointmentLoadStatus status;
  final bool includeProducts;
  final List<AppointmentSelectedProduct> selectedProducts;
  final ValueChanged<bool> onIncludeChanged;
  final ValueChanged<Product> onProductToggled;
  final void Function(Product product, int delta) onQuantityChanged;

  @override
  State<_ProductsSelectionStep> createState() => _ProductsSelectionStepState();
}

class _ProductsSelectionStepState extends State<_ProductsSelectionStep> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AutolabCustomer.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appointmentProductsSwitchLabel,
                  style: TextStyle(
                    color: _WorkshopAppointmentPageState.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(
                value: widget.includeProducts,
                activeThumbColor: _appointmentPrimary(context),
                onChanged: widget.onIncludeChanged,
              ),
            ],
          ),
        ),
        if (!widget.includeProducts) ...[
          const SizedBox(height: 16),
          _ProductsInfoMessage(
            message: l10n.appointmentProductsOptionalMessage,
          ),
        ] else ...[
          const SizedBox(height: 18),
          if (widget.status == AppointmentLoadStatus.loading)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.products.isEmpty)
            _ProductsInfoMessage(message: l10n.appointmentProductsEmpty)
          else
            ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
                AppointmentSelectedProduct? selectedProduct;
                for (final item in widget.selectedProducts) {
                  if (item.product.id == product.id) {
                    selectedProduct = item;
                    break;
                  }
                }
                final selected = selectedProduct != null;
                final quantity = selectedProduct?.quantity ?? 0;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == widget.products.length - 1 ? 0 : 12,
                  ),
                  child: _ProductOptionCard(
                    product: product,
                    selected: selected,
                    quantity: quantity,
                    onTap: () => widget.onProductToggled(product),
                    onQuantityChanged: (delta) =>
                        widget.onQuantityChanged(product, delta),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}

class _ServiceMetaChip extends StatelessWidget {
  const _ServiceMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _appointmentPrimary(context)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: _WorkshopAppointmentPageState.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductOptionCard extends StatelessWidget {
  const _ProductOptionCard({
    required this.product,
    required this.selected,
    required this.quantity,
    required this.onTap,
    required this.onQuantityChanged,
  });

  final Product product;
  final bool selected;
  final int quantity;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AutolabCustomer.background : Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? _appointmentPrimary(context)
                  : AutolabCustomer.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _appointmentPrimary(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: _WorkshopAppointmentPageState.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.effectiveDescription,
                      style: TextStyle(
                        color: _WorkshopAppointmentPageState.muted,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    if (product.sellingPrice != null) ...[
                      const SizedBox(height: 12),
                      _ServiceMetaChip(
                        icon: Icons.payments_outlined,
                        label: formatProductPrice(product.sellingPrice),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (selected)
                _QuantityStepper(
                  quantity: quantity,
                  onChanged: onQuantityChanged,
                )
              else
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: AutolabCustomer.gray,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsInfoMessage extends StatelessWidget {
  const _ProductsInfoMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AutolabCustomer.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _appointmentPrimary(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _WorkshopAppointmentPageState.ink,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E1E1)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove_rounded,
            onTap: () => onChanged(-1),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _WorkshopAppointmentPageState.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _QuantityButton(icon: Icons.add_rounded, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 20, color: _appointmentPrimary(context)),
      ),
    );
  }
}

class _BookingSubmittingOverlay extends StatelessWidget {
  const _BookingSubmittingOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Positioned.fill(
      child: AbsorbPointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
          ),
          child: Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AutolabCustomer.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: _appointmentPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.appointmentCreatingTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _WorkshopAppointmentPageState.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.appointmentCreatingMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _WorkshopAppointmentPageState.muted,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.canGoBack,
    required this.isLastStep,
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
  });

  final bool canGoBack;
  final bool isLastStep;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final horizontalPadding = isDesktop
        ? AutolabCustomer.spacingXl
        : AutolabCustomer.responsiveScreenMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AutolabCustomer.spacingSm,
        horizontalPadding,
        isDesktop ? AutolabCustomer.spacingXl : AutolabCustomer.spacingLg,
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    label: canGoBack
                        ? l10n.appointmentBackAction
                        : l10n.appointmentExitAction,
                    onPressed: isSubmitting ? null : onBack,
                  ),
                ),
                const SizedBox(width: AutolabCustomer.spacingSm),
                Expanded(
                  child: _OutlineActionButton(
                    label: isSubmitting
                        ? l10n.appointmentCreatingAction
                        : isLastStep
                        ? l10n.appointmentConfirmAction
                        : l10n.appointmentNextAction,
                    onPressed: isSubmitting ? null : onNext,
                    isLoading: isSubmitting,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AutolabCustomer.responsiveDouble(
        context,
        compact: 46,
        regular: 52,
        tablet: 58,
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isPrimary
              ? AutolabCustomer.primary
              : Colors.transparent,
          foregroundColor: isPrimary
              ? AutolabCustomer.white
              : AutolabCustomer.customerTextColor(context),
          disabledBackgroundColor: isPrimary
              ? AutolabCustomer.primary.withValues(alpha: 0.45)
              : Colors.transparent,
          disabledForegroundColor: AutolabCustomer.customerSecondaryTextColor(
            context,
          ),
          side: BorderSide(color: AutolabCustomer.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
          ),
          textStyle: AutolabCustomer.body.copyWith(fontWeight: FontWeight.w800),
        ),
        child: FittedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentFlowHeader extends StatelessWidget {
  const _AppointmentFlowHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [const _AutolabLogo()],
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingMd),
        Text(
          title,
          style: AutolabCustomer.bodyLarge.copyWith(
            color: AutolabCustomer.customerTextColor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AutolabCustomer.spacingXs),
          Text(
            subtitle!,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _DateTimeMock extends StatelessWidget {
  const _DateTimeMock({
    required this.title,
    required this.selectedDate,
    required this.selectedTime,
    required this.focusedDate,
    required this.unavailableDates,
    required this.unavailableTimesByDate,
    required this.availableTimesByDate,
    required this.availabilityStatus,
    required this.onDaySelected,
    required this.onFocusedDateChanged,
    required this.onSelected,
  });

  final String title;
  final DateTime? selectedDate;
  final String? selectedTime;
  final DateTime focusedDate;
  final List<DateTime> unavailableDates;
  final Map<DateTime, Set<String>> unavailableTimesByDate;
  final Map<DateTime, List<String>> availableTimesByDate;
  final AppointmentLoadStatus availabilityStatus;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onFocusedDateChanged;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppointmentFlowHeader(title: title),
        const SizedBox(height: AutolabCustomer.spacingMd),
        _AppointmentCalendar(
          selectedDate: selectedDate,
          focusedDate: focusedDate,
          unavailableDates: unavailableDates,
          shouldBlockUnavailableDates:
              availabilityStatus == AppointmentLoadStatus.success,
          onDaySelected: onDaySelected,
          onFocusedDateChanged: onFocusedDateChanged,
        ),
        if (selectedDate != null) ...[
          const SizedBox(height: 24),
          _AvailableHoursPanel(
            times: _timesForSelectedDate(),
            selectedTime: selectedTime,
            unavailableTimes: _unavailableTimesForSelectedDate(),
            availabilityStatus: availabilityStatus,
            onSelected: onSelected,
          ),
        ],
      ],
    );
  }

  List<String> _availableTimesForSelectedDate() {
    final date = selectedDate;
    if (date == null) {
      return const [];
    }

    for (final entry in availableTimesByDate.entries) {
      if (isSameDay(entry.key, date)) {
        return entry.value;
      }
    }

    return const [];
  }

  Set<String> _unavailableTimesForSelectedDate() {
    final date = selectedDate;
    if (date == null) {
      return const {};
    }

    for (final entry in unavailableTimesByDate.entries) {
      if (isSameDay(entry.key, date)) {
        return entry.value;
      }
    }

    return const {};
  }

  List<String> _timesForSelectedDate() {
    final times = {
      ..._availableTimesForSelectedDate(),
      ..._unavailableTimesForSelectedDate(),
    }.toList();

    times.sort();
    return times;
  }
}

class _AppointmentCalendar extends StatelessWidget {
  const _AppointmentCalendar({
    required this.selectedDate,
    required this.focusedDate,
    required this.unavailableDates,
    required this.shouldBlockUnavailableDates,
    required this.onDaySelected,
    required this.onFocusedDateChanged,
  });

  final DateTime? selectedDate;
  final DateTime focusedDate;
  final List<DateTime> unavailableDates;
  final bool shouldBlockUnavailableDates;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onFocusedDateChanged;

  static final _firstDay = DateTime.utc(2020, 1, 1);
  static final _lastDay = DateTime.utc(2035, 12, 31);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rowHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 38,
      regular: 43,
      tablet: 50,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar<void>(
          firstDay: _firstDay,
          lastDay: _lastDay,
          focusedDay: focusedDate,
          locale: 'es',
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableGestures: AvailableGestures.none,
          daysOfWeekHeight: 26,
          rowHeight: rowHeight,
          enabledDayPredicate: (day) {
            final calendarDay = DateTime(day.year, day.month, day.day);
            if (calendarDay.isBefore(today)) {
              return false;
            }

            if (!shouldBlockUnavailableDates) {
              return true;
            }

            return !unavailableDates.any(
              (unavailableDate) => isSameDay(unavailableDate, day),
            );
          },
          selectedDayPredicate: (day) =>
              selectedDate != null && isSameDay(day, selectedDate),
          onDaySelected: (selected, focused) {
            onDaySelected(selected);
          },
          onPageChanged: onFocusedDateChanged,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: AutolabCustomer.customerTextColor(context),
              size: AutolabCustomer.iconSm,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: AutolabCustomer.customerTextColor(context),
              size: AutolabCustomer.iconSm,
            ),
            leftChevronPadding: EdgeInsets.zero,
            rightChevronPadding: EdgeInsets.zero,
            leftChevronMargin: EdgeInsets.zero,
            rightChevronMargin: EdgeInsets.zero,
            titleTextStyle: TextStyle(
              color: AutolabCustomer.customerTextColor(context),
              fontSize: AutolabCustomer.responsiveDouble(
                context,
                compact: 12,
                regular: 13,
                tablet: 16,
              ),
              fontWeight: FontWeight.w800,
            ),
            titleTextFormatter: (date, locale) {
              final month = DateFormat.MMMM(locale).format(date);
              return l10n.appointmentMonthYearTitle(
                _capitalize(month),
                date.year,
              );
            },
            headerPadding: const EdgeInsets.only(bottom: 6),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: AutolabCustomer.customerTextColor(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            weekendStyle: TextStyle(
              color: AutolabCustomer.customerTextColor(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          calendarStyle: const CalendarStyle(outsideDaysVisible: true),
          calendarBuilders: CalendarBuilders<void>(
            defaultBuilder: (context, day, focusedDay) {
              return _TableCalendarDay(day: day);
            },
            disabledBuilder: (context, day, focusedDay) {
              return _TableCalendarDay(day: day, disabled: true);
            },
            outsideBuilder: (context, day, focusedDay) {
              return _TableCalendarDay(day: day, outside: true);
            },
            selectedBuilder: (context, day, focusedDay) {
              return _TableCalendarDay(day: day, selected: true);
            },
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingMd),
        Wrap(
          spacing: AutolabCustomer.spacingSm,
          runSpacing: AutolabCustomer.spacingXs,
          children: [
            _CalendarLegend(
              color: AutolabCustomer.primary,
              shape: BoxShape.circle,
              label: l10n.appointmentSelectedDayLegend,
            ),
            _CalendarLegend(
              color: Colors.transparent,
              borderColor: AutolabCustomer.customerBorderColor(context),
              label: l10n.appointmentAvailableDayLegend,
            ),
            if (shouldBlockUnavailableDates)
              _CalendarLegend(
                color: AutolabCustomer.gray,
                label: l10n.appointmentOccupiedDayLegend,
              ),
          ],
        ),
      ],
    );
  }
}

class _TableCalendarDay extends StatelessWidget {
  const _TableCalendarDay({
    required this.day,
    this.selected = false,
    this.outside = false,
    this.disabled = false,
  });

  final DateTime day;
  final bool selected;
  final bool outside;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = disabled
        ? AutolabCustomer.gray
        : selected
        ? AutolabCustomer.primary
        : Colors.transparent;
    final textColor = selected
        ? AutolabCustomer.white
        : disabled
        ? AutolabCustomer.white
        : outside
        ? AutolabCustomer.gray.withValues(alpha: 0.45)
        : day.weekday == DateTime.saturday || day.weekday == DateTime.sunday
        ? AutolabCustomer.primary
        : AutolabCustomer.customerTextColor(context);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: selected || disabled ? 30 : double.infinity,
        height: selected || disabled ? 30 : double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: selected ? BoxShape.circle : BoxShape.rectangle,
          border: Border.all(
            color: AutolabCustomer.customerBorderColor(
              context,
            ).withValues(alpha: 0.32),
            width: 0.5,
          ),
        ),
        child: Text(
          '${day.day}',
          style: AutolabCustomer.label.copyWith(
            color: textColor,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({
    required this.color,
    required this.label,
    this.borderColor,
    this.shape = BoxShape.rectangle,
  });

  final Color color;
  final String label;
  final Color? borderColor;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
        ),
        const SizedBox(width: AutolabCustomer.spacingXs),
        Text(
          label,
          style: AutolabCustomer.caption.copyWith(
            color: AutolabCustomer.customerTextColor(context),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _AvailableHoursPanel extends StatelessWidget {
  const _AvailableHoursPanel({
    required this.times,
    required this.selectedTime,
    required this.unavailableTimes,
    required this.availabilityStatus,
    required this.onSelected,
  });

  final List<String> times;
  final String? selectedTime;
  final Set<String> unavailableTimes;
  final AppointmentLoadStatus availabilityStatus;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appointmentAvailableHoursTitle,
          style: AutolabCustomer.bodyLarge.copyWith(
            color: AutolabCustomer.customerTextColor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingXs),
        Text(
          l10n.appointmentPickupLabel,
          style: AutolabCustomer.label.copyWith(
            color: AutolabCustomer.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingMd),
        if (availabilityStatus == AppointmentLoadStatus.loading)
          _AvailabilityPanelMessage(
            icon: Icons.schedule_outlined,
            message: l10n.appointmentAvailableHoursLoading,
          )
        else if (availabilityStatus == AppointmentLoadStatus.failure)
          _AvailabilityPanelMessage(
            icon: Icons.error_outline,
            message: l10n.appointmentAvailableHoursFailed,
            color: AutolabCustomer.primary,
          )
        else if (times.isEmpty)
          _AvailabilityPanelMessage(
            icon: Icons.info_outline,
            message: l10n.appointmentAvailableHoursEmpty,
          )
        else
          Wrap(
            spacing: AutolabCustomer.spacingXs,
            runSpacing: AutolabCustomer.spacingXs,
            children: times.map((time) {
              final selected = selectedTime == time;
              final unavailable = unavailableTimes.contains(time);

              return SizedBox(
                width: AutolabCustomer.responsiveDouble(
                  context,
                  compact: 70,
                  regular: 74,
                  tablet: 86,
                ),
                height: 34,
                child: OutlinedButton(
                  onPressed: unavailable ? null : () => onSelected(time),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: unavailable
                        ? AutolabCustomer.gray.withValues(alpha: 0.35)
                        : selected
                        ? AutolabCustomer.primary
                        : Colors.transparent,
                    foregroundColor: unavailable
                        ? AutolabCustomer.gray
                        : selected
                        ? AutolabCustomer.white
                        : AutolabCustomer.customerTextColor(context),
                    side: BorderSide(
                      color: unavailable
                          ? AutolabCustomer.gray.withValues(alpha: 0.5)
                          : selected
                          ? AutolabCustomer.primary
                          : AutolabCustomer.customerBorderColor(context),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AutolabCustomer.radiusChip,
                      ),
                    ),
                    textStyle: AutolabCustomer.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(time),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _AvailabilityPanelMessage extends StatelessWidget {
  const _AvailabilityPanelMessage({
    required this.icon,
    required this.message,
    this.color,
  });

  final IconData icon;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AutolabCustomer.gray;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: effectiveColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: effectiveColor, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _AppointmentNoteInput extends StatelessWidget {
  const _AppointmentNoteInput({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      borderSide: const BorderSide(color: AutolabCustomer.primary),
    );

    return TextFormField(
      key: const ValueKey('appointment-note-input'),
      initialValue: initialValue,
      minLines: 4,
      maxLines: 5,
      maxLength: 280,
      onChanged: onChanged,
      style: AutolabCustomer.caption.copyWith(
        color: AutolabCustomer.customerTextColor(context),
      ),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.appointmentNoteHint,
        hintStyle: AutolabCustomer.caption.copyWith(
          color: AutolabCustomer.customerSecondaryTextColor(context),
        ),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(
            color: AutolabCustomer.primary,
            width: 1.4,
          ),
        ),
        counterStyle: AutolabCustomer.label.copyWith(
          color: AutolabCustomer.customerTextColor(context),
        ),
      ),
    );
  }
}

class _BookingReviewStep extends StatelessWidget {
  const _BookingReviewStep({
    required this.title,
    required this.workshopName,
    required this.service,
    required this.licensePlate,
    required this.products,
    required this.date,
    required this.time,
    required this.onNoteChanged,
    required this.note,
  });

  final String title;
  final String workshopName;
  final Product? service;
  final String licensePlate;
  final List<AppointmentSelectedProduct> products;
  final DateTime? date;
  final String time;
  final ValueChanged<String> onNoteChanged;
  final String note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabel = date == null
        ? l10n.appointmentPendingDate
        : l10n.appointmentFullDate(
            date!.day,
            _monthName(context, date!),
            date!.year,
          );
    final productsTotal = products.fold<double>(
      0,
      (total, item) =>
          total + ((item.product.sellingPrice ?? 0) * item.quantity),
    );
    final hasPricelessItems = products.any(
      (item) => item.product.sellingPrice == null,
    );
    final servicePrice = service?.sellingPrice;
    final total = (servicePrice ?? 0) + productsTotal;
    final hasPriceToConfirm = servicePrice == null || hasPricelessItems;
    final iva = total * 13 / 113;
    final subtotal = total - iva;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppointmentFlowHeader(
          title: title,
          subtitle: l10n.appointmentConfirmationReadyTitle,
        ),
        const SizedBox(height: AutolabCustomer.spacingLg),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            AutolabCustomer.responsiveDouble(
              context,
              compact: AutolabCustomer.spacingSmd,
              regular: AutolabCustomer.spacingMd,
              tablet: AutolabCustomer.spacingLg,
            ),
          ),
          decoration: BoxDecoration(
            color: AutolabCustomer.customerSurfaceColor(context),
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.16),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AutolabCustomer.responsiveDouble(
                    context,
                    compact: 56,
                    regular: 62,
                    tablet: 72,
                  ),
                  height: AutolabCustomer.responsiveDouble(
                    context,
                    compact: 56,
                    regular: 62,
                    tablet: 72,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AutolabCustomer.primary,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AutolabCustomer.primary,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              _SummaryRow(
                label: l10n.appointmentVehiclePlateLabel,
                value: licensePlate.trim().isEmpty
                    ? l10n.appointmentPendingPlate
                    : licensePlate.trim().toUpperCase(),
              ),
              _SummaryRow(
                label: l10n.appointmentWorkshopLabel,
                value: workshopName,
              ),
              _SummaryRow(
                label: l10n.appointmentServiceLabel,
                value: service?.name ?? l10n.appointmentPendingService,
              ),
              _SummaryRow(
                label: l10n.appointmentCostLabel,
                value: servicePrice == null
                    ? l10n.appointmentPriceToConfirm
                    : formatProductPrice(servicePrice),
              ),
              _SummaryRow(
                label: l10n.appointmentDateLabel,
                value: '$dayLabel, $time',
              ),
              _SummaryRow(
                label: l10n.appointmentDurationLabel,
                value: _durationLabel(l10n, service?.estimatedDurationHours),
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              Text(
                l10n.appointmentOptionalNoteLabel,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingSm),
              _AppointmentNoteInput(
                initialValue: note,
                onChanged: onNoteChanged,
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              Text(
                l10n.appointmentProductsLabel,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingXs),
              if (products.isEmpty)
                _SummaryRow(
                  label: l10n.appointmentNoAdditionalProducts,
                  value: formatProductPrice(0),
                  labelColor: AutolabCustomer.primary,
                )
              else
                ...products.map((item) => _ProductSummaryRow(item: item)),
              const SizedBox(height: AutolabCustomer.spacingLg),
              _SummaryRow(
                label: l10n.appointmentSubtotalLabel,
                value: hasPriceToConfirm
                    ? l10n.appointmentPriceToConfirm
                    : formatProductPrice(subtotal),
              ),
              _SummaryRow(
                label: l10n.appointmentTaxLabel,
                value: hasPriceToConfirm
                    ? l10n.appointmentPriceToConfirm
                    : formatProductPrice(iva),
              ),
              _SummaryRow(
                label: l10n.appointmentTotalToPayLabel,
                value: hasPriceToConfirm
                    ? l10n.appointmentPriceToConfirm
                    : l10n.appointmentPriceWithTaxSuffix(
                        formatProductPrice(total),
                      ),
                emphasize: true,
              ),
              const SizedBox(height: AutolabCustomer.spacingSm),
              Center(
                child: Text(
                  l10n.appointmentConfirmationDeliveryMessage,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.primary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthName(BuildContext context, DateTime date) {
    return DateFormat.MMMM(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
  }

  String _durationLabel(AppLocalizations l10n, double? hours) {
    final durationHours = hours ?? 1;
    final minutes = (durationHours * 60).round();

    if (minutes < 60) {
      return l10n.appointmentDurationMinutes(minutes);
    }

    final wholeHours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return l10n.appointmentDurationHours(wholeHours);
    }

    return l10n.appointmentDurationHoursMinutes(wholeHours, remainingMinutes);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.labelColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final labelWidth = AutolabCustomer.responsiveDouble(
      context,
      compact: 92,
      regular: 110,
      tablet: 132,
    );
    final valueStyle = AutolabCustomer.caption.copyWith(
      color: AutolabCustomer.customerTextColor(context),
      fontSize: AutolabCustomer.responsiveDouble(
        context,
        compact: emphasize ? 12 : 11,
        regular: emphasize ? 13 : 12,
        tablet: emphasize ? 14 : 13,
      ),
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AutolabCustomer.caption.copyWith(
                color: labelColor ?? AutolabCustomer.customerTextColor(context),
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AutolabCustomer.spacingSm),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: valueStyle),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;

  return '${value[0].toUpperCase()}${value.substring(1)}';
}

class _ProductSummaryRow extends StatelessWidget {
  const _ProductSummaryRow({required this.item});

  final AppointmentSelectedProduct item;

  @override
  Widget build(BuildContext context) {
    final price = item.product.sellingPrice;
    final subtotal = price == null ? null : price * item.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatProductPrice(price)} x ${item.quantity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutolabCustomer.spacingSm),
          Flexible(
            flex: 0,
            child: Text(
              subtotal == null
                  ? AppLocalizations.of(context)!.appointmentPriceToConfirm
                  : formatProductPrice(subtotal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutolabLogo extends StatelessWidget {
  const _AutolabLogo({this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return AutolabLogoMark(width: large ? 260 : 88, height: large ? 118 : 34);
  }
}

class _AppointmentStep {
  const _AppointmentStep(this.title, this.icon);

  final String title;
  final IconData icon;
}
