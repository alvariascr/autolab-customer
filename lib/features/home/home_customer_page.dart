import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/app_injection.dart';
import '../../core/location/current_location.dart';
import '../../core/location/current_location_data_source.dart';
import '../../core/location/location_permission_gate.dart';
import '../../core/location/location_place_resolver.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';

class HomeCustomerPage extends StatefulWidget {
  const HomeCustomerPage({super.key});

  @override
  State<HomeCustomerPage> createState() => _HomeCustomerPageState();
}

class _HomeCustomerPageState extends State<HomeCustomerPage> {
  late final Future<_LocationCardState> _locationFuture;

  @override
  void initState() {
    super.initState();
    _locationFuture = _loadCurrentLocation();
  }

  Future<_LocationCardState> _loadCurrentLocation() async {
    final result = await sl<CurrentLocationDataSource>().getCurrentLocation();

    return await result.fold(
      (failure) async => _LocationCardState.error(failure.message),
      (location) async {
        try {
          final resolution = await sl<LocationPlaceResolver>().resolvePlaceName(
            location,
          );

          return _LocationCardState.success(
            location,
            placeName: resolution.placeName,
            debugDetails: resolution.debugDetails,
          );
        } catch (error) {
          return _LocationCardState.success(
            location,
            debugDetails: 'geocoder_error=$error',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = const [
      _CategoryChipData(
        label: 'Frenos',
        icon: Icons.album_outlined,
        accent: Color(0xFFB42318),
      ),
      _CategoryChipData(
        label: 'Filtros',
        icon: Icons.tune_outlined,
        accent: Color(0xFF175CD3),
      ),
      _CategoryChipData(
        label: 'Aceites',
        icon: Icons.opacity_outlined,
        accent: Color(0xFF0F8A5F),
      ),
      _CategoryChipData(
        label: 'Baterías',
        icon: Icons.battery_charging_full_outlined,
        accent: Color(0xFF93370D),
      ),
      _CategoryChipData(
        label: 'Suspensión',
        icon: Icons.precision_manufacturing_outlined,
        accent: Color(0xFF7A5AF8),
      ),
    ];

    final recommendedParts = const [
      _PartCardData(
        title: 'Kit de frenos delanteros Bosch',
        price: '₡74,900',
        eta: 'Entrega hoy',
        badge: 'Top ventas',
        compatibility: 'Toyota Hilux 2017-2022',
        accent: Color(0xFFB42318),
      ),
      _PartCardData(
        title: 'Filtro de aceite OEM',
        price: '₡8,500',
        eta: 'Retiro en 25 min',
        badge: 'Compatible',
        compatibility: 'Hyundai Accent 2018',
        accent: Color(0xFF175CD3),
      ),
      _PartCardData(
        title: 'Batería 650A premium',
        price: '₡61,000',
        eta: 'Instalación disponible',
        badge: 'Garantía 18 meses',
        compatibility: 'Nissan Frontier 2020',
        accent: Color(0xFF0F8A5F),
      ),
    ];

    final fastDeals = const [
      _PartCompactData(
        title: 'Cambio de aceite Castrol',
        subtitle: 'Incluye filtro y revisión visual',
        price: '₡28,900',
      ),
      _PartCompactData(
        title: 'Pastillas traseras Akebono',
        subtitle: 'Listas para despacho inmediato',
        price: '₡32,400',
      ),
      _PartCompactData(
        title: 'Paquete de afinamiento',
        subtitle: 'Bujías, filtros y mano de obra',
        price: '₡54,700',
      ),
    ];

    return LocationPermissionGate(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F4EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F4EF),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 20,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Autolab Repuestos',
                style: TextStyle(
                  color: Color(0xFF181411),
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Compra repuestos compatibles y agenda instalación.',
                style: TextStyle(color: Color(0xFF6B5F57), fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
              },
              icon: const Icon(Icons.logout, color: Color(0xFF181411)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MarketplaceHero(categories: categories),
                    const SizedBox(height: 24),
                    FutureBuilder<_LocationCardState>(
                      future: _locationFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const _LocationStatusCard.loading();
                        }

                        final state =
                            snapshot.data ??
                            const _LocationCardState.error(
                              'No fue posible consultar la ubicacion actual.',
                            );

                        return _LocationStatusCard(state: state);
                      },
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Repuestos para tu vehículo',
                      subtitle:
                          'Sugerencias pensadas para el carro que tienes registrado.',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: recommendedParts
                          .map((part) => _PartCard(data: part))
                          .toList(),
                    ),
                    const SizedBox(height: 28),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 980;

                        if (!isWide) {
                          return Column(
                            children: [
                              _QuickDealsSection(items: fastDeals),
                              const SizedBox(height: 20),
                              const _CartSummaryCard(),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _QuickDealsSection(items: fastDeals),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(flex: 2, child: _CartSummaryCard()),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketplaceHero extends StatelessWidget {
  const _MarketplaceHero({required this.categories});

  final List<_CategoryChipData> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17110D), Color(0xFF8E2F1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22181411),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeroPill(
                icon: Icons.verified_outlined,
                label: 'Compatibilidad validada',
              ),
              _HeroPill(
                icon: Icons.local_shipping_outlined,
                label: 'Entrega rápida',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Pide repuestos como si fuera delivery, pero con criterio automotriz.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Busca por vehículo, compara opciones y agrega instalación en taller sin salir de la misma experiencia.',
            style: TextStyle(
              color: Color(0xFFF7EAE4),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final compactSearch = constraints.maxWidth < 430;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: compactSearch
                    ? const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.search, color: Color(0xFF9B3D24)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Buscar por repuesto, marca o placa del vehículo',
                                  style: TextStyle(
                                    color: Color(0xFF7B6F67),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _SearchVehicleButton(),
                          ),
                        ],
                      )
                    : const Row(
                        children: [
                          Icon(Icons.search, color: Color(0xFF9B3D24)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Buscar por repuesto, marca o placa del vehículo',
                              style: TextStyle(
                                color: Color(0xFF7B6F67),
                                fontSize: 15,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          _SearchVehicleButton(),
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories
                .map((item) => _CategoryChip(data: item))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LocationStatusCard extends StatelessWidget {
  const _LocationStatusCard({required this.state}) : isLoading = false;

  const _LocationStatusCard.loading() : state = null, isLoading = true;

  final _LocationCardState? state;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveState =
        state ??
        const _LocationCardState.error(
          'No fue posible consultar la ubicacion actual.',
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9DDD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isLoading
                  ? Icons.location_searching_outlined
                  : effectiveState.isSuccess
                  ? Icons.location_on_outlined
                  : Icons.location_off_outlined,
              color: const Color(0xFF9B3D24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ubicación actual',
                  style: TextStyle(
                    color: Color(0xFF181411),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isLoading
                      ? 'Consultando coordenadas del dispositivo...'
                      : effectiveState.description,
                  style: const TextStyle(
                    color: Color(0xFF6B5F57),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (!isLoading && effectiveState.placeName != null) ...[
                  const SizedBox(height: 12),
                  _LocationChip(label: effectiveState.placeName!),
                ],
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF181411),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LocationCardState {
  const _LocationCardState.success(
    this.location, {
    this.placeName,
    this.debugDetails,
  }) : message = null,
       isSuccess = true;

  const _LocationCardState.error(this.message)
    : location = null,
      placeName = null,
      debugDetails = null,
      isSuccess = false;

  final CurrentLocation? location;
  final String? placeName;
  final String? debugDetails;
  final String? message;
  final bool isSuccess;

  String get description {
    if (location != null) {
      if (placeName != null && placeName!.trim().isNotEmpty) {
        return 'Usaremos esta ubicación para mostrar talleres y servicios cercanos a ti.';
      }

      return 'Ubicación detectada correctamente para recomendar opciones cercanas.';
    }

    return message ?? 'No fue posible consultar la ubicacion actual.';
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchVehicleButton extends StatelessWidget {
  const _SearchVehicleButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF181411),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Mi vehículo',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.data});

  final _CategoryChipData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADFD5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            data.label,
            style: const TextStyle(
              color: Color(0xFF181411),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF181411),
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6B5F57), fontSize: 14),
        ),
      ],
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({required this.data});

  final _PartCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9DDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              gradient: LinearGradient(
                colors: [
                  data.accent.withValues(alpha: 0.96),
                  const Color(0xFFF3E4D8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 18,
                  left: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      data.badge,
                      style: TextStyle(
                        color: data.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 24,
                  bottom: 18,
                  child: Icon(
                    Icons.settings_input_component_outlined,
                    size: 82,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF181411),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.compatibility,
                  style: const TextStyle(
                    color: Color(0xFF6B5F57),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      data.price,
                      style: const TextStyle(
                        color: Color(0xFF181411),
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        data.eta,
                        style: const TextStyle(
                          color: Color(0xFF344054),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: data.accent,
                          side: BorderSide(color: data.accent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Ver detalle'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF181411),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Agregar'),
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

class _QuickDealsSection extends StatelessWidget {
  const _QuickDealsSection({required this.items});

  final List<_PartCompactData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9DDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Compra rápida',
            subtitle:
                'Atajos para productos con alta rotación y servicios frecuentes.',
          ),
          const SizedBox(height: 18),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4EF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.flash_on_outlined,
                        color: Color(0xFFB54708),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Color(0xFF181411),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF6B5F57),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.price,
                      style: const TextStyle(
                        color: Color(0xFF181411),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181411),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu pedido',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '2 repuestos y 1 instalación sugerida.',
            style: TextStyle(color: Color(0xFFD6CCC3), fontSize: 14),
          ),
          const SizedBox(height: 22),
          const _CartLine(label: 'Subtotal', value: '₡83,400'),
          const SizedBox(height: 10),
          const _CartLine(label: 'Instalación estimada', value: '₡18,000'),
          const SizedBox(height: 10),
          const _CartLine(label: 'Envío', value: 'Gratis'),
          const Divider(color: Color(0x33FFFFFF), height: 28),
          const _CartLine(label: 'Total', value: '₡101,400', emphasized: true),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.directions_car_outlined, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Compatibilidad validada para Toyota Hilux 2020 2.8L.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEE6B3B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Ir al checkout',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: emphasized ? Colors.white : const Color(0xFFD6CCC3),
      fontSize: emphasized ? 18 : 14,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
    );

    return Row(
      children: [
        Text(label, style: textStyle),
        const Spacer(),
        Text(value, style: textStyle),
      ],
    );
  }
}

class _CategoryChipData {
  const _CategoryChipData({
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final Color accent;
}

class _PartCardData {
  const _PartCardData({
    required this.title,
    required this.price,
    required this.eta,
    required this.badge,
    required this.compatibility,
    required this.accent,
  });

  final String title;
  final String price;
  final String eta;
  final String badge;
  final String compatibility;
  final Color accent;
}

class _PartCompactData {
  const _PartCompactData({
    required this.title,
    required this.subtitle,
    required this.price,
  });

  final String title;
  final String subtitle;
  final String price;
}
