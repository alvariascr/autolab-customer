import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/widgets/product_price_text.dart';
import '../../application/appointment_cubit.dart';
import '../../application/appointment_state.dart';

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
  final _customerFormKey = GlobalKey<FormState>();

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
              isDesktop ? 96 : 28,
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
          isPaymentEntryStep: state.currentStep == steps.length - 2,
          onBack: () => context.read<AppointmentCubit>().goBack(),
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
    final l10n = AppLocalizations.of(context)!;

    switch (state.currentStep) {
      case 0:
        return _VehicleStep(
          title: steps[state.currentStep].title,
          vehicles: _vehicleTypes(l10n),
          selectedVehicle: state.selectedVehicle,
          onSelected: context.read<AppointmentCubit>().selectVehicle,
          isDesktop: isDesktop,
        );
      case 1:
        return _MockStepPanel(
          icon: Icons.storefront_outlined,
          title: steps[state.currentStep].title,
          child: _WorkshopSelectedCard(
            workshopName: _workshopName(state),
            workshopAddress: _workshopAddress(state),
            workshopPhone: _workshopPhone(state),
            workshopAvatarUrl: _workshopAvatarUrl(state),
          ),
        );
      case 2:
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
      case 3:
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
      case 4:
        return _MockStepPanel(
          icon: Icons.event_outlined,
          title: steps[state.currentStep].title,
          child: _DateTimeMock(
            selectedDate: state.selectedDate,
            selectedTime: state.selectedTime,
            focusedDate: state.focusedDate ?? DateTime.utc(2026, 5, 1),
            onDaySelected: context.read<AppointmentCubit>().selectDate,
            onFocusedDateChanged: context.read<AppointmentCubit>().focusDate,
            onSelected: context.read<AppointmentCubit>().selectTime,
          ),
        );
      case 5:
        return _MockStepPanel(
          icon: Icons.person_outline,
          title: steps[state.currentStep].title,
          child: _CustomerInfoMock(formKey: _customerFormKey),
        );
      case 6:
        return _MockStepPanel(
          icon: Icons.check_circle_outline,
          title: steps[state.currentStep].title,
          child: _ConfirmationMock(
            workshopName: _workshopName(state),
            service: state.selectedService,
            vehicle: state.selectedVehicle,
            products: state.selectedProducts,
            date: state.selectedDate,
            time: state.selectedTime ?? '9:00 AM',
          ),
        );
      default:
        return _MockStepPanel(
          icon: Icons.credit_card_outlined,
          title: steps[state.currentStep].title,
          child: _PaymentMethodStep(
            selectedMethod: state.selectedPaymentMethod,
            onSelected: context.read<AppointmentCubit>().selectPaymentMethod,
          ),
        );
    }
  }

  String _workshopName(AppointmentState state) {
    final name = state.workshop?.name.trim();
    return name == null || name.isEmpty ? 'Taller Autolab' : name;
  }

  String _workshopAddress(AppointmentState state) {
    final address = state.workshop?.locationAddress.trim();
    return address == null || address.isEmpty
        ? 'Direccion no registrada'
        : address;
  }

  String _workshopPhone(AppointmentState state) {
    final phone = state.workshop?.phone.trim();
    return phone == null || phone.isEmpty ? 'Telefono no registrado' : phone;
  }

  String _workshopAvatarUrl(AppointmentState state) {
    return state.workshop?.avatarUrl.trim() ?? '';
  }

  void _handleBack(BuildContext context, AppointmentState state) {
    if (state.currentStep == 0) {
      context.pop();
      return;
    }

    context.read<AppointmentCubit>().goBack();
  }

  void _goNextStep(
    BuildContext context,
    AppointmentState state,
    int stepCount,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (state.currentStep == stepCount - 1) {
      context.pop();
      return;
    }

    if (state.currentStep == 2 && state.selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.appointmentSelectServiceRequired)),
      );
      return;
    }

    if (state.currentStep == 4 &&
        (state.selectedDate == null || state.selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.appointmentSelectDateTimeRequired)),
      );
      return;
    }

    if (state.currentStep == 5 &&
        !(_customerFormKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<AppointmentCubit>().goNext();
  }
}

