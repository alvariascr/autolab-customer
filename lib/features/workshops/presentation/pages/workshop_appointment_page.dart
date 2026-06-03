import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/widgets/product_price_text.dart';
import '../../../profile/presentation/page/garage_page.dart';
import '../../application/appointment_cubit.dart';
import '../../application/appointment_state.dart';
import '../../domain/entities/appointment_vehicle.dart';

class WorkshopAppointmentPage extends StatefulWidget {
  const WorkshopAppointmentPage({super.key, required this.workshopId});

  final String workshopId;

  @override
  State<WorkshopAppointmentPage> createState() =>
      _WorkshopAppointmentPageState();
}

class _WorkshopAppointmentPageState extends State<WorkshopAppointmentPage> {
  static const ink = AppColors.ink;
  static const muted = AppColors.muted;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppointmentCubit>()..load(widget.workshopId),
      child: BlocBuilder<AppointmentCubit, AppointmentState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          final steps = _appointmentSteps(l10n);
          final isDesktop = MediaQuery.sizeOf(context).width >= 900;

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                        _MobileHeader(
                          steps: steps,
                          currentStep: state.currentStep,
                          onBack: () => _handleBack(context, state),
                        ),
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 92 : 28,
              isDesktop ? 96 : 22,
              isDesktop ? 92 : 28,
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
          isSubmitting:
              state.submitStatus == AppointmentSubmitStatus.submitting,
          onBack: () => _handleBack(context, state),
          onNext: () => _goNextStep(context, state, steps.length),
        ),
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
        return _VehicleStep(
          title: steps[state.currentStep].title,
          vehicles: state.vehicles,
          vehiclesStatus: state.vehiclesStatus,
          selectedVehicleId: state.selectedVehicleId,
          licensePlate: state.vehicleLicensePlate,
          vehicleType: state.vehicleType,
          brand: state.vehicleBrand,
          model: state.vehicleModel,
          year: state.vehicleYear,
          color: state.vehicleColor,
          fuelType: state.vehicleFuelType,
          transmissionType: state.vehicleTransmissionType,
          onExistingVehicleSelected: context
              .read<AppointmentCubit>()
              .selectExistingVehicle,
          onNewVehicleSelected: () => _openGarage(context),
          onLicensePlateChanged: context
              .read<AppointmentCubit>()
              .updateVehicleLicensePlate,
          onVehicleTypeChanged: context
              .read<AppointmentCubit>()
              .updateVehicleType,
          onBrandChanged: context.read<AppointmentCubit>().updateVehicleBrand,
          onModelChanged: context.read<AppointmentCubit>().updateVehicleModel,
          onYearChanged: context.read<AppointmentCubit>().updateVehicleYear,
          onColorChanged: context.read<AppointmentCubit>().updateVehicleColor,
          onFuelTypeChanged: context
              .read<AppointmentCubit>()
              .updateVehicleFuelType,
          onTransmissionTypeChanged: context
              .read<AppointmentCubit>()
              .updateVehicleTransmissionType,
          isDesktop: isDesktop,
        );
      case 1:
        return _MockStepPanel(
          icon: Icons.build_circle_outlined,
          title: steps[state.currentStep].title,
          child: _ServiceSelectionStep(
            services: state.services,
            status: state.servicesStatus,
            selectedService: state.selectedService,
            onSelected: context.read<AppointmentCubit>().selectService,
          ),
        );
      case 2:
        return _MockStepPanel(
          icon: Icons.inventory_2_outlined,
          title: steps[state.currentStep].title,
          child: _ProductsSelectionStep(
            products: state.products,
            status: state.productsStatus,
            includeProducts: state.includeProducts,
            selectedProducts: state.selectedProducts,
            onIncludeChanged: context
                .read<AppointmentCubit>()
                .setIncludeProducts,
            onProductToggled: context.read<AppointmentCubit>().toggleProduct,
            onQuantityChanged: context
                .read<AppointmentCubit>()
                .changeProductQuantity,
          ),
        );
      case 3:
        return _MockStepPanel(
          icon: Icons.event_outlined,
          title: steps[state.currentStep].title,
          child: _DateTimeMock(
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
          ),
        );
      case 4:
        return _ConfirmationMock(
          workshopName: _workshopName(state),
          service: state.selectedService,
          licensePlate: state.vehicleLicensePlate,
          products: state.selectedProducts,
          date: state.selectedDate,
          time: state.selectedTime ?? '9:00 AM',
          paymentMethod: state.selectedPaymentMethod,
          onPaymentMethodSelected: context
              .read<AppointmentCubit>()
              .selectPaymentMethod,
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

  Future<void> _openGarage(BuildContext context) async {
    final cubit = context.read<AppointmentCubit>();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GaragePage()));

    if (!mounted) {
      return;
    }

    await cubit.refreshVehicles();
  }

  void _handleBack(BuildContext context, AppointmentState state) {
    if (state.currentStep == 0) {
      _goToWorkshopProfileOrHome(context);
      return;
    }

    context.read<AppointmentCubit>().goBack();
  }

  void _goToWorkshopProfileOrHome(BuildContext context) {
    final workshopId = widget.workshopId.trim();
    if (workshopId.isEmpty) {
      context.go('/home-customer');
      return;
    }

    context.go('/workshops/$workshopId');
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

    if (state.currentStep == 1 && state.selectedService == null) {
      _showAppointmentMessage(
        context,
        message: l10n.appointmentSelectServiceRequired,
        type: _AppointmentMessageType.warning,
      );
      return;
    }

    if (state.currentStep == 3) {
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
                      color: AppColors.ink,
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

enum _AppointmentMessageType { success, warning, error }

List<_AppointmentStep> _appointmentSteps(AppLocalizations l10n) {
  return [
    _AppointmentStep(l10n.appointmentStepVehicleInfo, Icons.directions_car),
    _AppointmentStep(l10n.appointmentStepService, Icons.build_circle_outlined),
    _AppointmentStep(l10n.appointmentStepProducts, Icons.inventory_2_outlined),
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
    AppointmentSubmitError.serviceNotSchedulable =>
      l10n.appointmentServiceNotSchedulable,
    AppointmentSubmitError.vehicleNotOwned => l10n.appointmentVehicleNotOwned,
    AppointmentSubmitError.vehiclePlateRequiredForBooking =>
      l10n.appointmentVehiclePlateRequiredForBooking,
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
        : AppColors.disabledStep;
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
              Container(width: 1, height: 48, color: AppColors.subtleBorder),
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
                      : AppColors.subtleBorder,
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
      borderSide: BorderSide(color: AppColors.border),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: _appointmentPrimary(context), width: 2),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
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
              hintText: 'Ej. ABC123',
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
              hintText: 'Ej. Toyota',
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
              hintText: 'Ej. Yaris',
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
                    hintText: 'Ej. 2019',
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
                    hintText: 'Ej. Negro',
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
              border: Border.all(color: AppColors.border),
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
      color: AppColors.appointmentSelectedBackground,
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
              color: selected ? _appointmentPrimary(context) : AppColors.border,
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
                      ? AppColors.appointmentSelectedBackground
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
                            : AppColors.muted,
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

class _ServiceSelectionStep extends StatefulWidget {
  const _ServiceSelectionStep({
    required this.services,
    required this.status,
    required this.selectedService,
    required this.onSelected,
  });

  final List<Product> services;
  final AppointmentLoadStatus status;
  final Product? selectedService;
  final ValueChanged<Product> onSelected;

  @override
  State<_ServiceSelectionStep> createState() => _ServiceSelectionStepState();
}

class _ServiceSelectionStepState extends State<_ServiceSelectionStep> {
  @override
  Widget build(BuildContext context) {
    if (widget.status == AppointmentLoadStatus.loading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.services.isEmpty) {
      return const _EmptyServicesMessage();
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.services.length,
      itemBuilder: (context, index) {
        final service = widget.services[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == widget.services.length - 1 ? 0 : 12,
          ),
          child: _ServiceCard(
            service: service,
            selected: widget.selectedService?.id == service.id,
            onTap: () => widget.onSelected(service),
          ),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final Product service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.appointmentSelectedBackground : Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? _appointmentPrimary(context) : AppColors.border,
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
                  Icons.build_circle_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        color: _WorkshopAppointmentPageState.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.effectiveDescription,
                      style: TextStyle(
                        color: _WorkshopAppointmentPageState.muted,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (service.sellingPrice != null)
                          _ServiceMetaChip(
                            icon: Icons.payments_outlined,
                            label: formatProductPrice(service.sellingPrice),
                          ),
                        if (service.estimatedDurationHours != null)
                          _ServiceMetaChip(
                            icon: Icons.schedule_rounded,
                            label:
                                '${service.estimatedDurationHours!.toStringAsFixed(1)} h',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

class _EmptyServicesMessage extends StatelessWidget {
  const _EmptyServicesMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _appointmentPrimary(context)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.appointmentNoSchedulableServices,
              style: const TextStyle(
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
            border: Border.all(color: AppColors.border),
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
      color: selected ? AppColors.appointmentSelectedBackground : Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? _appointmentPrimary(context) : AppColors.border,
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
                  color: AppColors.disabledIcon,
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
        border: Border.all(color: AppColors.border),
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

class _PaymentMethodStep extends StatelessWidget {
  const _PaymentMethodStep({
    required this.selectedMethod,
    required this.onSelected,
  });

  final String selectedMethod;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final methods = [
      _PaymentMethodOption(
        title: l10n.appointmentPaymentCard,
        subtitle: l10n.appointmentPaymentCardSubtitle,
        icon: Icons.credit_card_outlined,
      ),
      _PaymentMethodOption(
        title: l10n.appointmentPaymentSinpe,
        subtitle: l10n.appointmentPaymentSinpeSubtitle,
        icon: Icons.phone_android_outlined,
      ),
    ];

    return Column(
      children: methods.map((method) {
        final selected = selectedMethod == method.title;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PaymentMethodCard(
            option: method,
            selected: selected,
            onTap: () => onSelected(method.title),
          ),
        );
      }).toList(),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PaymentMethodOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.appointmentSelectedBackground : Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? _appointmentPrimary(context) : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _appointmentPrimary(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(option.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        color: _WorkshopAppointmentPageState.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        color: _WorkshopAppointmentPageState.muted,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? _appointmentPrimary(context)
                    : AppColors.disabledIcon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodOption {
  const _PaymentMethodOption({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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

    return Padding(
      padding: EdgeInsets.fromLTRB(28, 10, 28, isDesktop ? 36 : 22),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    icon: canGoBack ? Icons.chevron_left : Icons.close_rounded,
                    label: canGoBack
                        ? l10n.appointmentBackAction
                        : l10n.appointmentExitAction,
                    onPressed: isSubmitting ? null : onBack,
                  ),
                ),
                Expanded(
                  child: _OutlineActionButton(
                    trailingIcon: isSubmitting
                        ? null
                        : isLastStep
                        ? Icons.check_rounded
                        : Icons.chevron_right,
                    label: isSubmitting
                        ? l10n.appointmentCreatingAction
                        : isLastStep
                        ? l10n.appointmentConfirmAction
                        : l10n.appointmentNextAction,
                    onPressed: isSubmitting ? null : onNext,
                    isLoading: isSubmitting,
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
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkControl,
          side: BorderSide(color: Color(0xFF555555)),
          shape: const RoundedRectangleBorder(),
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
              if (icon != null) ...[
                Icon(icon, size: 28),
                const SizedBox(width: 6),
              ],
              Text(label),
              if (trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(trailingIcon, size: 28),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MockStepPanel extends StatelessWidget {
  const _MockStepPanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _appointmentPrimary(context),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _appointmentPrimary(context),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

class _DateTimeMock extends StatelessWidget {
  const _DateTimeMock({
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
            times: _availableTimesForSelectedDate(),
            selectedTime: selectedTime,
            unavailableTimes: _unavailableTimesForSelectedDate(),
            availabilityStatus: availabilityStatus,
            onSelected: onSelected,
          ),
        ],
      ],
    );
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
          daysOfWeekHeight: 34,
          rowHeight: 78,
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
            onFocusedDateChanged(focused);
            onDaySelected(selected);
          },
          onPageChanged: onFocusedDateChanged,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: false,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: _appointmentPrimary(context),
              size: 30,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: _appointmentPrimary(context),
              size: 30,
            ),
            titleTextStyle: TextStyle(
              color: _WorkshopAppointmentPageState.ink,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
            headerPadding: EdgeInsets.only(bottom: 12),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: _appointmentPrimary(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            weekendStyle: TextStyle(
              color: _appointmentPrimary(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
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
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _CalendarLegend(
              color: _appointmentPrimary(context),
              label: l10n.appointmentSelectedDayLegend,
            ),
            _CalendarLegend(
              color: Color(0xFFD9DDE2),
              label: l10n.appointmentAvailableDayLegend,
            ),
            if (shouldBlockUnavailableDates)
              _CalendarLegend(
                color: Color(0xFFF2C6C6),
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
        ? const Color(0xFFFFE5E5)
        : selected
        ? _appointmentPrimary(context)
        : Colors.white;
    final textColor = selected
        ? Colors.white
        : disabled
        ? const Color(0xFFC96B6B)
        : outside
        ? AppColors.disabledBorder
        : day.weekday == DateTime.saturday || day.weekday == DateTime.sunday
        ? const Color(0xFFC96B6B)
        : AppColors.subtleText;

    return Container(
      alignment: Alignment.topRight,
      padding: const EdgeInsets.only(top: 12, right: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: disabled ? const Color(0xFFF2C6C6) : AppColors.calendarBorder,
          width: 0.7,
        ),
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 24, height: 24, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: _WorkshopAppointmentPageState.ink,
            fontSize: 16,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appointmentAvailableHoursTitle,
                  style: TextStyle(
                    color: _appointmentPrimary(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_up, color: Color(0xFF777777)),
            ],
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '${l10n.appointmentVehicleTypeCar.toUpperCase()}:',
              style: const TextStyle(
                color: _WorkshopAppointmentPageState.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (availabilityStatus == AppointmentLoadStatus.loading)
            _AvailabilityPanelMessage(
              icon: Icons.schedule_outlined,
              message: l10n.appointmentAvailableHoursLoading,
            )
          else if (availabilityStatus == AppointmentLoadStatus.failure)
            _AvailabilityPanelMessage(
              icon: Icons.error_outline,
              message: l10n.appointmentAvailableHoursFailed,
              color: _appointmentPrimary(context),
            )
          else if (times.isEmpty)
            _AvailabilityPanelMessage(
              icon: Icons.info_outline,
              message: l10n.appointmentAvailableHoursEmpty,
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: times.map((time) {
                final selected = selectedTime == time;
                final unavailable = unavailableTimes.contains(time);

                return SizedBox(
                  width: 60,
                  height: 40,
                  child: OutlinedButton(
                    onPressed: unavailable ? null : () => onSelected(time),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: unavailable
                          ? const Color(0xFFF1F1F1)
                          : selected
                          ? _appointmentPrimary(context)
                          : Colors.white,
                      foregroundColor: unavailable
                          ? AppColors.disabledIcon
                          : selected
                          ? Colors.white
                          : const Color(0xFF344050),
                      side: BorderSide(
                        color: unavailable
                            ? AppColors.disabledBorder
                            : selected
                            ? _appointmentPrimary(context)
                            : const Color(0xFF555555),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: Text(time),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
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
    final effectiveColor = color ?? AppColors.muted;

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

class _ContactInput extends StatelessWidget {
  const _ContactInput({
    required this.initialValue,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
  });

  final String initialValue;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final int minLines;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.border),
    );

    return TextFormField(
      key: ValueKey(label),
      initialValue: initialValue,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _appointmentPrimary(context), width: 2),
        ),
      ),
    );
  }
}

class _ConfirmationMock extends StatelessWidget {
  const _ConfirmationMock({
    required this.workshopName,
    required this.service,
    required this.licensePlate,
    required this.products,
    required this.date,
    required this.time,
    required this.paymentMethod,
    required this.onPaymentMethodSelected,
    required this.onNoteChanged,
    required this.note,
  });

  final String workshopName;
  final Product? service;
  final String licensePlate;
  final List<AppointmentSelectedProduct> products;
  final DateTime? date;
  final String time;
  final String paymentMethod;
  final ValueChanged<String> onPaymentMethodSelected;
  final ValueChanged<String> onNoteChanged;
  final String note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabel = date == null
        ? l10n.appointmentPendingDate
        : '${date!.day} de ${_monthName(date!.month)} ${date!.year}';
    final servicePrice = service?.sellingPrice ?? 0;
    final productsTotal = products.fold<double>(
      0,
      (total, item) =>
          total + ((item.product.sellingPrice ?? 0) * item.quantity),
    );
    final total = servicePrice + productsTotal;
    final hasPricelessItems =
        service?.sellingPrice == null ||
        products.any((item) => item.product.sellingPrice == null);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x15000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _appointmentPrimary(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.appointmentConfirmationReadyTitle,
                      style: const TextStyle(
                        color: _WorkshopAppointmentPageState.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
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
                trailing: formatProductPrice(service?.sellingPrice),
              ),
              _SummaryRow(
                label: l10n.appointmentDateLabel,
                value: '$dayLabel, $time',
              ),
              _SummaryRow(
                label: l10n.appointmentDurationLabel,
                value: _durationLabel(l10n, service?.estimatedDurationHours),
              ),
              _SummaryRow(
                label: l10n.appointmentPaymentMethodLabel,
                value: paymentMethod,
              ),
              const Divider(height: 28, color: AppColors.border),
              Text(
                l10n.appointmentStepPayment,
                style: const TextStyle(
                  color: _WorkshopAppointmentPageState.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _PaymentMethodStep(
                selectedMethod: paymentMethod,
                onSelected: onPaymentMethodSelected,
              ),
              const Divider(height: 28, color: AppColors.border),
              Text(
                l10n.appointmentOptionalNoteLabel,
                style: const TextStyle(
                  color: _WorkshopAppointmentPageState.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _ContactInput(
                initialValue: note,
                label: l10n.appointmentOptionalNoteLabel,
                icon: Icons.notes_outlined,
                minLines: 3,
                maxLines: 5,
                maxLength: 280,
                onChanged: onNoteChanged,
              ),
              const Divider(height: 28, color: AppColors.border),
              Text(
                l10n.appointmentProductsLabel,
                style: const TextStyle(
                  color: _WorkshopAppointmentPageState.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (products.isEmpty)
                Text(
                  l10n.appointmentNoAdditionalProducts,
                  style: const TextStyle(
                    color: _WorkshopAppointmentPageState.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ...products.map((item) => _ProductSummaryRow(item: item)),
              const Divider(height: 30, color: AppColors.border),
              _SummaryRow(
                label: l10n.appointmentTotalToPayLabel,
                value: hasPricelessItems
                    ? l10n.appointmentPriceToConfirm
                    : formatProductPrice(total),
                emphasize: true,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appointmentConfirmationDeliveryMessage,
                style: const TextStyle(
                  color: _WorkshopAppointmentPageState.muted,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return names[month - 1];
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
    this.trailing,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final String? trailing;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      color: emphasize
          ? _appointmentPrimary(context)
          : _WorkshopAppointmentPageState.ink,
      fontSize: emphasize ? 19 : 16,
      fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: _WorkshopAppointmentPageState.muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: valueStyle)),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Text(trailing!, style: valueStyle),
          ],
        ],
      ),
    );
  }
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
                  style: TextStyle(
                    color: _WorkshopAppointmentPageState.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatProductPrice(price)} x ${item.quantity}',
                  style: TextStyle(
                    color: _WorkshopAppointmentPageState.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            subtotal == null
                ? AppLocalizations.of(context)!.appointmentPriceToConfirm
                : formatProductPrice(subtotal),
            style: TextStyle(
              color: _WorkshopAppointmentPageState.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
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
    return SizedBox(
      width: large ? 260 : 220,
      height: large ? 118 : 92,
      child: ClipRect(
        child: Align(
          alignment: const Alignment(0, 0.48),
          widthFactor: 0.52,
          heightFactor: 0.3,
          child: Image.asset(
            'assets/images/virtual/Mesa de trabajo 11@2x.png',
            width: large ? 620 : 540,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _AppointmentStep {
  const _AppointmentStep(this.title, this.icon);

  final String title;
  final IconData icon;
}
