import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/presentation/widgets/product_price_text.dart';
import '../../domain/entities/workshop.dart';
import '../../domain/repositories/workshop_repository.dart';

class WorkshopAppointmentPage extends StatefulWidget {
  const WorkshopAppointmentPage({super.key, required this.workshopId});

  final String workshopId;

  @override
  State<WorkshopAppointmentPage> createState() =>
      _WorkshopAppointmentPageState();
}

class _WorkshopAppointmentPageState extends State<WorkshopAppointmentPage> {
  static const autolabRed = Color(0xFFFF281B);
  static const ink = Color(0xFF171717);
  static const muted = Color(0xFF7B828C);
  final _customerFormKey = GlobalKey<FormState>();
  Workshop? _workshop;

  final List<_AppointmentStep> _steps = const [
    _AppointmentStep('Seleccionar tipo de vehiculo', Icons.directions_car),
    _AppointmentStep('Taller seleccionado', Icons.storefront_outlined),
    _AppointmentStep('Seleccionar servicio', Icons.build_circle_outlined),
    _AppointmentStep('Productos adicionales', Icons.inventory_2_outlined),
    _AppointmentStep('Seleccionar dia y hora', Icons.event_outlined),
    _AppointmentStep('Informacion del cliente', Icons.person_outline),
    _AppointmentStep('Confirmacion', Icons.check_circle_outline),
    _AppointmentStep('Metodo de pago', Icons.credit_card_outlined),
  ];

  final List<_VehicleType> _vehicleTypes = const [
    _VehicleType('AUTOMOVIL', Icons.directions_car_filled_outlined),
    _VehicleType('MOTOCICLETA / CUADRACICLO', Icons.two_wheeler_outlined),
    _VehicleType('CARGA LIVIANA', Icons.local_shipping_outlined),
    _VehicleType('TAXI', Icons.local_taxi_outlined),
    _VehicleType('CARGA PESADA', Icons.fire_truck_outlined),
    _VehicleType('AUTOBUS-MICROBUS', Icons.directions_bus_outlined),
    _VehicleType(
      'Equipos Especiales',
      Icons.agriculture_outlined,
      subtitle: 'No transitan por vias publicas',
    ),
    _VehicleType('REMOLQUE-SEMIREMOLQUE', Icons.rv_hookup_outlined),
    _VehicleType(
      'AUTOBUS-MICROBUS TRANSPORTE PUBLICO',
      Icons.airport_shuttle_outlined,
    ),
  ];