List<_AppointmentStep> _appointmentSteps(AppLocalizations l10n) {
  return [
    _AppointmentStep(l10n.appointmentStepVehicle, Icons.directions_car),
    _AppointmentStep(l10n.appointmentStepWorkshop, Icons.storefront_outlined),
    _AppointmentStep(l10n.appointmentStepService, Icons.build_circle_outlined),
    _AppointmentStep(l10n.appointmentStepProducts, Icons.inventory_2_outlined),
    _AppointmentStep(l10n.appointmentStepDateTime, Icons.event_outlined),
    _AppointmentStep(l10n.appointmentStepCustomerInfo, Icons.person_outline),
    _AppointmentStep(
      l10n.appointmentStepConfirmation,
      Icons.check_circle_outline,
    ),
    _AppointmentStep(l10n.appointmentStepPayment, Icons.credit_card_outlined),
  ];
}

List<_VehicleType> _vehicleTypes(AppLocalizations l10n) {
  return [
    _VehicleType(
      l10n.appointmentVehicleCar,
      Icons.directions_car_filled_outlined,
    ),
    _VehicleType(l10n.appointmentVehicleMotorcycle, Icons.two_wheeler_outlined),
    _VehicleType(
      l10n.appointmentVehicleLightLoad,
      Icons.local_shipping_outlined,
    ),
    _VehicleType(l10n.appointmentVehicleTaxi, Icons.local_taxi_outlined),
    _VehicleType(l10n.appointmentVehicleHeavyLoad, Icons.fire_truck_outlined),
    _VehicleType(l10n.appointmentVehicleBus, Icons.directions_bus_outlined),
    _VehicleType(
      l10n.appointmentVehicleSpecialEquipment,
      Icons.agriculture_outlined,
      subtitle: l10n.appointmentVehicleSpecialEquipmentSubtitle,
    ),
    _VehicleType(l10n.appointmentVehicleTrailer, Icons.rv_hookup_outlined),
    _VehicleType(
      l10n.appointmentVehiclePublicTransport,
      Icons.airport_shuttle_outlined,
    ),
  ];
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
          const Text(
            'Servicio y mantenimiento automotriz',
            style: TextStyle(color: _WorkshopAppointmentPageState.muted),
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

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.steps,
    required this.currentStep,
    required this.onBack,
  });

  final List<_AppointmentStep> steps;
  final int currentStep;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                const _AutolabLogo(),
              ],
            ),
          ),
          Container(
            height: 92,
            color: const Color(0xFFF6F6F6),
            alignment: Alignment.centerLeft,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 20),
              scrollDirection: Axis.horizontal,
              itemCount: steps.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final active = index == currentStep;

                return AnimatedContainer(
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
                  child: Text(
                    active
                        ? '${index + 1} ${steps[index].title}'
                        : '${index + 1}',
                    style: TextStyle(
                      color: active
                          ? _appointmentPrimary(context)
                          : _WorkshopAppointmentPageState.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleStep extends StatelessWidget {
  const _VehicleStep({
    required this.title,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onSelected,
    required this.isDesktop,
  });

  final String title;
  final List<_VehicleType> vehicles;
  final String? selectedVehicle;
  final ValueChanged<String> onSelected;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _appointmentPrimary(context),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vehicles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 1,
            mainAxisExtent: isDesktop ? 64 : 94,
            mainAxisSpacing: isDesktop ? 6 : 10,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];

            return _VehicleCard(
              vehicle: vehicle,
              selected: selectedVehicle == vehicle.title,
              onTap: () => onSelected(vehicle.title),
            );
          },
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final _VehicleType vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.appointmentSelectedBackground : Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? _appointmentPrimary(context) : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _appointmentPrimary(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(vehicle.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _WorkshopAppointmentPageState.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (vehicle.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        vehicle.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _WorkshopAppointmentPageState.muted,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
              'Este taller no tiene servicios disponibles para agendar.',
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

  static const _methods = [
    _PaymentMethodOption(
      title: 'Tarjeta',
      subtitle: 'Pago con tarjeta de credito o debito.',
      icon: Icons.credit_card_outlined,
    ),
    _PaymentMethodOption(
      title: 'SINPE Movil',
      subtitle: 'Recibiras las instrucciones para completar el pago.',
      icon: Icons.phone_android_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _methods.map((method) {
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
    required this.isPaymentEntryStep,
    required this.onBack,
    required this.onNext,
  });

  final bool canGoBack;
  final bool isLastStep;
  final bool isPaymentEntryStep;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
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
                    icon: canGoBack ? Icons.chevron_left : Icons.add,
                    label: canGoBack ? 'ANTERIOR' : 'NUEVO SERVICIO',
                    onPressed: canGoBack ? onBack : () {},
                  ),
                ),
                Expanded(
                  child: _OutlineActionButton(
                    trailingIcon: isLastStep
                        ? Icons.check_rounded
                        : Icons.chevron_right,
                    label: isLastStep
                        ? 'FINALIZAR'
                        : isPaymentEntryStep
                        ? 'PAGAR'
                        : 'SIGUIENTE',
                    onPressed: onNext,
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
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final IconData? trailingIcon;

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

class _WorkshopSelectedCard extends StatelessWidget {
  const _WorkshopSelectedCard({
    required this.workshopName,
    required this.workshopAddress,
    required this.workshopPhone,
    required this.workshopAvatarUrl,
  });

  final String workshopName;
  final String workshopAddress;
  final String workshopPhone;
  final String workshopAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkshopAvatar(imageUrl: workshopAvatarUrl),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workshopName,
                  style: TextStyle(
                    color: _WorkshopAppointmentPageState.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  workshopAddress,
                  style: TextStyle(
                    color: _WorkshopAppointmentPageState.muted,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      color: _appointmentPrimary(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        workshopPhone,
                        style: TextStyle(
                          color: _WorkshopAppointmentPageState.ink,
                          fontSize: 16,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopAvatar extends StatelessWidget {
  const _WorkshopAvatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 29,
      backgroundColor: AppColors.appointmentSoftRedBackground,
      backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
      child: imageUrl.isEmpty
          ? Icon(
              Icons.storefront_outlined,
              color: _appointmentPrimary(context),
              size: 30,
            )
          : null,
    );
  }
}

class _DateTimeMock extends StatelessWidget {
  const _DateTimeMock({
    required this.selectedDate,
    required this.selectedTime,
    required this.focusedDate,
    required this.onDaySelected,
    required this.onFocusedDateChanged,
    required this.onSelected,
  });

  final DateTime? selectedDate;
  final String? selectedTime;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onFocusedDateChanged;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const times = [
      '06:10',
      '06:15',
      '06:20',
      '06:35',
      '06:40',
      '06:45',
      '07:10',
      '07:15',
      '07:20',
      '07:25',
      '08:05',
      '08:10',
      '08:15',
      '08:20',
      '08:50',
      '09:10',
      '09:15',
      '09:20',
      '10:45',
      '11:10',
      '11:20',
      '11:25',
      '11:40',
      '11:45',
      '11:50',
      '11:55',
      '12:00',
      '12:05',
      '12:15',
      '12:20',
      '12:25',
      '12:30',
      '12:35',
      '12:40',
      '12:45',
      '12:50',
      '12:55',
      '13:10',
      '13:15',
      '13:20',
      '13:25',
      '13:35',
      '13:40',
      '13:45',
      '13:50',
      '14:10',
      '14:15',
      '14:20',
      '14:25',
      '14:35',
      '14:40',
      '14:45',
      '14:50',
      '15:05',
      '15:10',
      '15:15',
      '15:25',
      '15:35',
      '15:45',
      '15:50',
      '15:55',
      '16:05',
      '16:10',
      '16:15',
      '16:20',
      '16:50',
      '16:55',
      '17:00',
      '17:05',
      '17:10',
      '17:15',
      '17:50',
      '17:55',
      '18:20',
      '18:25',
      '19:10',
      '19:40',
      '20:00',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppointmentCalendar(
          selectedDate: selectedDate,
          focusedDate: focusedDate,
          onDaySelected: onDaySelected,
          onFocusedDateChanged: onFocusedDateChanged,
        ),
        if (selectedDate != null) ...[
          const SizedBox(height: 24),
          _AvailableHoursPanel(
            times: times,
            selectedTime: selectedTime,
            onSelected: onSelected,
          ),
        ],
      ],
    );
  }
}

class _AppointmentCalendar extends StatelessWidget {
  const _AppointmentCalendar({
    required this.selectedDate,
    required this.focusedDate,
    required this.onDaySelected,
    required this.onFocusedDateChanged,
  });

  final DateTime? selectedDate;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onFocusedDateChanged;

  static final _firstDay = DateTime.utc(2020, 1, 1);
  static final _lastDay = DateTime.utc(2035, 12, 31);

  @override
  Widget build(BuildContext context) {
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
              return _TableCalendarDay(day: day);
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
              label: 'Dia seleccionado',
            ),
            _CalendarLegend(color: Color(0xFFD9DDE2), label: 'Dia disponible'),
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
  });

  final DateTime day;
  final bool selected;
  final bool outside;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? _appointmentPrimary(context)
        : Colors.white;
    final textColor = selected
        ? Colors.white
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
        border: Border.all(color: AppColors.calendarBorder, width: 0.7),
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
    required this.onSelected,
  });

  final List<String> times;
  final String? selectedTime;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
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
                  'Horas disponibles',
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
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'AUTOMOVIL:',
              style: TextStyle(
                color: _WorkshopAppointmentPageState.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: times.map((time) {
              final selected = selectedTime == time;

              return SizedBox(
                width: 60,
                height: 40,
                child: OutlinedButton(
                  onPressed: () => onSelected(time),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: selected
                        ? _appointmentPrimary(context)
                        : Colors.white,
                    foregroundColor: selected
                        ? Colors.white
                        : const Color(0xFF344050),
                    side: BorderSide(
                      color: selected
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

class _CustomerInfoMock extends StatelessWidget {
  const _CustomerInfoMock({required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: formKey,
      child: Column(
        children: [
          _MockInput(
            label: 'Nombre completo',
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return l10n.validationNameRequired;
              }
              if (text.length < 3) {
                return l10n.validationNameTooShort;
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _MockInput(
            label: 'Telefono',
            keyboardType: TextInputType.phone,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return l10n.validationPhoneRequired;
              }
              if (text.replaceAll(RegExp(r'\D'), '').length < 8) {
                return l10n.validationPhoneInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _MockInput(
            label: 'Correo electronico',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return l10n.validationEmailRequired;
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                return l10n.validationEmailInvalid;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _ConfirmationMock extends StatelessWidget {
  const _ConfirmationMock({
    required this.workshopName,
    required this.service,
    required this.vehicle,
    required this.products,
    required this.date,
    required this.time,
  });

  final String workshopName;
  final Product? service;
  final String? vehicle;
  final List<AppointmentSelectedProduct> products;
  final DateTime? date;
  final String time;

  @override
  Widget build(BuildContext context) {
    final dayLabel = date == null
        ? 'fecha pendiente'
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
                  const Expanded(
                    child: Text(
                      'Cita lista para confirmar',
                      style: TextStyle(
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
                label: 'Vehiculo',
                value: vehicle ?? 'Vehiculo pendiente',
              ),
              _SummaryRow(label: 'Taller', value: workshopName),
              _SummaryRow(
                label: 'Servicio',
                value: service?.name ?? 'Servicio pendiente',
                trailing: formatProductPrice(service?.sellingPrice),
              ),
              _SummaryRow(label: 'Fecha', value: '$dayLabel, $time'),
              const Divider(height: 28, color: AppColors.border),
              const Text(
                'Productos',
                style: TextStyle(
                  color: _WorkshopAppointmentPageState.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (products.isEmpty)
                const Text(
                  'Sin productos adicionales.',
                  style: TextStyle(
                    color: _WorkshopAppointmentPageState.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ...products.map((item) => _ProductSummaryRow(item: item)),
              const Divider(height: 30, color: AppColors.border),
              _SummaryRow(
                label: 'Total a pagar',
                value: hasPricelessItems
                    ? 'Por confirmar'
                    : formatProductPrice(total),
                emphasize: true,
              ),
              const SizedBox(height: 12),
              const Text(
                'Recibiras los detalles por correo o WhatsApp.',
                style: TextStyle(
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
            subtotal == null ? 'Por confirmar' : formatProductPrice(subtotal),
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

class _MockInput extends StatelessWidget {
  const _MockInput({required this.label, this.keyboardType, this.validator});

  final String label;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        color: _WorkshopAppointmentPageState.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _WorkshopAppointmentPageState.ink),
        floatingLabelStyle: TextStyle(color: _WorkshopAppointmentPageState.ink),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: _appointmentPrimary(context),
            width: 1.4,
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
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

class _VehicleType {
  const _VehicleType(this.title, this.icon, {this.subtitle});

  final String title;
  final IconData icon;
  final String? subtitle;
}