  int _currentStep = 0;
  String? _selectedVehicle = 'AUTOMOVIL';
  Product? _selectedService;
  bool _includeProducts = false;
  final List<_SelectedProduct> _selectedProducts = [];
  DateTime? _selectedDate;
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadWorkshop();
  }

  Future<void> _loadWorkshop() async {
    final result = await sl<WorkshopRepository>().getWorkshopById(
      widget.workshopId,
    );

    if (!mounted) {
      return;
    }

    result.fold((_) {}, (workshop) => setState(() => _workshop = workshop));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  SizedBox(
                    width: 430,
                    child: _DesktopRail(
                      steps: _steps,
                      currentStep: _currentStep,
                      workshopName: _workshopName,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _pageBody(isDesktop: true)),
                ],
              )
            : Column(
                children: [
                  _MobileHeader(
                    steps: _steps,
                    currentStep: _currentStep,
                    onBack: _handleBack,
                  ),
                  Expanded(child: _pageBody(isDesktop: false)),
                ],
              ),
      ),
    );
  }

  Widget _pageBody({required bool isDesktop}) {
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
                child: _buildStepContent(isDesktop),
              ),
            ),
          ),
        ),
        _FooterActions(
          canGoBack: _currentStep > 0,
          isLastStep: _currentStep == _steps.length - 1,
          isPaymentEntryStep: _currentStep == _steps.length - 2,
          onBack: _goBackStep,
          onNext: _goNextStep,
        ),
      ],
    );
  }

  Widget _buildStepContent(bool isDesktop) {
    switch (_currentStep) {
      case 0:
        return _VehicleStep(
          title: _steps[_currentStep].title,
          vehicles: _vehicleTypes,
          selectedVehicle: _selectedVehicle,
          onSelected: (vehicle) => setState(() => _selectedVehicle = vehicle),
          isDesktop: isDesktop,
        );
      case 1:
        return _MockStepPanel(
          icon: Icons.storefront_outlined,
          title: _steps[_currentStep].title,
          child: _WorkshopSelectedCard(
            workshopName: _workshopName,
            workshopAddress: _workshopAddress,
            workshopPhone: _workshopPhone,
            workshopAvatarUrl: _workshopAvatarUrl,
          ),
        );
      case 2:
        return _MockStepPanel(
          icon: Icons.build_circle_outlined,
          title: _steps[_currentStep].title,
          child: _ServiceSelectionStep(
            workshopId: widget.workshopId,
            selectedService: _selectedService,
            onSelected: (service) => setState(() {
              _selectedService = service;
              _includeProducts = false;
              _selectedProducts.clear();
              _selectedDate = null;
              _selectedTime = null;
            }),
          ),
        );
      case 3:
        return _MockStepPanel(
          icon: Icons.inventory_2_outlined,
          title: _steps[_currentStep].title,
          child: _ProductsSelectionStep(
            workshopId: widget.workshopId,
            includeProducts: _includeProducts,
            selectedProducts: _selectedProducts,
            onIncludeChanged: (value) => setState(() {
              _includeProducts = value;
              if (!value) {
                _selectedProducts.clear();
              }
            }),
            onProductToggled: _toggleSelectedProduct,
            onQuantityChanged: _changeProductQuantity,
          ),
        );
      case 4:
        return _MockStepPanel(
          icon: Icons.event_outlined,
          title: _steps[_currentStep].title,
          child: _DateTimeMock(
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            onDaySelected: (date) => setState(() {
              _selectedDate = isSameDay(_selectedDate, date) ? null : date;
              _selectedTime = null;
            }),
            onSelected: (time) => setState(() => _selectedTime = time),
          ),
        );
      case 5:
        return _MockStepPanel(
          icon: Icons.person_outline,
          title: _steps[_currentStep].title,
          child: _CustomerInfoMock(formKey: _customerFormKey),
        );
      case 6:
        return _MockStepPanel(
          icon: Icons.check_circle_outline,
          title: _steps[_currentStep].title,
          child: _ConfirmationMock(
            workshopName: _workshopName,
            service: _selectedService,
            vehicle: _selectedVehicle,
            products: _selectedProducts,
            date: _selectedDate,
            time: _selectedTime ?? '9:00 AM',
          ),
        );
      default:
        return _MockStepPanel(
          icon: Icons.credit_card_outlined,
          title: _steps[_currentStep].title,
          child: const _PaymentMethodStep(),
        );
    }
  }

  String get _workshopName {
    final name = _workshop?.name.trim();
    return name == null || name.isEmpty ? 'Taller Autolab' : name;
  }

  String get _workshopAddress {
    final address = _workshop?.locationAddress.trim();
    return address == null || address.isEmpty
        ? 'Direccion no registrada'
        : address;
  }

  String get _workshopPhone {
    final phone = _workshop?.phone.trim();
    return phone == null || phone.isEmpty ? 'Telefono no registrado' : phone;
  }

  String get _workshopAvatarUrl => _workshop?.avatarUrl.trim() ?? '';

  void _handleBack() {
    if (_currentStep == 0) {
      context.pop();
      return;
    }

    _goBackStep();
  }

  void _goBackStep() {
    if (_currentStep == 0) {
      return;
    }

    setState(() => _currentStep--);
  }

  void _goNextStep() {
    final l10n = AppLocalizations.of(context)!;

    if (_currentStep == _steps.length - 1) {
      context.pop();
      return;
    }

    if (_currentStep == 2 && _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.appointmentSelectServiceRequired)),
      );
      return;
    }

    if (_currentStep == 4 && (_selectedDate == null || _selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.appointmentSelectDateTimeRequired)),
      );
      return;
    }

    if (_currentStep == 5 &&
        !(_customerFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _currentStep++);
  }

  void _toggleSelectedProduct(Product product) {
    setState(() {
      final existingIndex = _selectedProducts.indexWhere(
        (selected) => selected.product.id == product.id,
      );

      if (existingIndex >= 0) {
        _selectedProducts.removeAt(existingIndex);
        return;
      }

      _selectedProducts.add(_SelectedProduct(product: product));
    });
  }

  void _changeProductQuantity(Product product, int delta) {
    setState(() {
      final existingIndex = _selectedProducts.indexWhere(
        (selected) => selected.product.id == product.id,
      );

      if (existingIndex < 0) {
        if (delta > 0) {
          _selectedProducts.add(_SelectedProduct(product: product));
        }
        return;
      }

      final selected = _selectedProducts[existingIndex];
      final nextQuantity = selected.quantity + delta;

      if (nextQuantity <= 0) {
        _selectedProducts.removeAt(existingIndex);
        return;
      }

      _selectedProducts[existingIndex] = selected.copyWith(
        quantity: nextQuantity,
      );
    });
  }
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
          const Text(
            'Taller seleccionado',
            style: TextStyle(
              color: _WorkshopAppointmentPageState.autolabRed,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            workshopName,
            style: const TextStyle(
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
        ? _WorkshopAppointmentPageState.autolabRed
        : const Color(0xFFB8BBC0);
    final titleColor = active || done
        ? _WorkshopAppointmentPageState.autolabRed
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
              Container(width: 1, height: 48, color: const Color(0xFFE0E0E0)),
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
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
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
                          ? _WorkshopAppointmentPageState.autolabRed
                          : const Color(0xFFE0E0E0),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    active
                        ? '${index + 1} ${steps[index].title}'
                        : '${index + 1}',
                    style: TextStyle(
                      color: active
                          ? _WorkshopAppointmentPageState.autolabRed
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
          style: const TextStyle(
            color: _WorkshopAppointmentPageState.autolabRed,
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
      color: selected ? const Color(0xFFFFF1F0) : Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? _WorkshopAppointmentPageState.autolabRed
                  : const Color(0xFFE5E5E5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: _WorkshopAppointmentPageState.autolabRed,
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
                      style: const TextStyle(
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
                        style: const TextStyle(
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
    required this.workshopId,
    required this.selectedService,
    required this.onSelected,
  });

  final String workshopId;
  final Product? selectedService;
  final ValueChanged<Product> onSelected;

  @override
  State<_ServiceSelectionStep> createState() => _ServiceSelectionStepState();
}

class _ServiceSelectionStepState extends State<_ServiceSelectionStep> {
  late final Future<List<Product>> _servicesFuture = _loadServices();

  Future<List<Product>> _loadServices() async {
    final result = await sl<ProductRepository>().getActiveProductsByWorkshop(
      widget.workshopId,
    );

    return result.fold((_) => const <Product>[], (products) {
      return products.where(_isSchedulableService).toList();
    });
  }

  bool _isSchedulableService(Product product) {
    return product.itemType.trim().toLowerCase() == 'service' &&
        product.isSchedulable &&
        product.requiresAppointment;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final services = snapshot.data ?? const <Product>[];

        if (services.isEmpty) {
          return const _EmptyServicesMessage();
        }

        return Column(
          children: services.map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServiceCard(
                service: service,
                selected: widget.selectedService?.id == service.id,
                onTap: () => widget.onSelected(service),
              ),
            );
          }).toList(),
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
      color: selected ? const Color(0xFFFFF1F0) : Colors.white,
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
                  ? _WorkshopAppointmentPageState.autolabRed
                  : const Color(0xFFE5E5E5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: _WorkshopAppointmentPageState.autolabRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
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
                      style: const TextStyle(
                        color: _WorkshopAppointmentPageState.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.effectiveDescription,
                      style: const TextStyle(
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
          Icon(icon, size: 16, color: _WorkshopAppointmentPageState.autolabRed),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
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
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _WorkshopAppointmentPageState.autolabRed,
          ),
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
    required this.workshopId,
    required this.includeProducts,
    required this.selectedProducts,
    required this.onIncludeChanged,
    required this.onProductToggled,
    required this.onQuantityChanged,
  });

  final String workshopId;
  final bool includeProducts;
  final List<_SelectedProduct> selectedProducts;
  final ValueChanged<bool> onIncludeChanged;
  final ValueChanged<Product> onProductToggled;
  final void Function(Product product, int delta) onQuantityChanged;

  @override
  State<_ProductsSelectionStep> createState() => _ProductsSelectionStepState();
}

class _ProductsSelectionStepState extends State<_ProductsSelectionStep> {
  late final Future<List<Product>> _productsFuture = _loadProducts();

  Future<List<Product>> _loadProducts() async {
    final result = await sl<ProductRepository>().getActiveProductsByWorkshop(
      widget.workshopId,
    );

    return result.fold((_) => const <Product>[], (products) {
      return products.where(_isAdditionalProduct).toList();
    });
  }

  bool _isAdditionalProduct(Product product) {
    return product.itemType.trim().toLowerCase() != 'service';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E5E5)),
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
              const Expanded(
                child: Text(
                  'Necesito productos para este servicio',
                  style: TextStyle(
                    color: _WorkshopAppointmentPageState.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(
                value: widget.includeProducts,
                activeThumbColor: _WorkshopAppointmentPageState.autolabRed,
                onChanged: widget.onIncludeChanged,
              ),
            ],
          ),
        ),
        if (!widget.includeProducts) ...[
          const SizedBox(height: 16),
          const _ProductsInfoMessage(
            message: 'Puedes continuar sin agregar productos.',
          ),
        ] else ...[
          const SizedBox(height: 18),
          FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final products = snapshot.data ?? const <Product>[];

              if (products.isEmpty) {
                return const _ProductsInfoMessage(
                  message:
                      'Este taller no tiene productos adicionales disponibles.',
                );
              }

              return Column(
                children: products.map((product) {
                  _SelectedProduct? selectedProduct;
                  for (final item in widget.selectedProducts) {
                    if (item.product.id == product.id) {
                      selectedProduct = item;
                      break;
                    }
                  }
                  final selected = selectedProduct != null;
                  final quantity = selectedProduct?.quantity ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProductOptionCard(
                      product: product,
                      selected: selected,
                      quantity: quantity,
                      onTap: () => widget.onProductToggled(product),
                      onQuantityChanged: (delta) =>
                          widget.onQuantityChanged(product, delta),
                    ),
                  );
                }).toList(),
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
      color: selected ? const Color(0xFFFFF1F0) : Colors.white,
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
                  ? _WorkshopAppointmentPageState.autolabRed
                  : const Color(0xFFE5E5E5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: _WorkshopAppointmentPageState.autolabRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
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
                      style: const TextStyle(
                        color: _WorkshopAppointmentPageState.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.effectiveDescription,
                      style: const TextStyle(
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
                  color: const Color(0xFF9AA0A6),
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
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _WorkshopAppointmentPageState.autolabRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
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
              style: const TextStyle(
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
        child: Icon(
          icon,
          size: 20,
          color: _WorkshopAppointmentPageState.autolabRed,
        ),
      ),
    );
  }
}

class _PaymentMethodStep extends StatefulWidget {
  const _PaymentMethodStep();

  @override
  State<_PaymentMethodStep> createState() => _PaymentMethodStepState();
}

class _PaymentMethodStepState extends State<_PaymentMethodStep> {
  String _selectedMethod = 'Tarjeta';

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
        final selected = _selectedMethod == method.title;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PaymentMethodCard(
            option: method,
            selected: selected,
            onTap: () => setState(() => _selectedMethod = method.title),
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
      color: selected ? const Color(0xFFFFF1F0) : Colors.white,
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
                  ? _WorkshopAppointmentPageState.autolabRed
                  : const Color(0xFFE5E5E5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: _WorkshopAppointmentPageState.autolabRed,
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
                      style: const TextStyle(
                        color: _WorkshopAppointmentPageState.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.subtitle,
                      style: const TextStyle(
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
                    ? _WorkshopAppointmentPageState.autolabRed
                    : const Color(0xFF9AA0A6),
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
          foregroundColor: const Color(0xFF3F4752),
          side: const BorderSide(color: Color(0xFF555555)),
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
              decoration: const BoxDecoration(
                color: _WorkshopAppointmentPageState.autolabRed,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _WorkshopAppointmentPageState.autolabRed,
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
        border: Border.all(color: const Color(0xFFE5E5E5)),
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
                  style: const TextStyle(
                    color: _WorkshopAppointmentPageState.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  workshopAddress,
                  style: const TextStyle(
                    color: _WorkshopAppointmentPageState.muted,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      color: _WorkshopAppointmentPageState.autolabRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        workshopPhone,
                        style: const TextStyle(
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
      backgroundColor: const Color(0xFFFFE7E5),
      backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
      child: imageUrl.isEmpty
          ? const Icon(
              Icons.storefront_outlined,
              color: _WorkshopAppointmentPageState.autolabRed,
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
    required this.onDaySelected,
    required this.onSelected,
  });

  final DateTime? selectedDate;
  final String? selectedTime;
  final ValueChanged<DateTime> onDaySelected;
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
          onDaySelected: onDaySelected,
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

class _AppointmentCalendar extends StatefulWidget {
  const _AppointmentCalendar({
    required this.selectedDate,
    required this.onDaySelected,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<_AppointmentCalendar> createState() => _AppointmentCalendarState();
}

class _AppointmentCalendarState extends State<_AppointmentCalendar> {
  static final _firstDay = DateTime.utc(2020, 1, 1);
  static final _lastDay = DateTime.utc(2035, 12, 31);
  late DateTime _focusedDay = widget.selectedDate ?? DateTime.utc(2026, 5, 1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar<void>(
          firstDay: _firstDay,
          lastDay: _lastDay,
          focusedDay: _focusedDay,
          locale: 'es',
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableGestures: AvailableGestures.none,
          daysOfWeekHeight: 34,
          rowHeight: 78,
          selectedDayPredicate: (day) =>
              widget.selectedDate != null &&
              isSameDay(day, widget.selectedDate),
          onDaySelected: (selected, focused) {
            setState(() => _focusedDay = focused);
            widget.onDaySelected(selected);
          },
          onPageChanged: (focused) {
            setState(() => _focusedDay = focused);
          },
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: false,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: _WorkshopAppointmentPageState.autolabRed,
              size: 30,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: _WorkshopAppointmentPageState.autolabRed,
              size: 30,
            ),
            titleTextStyle: TextStyle(
              color: _WorkshopAppointmentPageState.ink,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
            headerPadding: EdgeInsets.only(bottom: 12),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: _WorkshopAppointmentPageState.autolabRed,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            weekendStyle: TextStyle(
              color: _WorkshopAppointmentPageState.autolabRed,
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
        const Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _CalendarLegend(
              color: _WorkshopAppointmentPageState.autolabRed,
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
        ? _WorkshopAppointmentPageState.autolabRed
        : Colors.white;
    final textColor = selected
        ? Colors.white
        : outside
        ? const Color(0xFFE4E4E4)
        : day.weekday == DateTime.saturday || day.weekday == DateTime.sunday
        ? const Color(0xFFC96B6B)
        : const Color(0xFF8C8C8C);

    return Container(
      alignment: Alignment.topRight,
      padding: const EdgeInsets.only(top: 12, right: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: const Color(0xFFE3E3E3), width: 0.7),
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
          style: const TextStyle(
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
        border: Border.all(color: const Color(0xFFE5E5E5)),
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
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Horas disponibles',
                  style: TextStyle(
                    color: _WorkshopAppointmentPageState.autolabRed,
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
                        ? _WorkshopAppointmentPageState.autolabRed
                        : Colors.white,
                    foregroundColor: selected
                        ? Colors.white
                        : const Color(0xFF344050),
                    side: BorderSide(
                      color: selected
                          ? _WorkshopAppointmentPageState.autolabRed
                          : const Color(0xFF555555),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    textStyle: const TextStyle(
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
  final List<_SelectedProduct> products;
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
            border: Border.all(color: const Color(0xFFE5E5E5)),
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
                    decoration: const BoxDecoration(
                      color: _WorkshopAppointmentPageState.autolabRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
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
              const Divider(height: 28, color: Color(0xFFE5E5E5)),
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
              const Divider(height: 30, color: Color(0xFFE5E5E5)),
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
          ? _WorkshopAppointmentPageState.autolabRed
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
              style: const TextStyle(
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

  final _SelectedProduct item;

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
                  style: const TextStyle(
                    color: _WorkshopAppointmentPageState.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatProductPrice(price)} x ${item.quantity}',
                  style: const TextStyle(
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
            style: const TextStyle(
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
      style: const TextStyle(
        color: _WorkshopAppointmentPageState.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _WorkshopAppointmentPageState.ink),
        floatingLabelStyle: const TextStyle(
          color: _WorkshopAppointmentPageState.ink,
        ),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: _WorkshopAppointmentPageState.autolabRed,
            width: 1.4,
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5E5E5)),
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

class _SelectedProduct {
  const _SelectedProduct({required this.product, this.quantity = 1});

  final Product product;
  final int quantity;

  _SelectedProduct copyWith({int? quantity}) {
    return _SelectedProduct(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class _VehicleType {
  const _VehicleType(this.title, this.icon, {this.subtitle});

  final String title;
  final IconData icon;
  final String? subtitle;
}
