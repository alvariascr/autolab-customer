import 'package:flutter/material.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/garage_vehicle_remote_data_source.dart';
import '../../domain/entities/garage_vehicle.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  late final GarageVehicleRemoteDataSource _dataSource;
  var _status = _VehiclesStatus.loading;
  var _vehicles = <GarageVehicle>[];

  @override
  void initState() {
    super.initState();
    _dataSource = sl<GarageVehicleRemoteDataSource>();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    if (!mounted) {
      return;
    }

    setState(() => _status = _VehiclesStatus.loading);

    try {
      final vehicles = await _dataSource.getVehicles();
      if (!mounted) {
        return;
      }

      setState(() {
        _vehicles = vehicles;
        _status = _VehiclesStatus.success;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _status = _VehiclesStatus.failure);
    }
  }

  Future<void> _openVehicleForm({GarageVehicle? vehicle}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _VehicleForm(dataSource: _dataSource, initialVehicle: vehicle),
    );

    if (saved == true && mounted) {
      await _loadVehicles();
    }
  }

  Future<void> _deleteVehicle(GarageVehicle vehicle) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vehiclesDeleteTitle),
        content: Text(l10n.vehiclesDeleteMessage(vehicle.licensePlate)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.vehiclesCancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.vehiclesDeleteAction),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _dataSource.deleteVehicle(vehicle.id);
      if (!mounted) {
        return;
      }

      await _loadVehicles();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.vehiclesDeleteFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4EF),
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.vehiclesTitle),
        actions: [
          IconButton(
            tooltip: l10n.vehiclesAddAction,
            onPressed: _openVehicleForm,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadVehicles,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                l10n.vehiclesSubtitle,
                style: const TextStyle(
                  color: Color(0xFF6B5F57),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              if (_status == _VehiclesStatus.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_status == _VehiclesStatus.failure)
                _VehiclesMessage(
                  icon: Icons.error_outline_rounded,
                  message: l10n.vehiclesLoadFailed,
                )
              else if (_vehicles.isEmpty)
                _VehiclesMessage(
                  icon: Icons.directions_car_filled_outlined,
                  message: l10n.vehiclesEmpty,
                )
              else
                ..._vehicles.map(
                  (vehicle) => _VehicleTile(
                    vehicle: vehicle,
                    onEdit: () => _openVehicleForm(vehicle: vehicle),
                    onDelete: () => _deleteVehicle(vehicle),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openVehicleForm,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.vehiclesAddAction),
      ),
    );
  }
}

enum _VehiclesStatus { loading, success, failure }

class _VehiclesMessage extends StatelessWidget {
  const _VehiclesMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9DDD2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xFFE32119)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B5F57),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final GarageVehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = [
      vehicle.brand,
      vehicle.model,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
    final subtitle = [
      vehicle.licensePlate,
      if (vehicle.year != null) vehicle.year.toString(),
      vehicle.color,
      vehicle.vehicleType,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9DDD2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9E7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.directions_car_filled_outlined,
              color: Color(0xFFE32119),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? vehicle.licensePlate : title,
                  style: const TextStyle(
                    color: Color(0xFF181411),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B5F57),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.vehiclesEditAction,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.vehiclesDeleteAction,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _VehicleForm extends StatefulWidget {
  const _VehicleForm({required this.dataSource, this.initialVehicle});

  final GarageVehicleRemoteDataSource dataSource;
  final GarageVehicle? initialVehicle;

  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  String? _vehicleType;
  String? _fuelType;
  String? _transmissionType;
  String? _errorMessage;
  var _saving = false;

  bool get _isEditing => widget.initialVehicle != null;

  @override
  void initState() {
    super.initState();

    final vehicle = widget.initialVehicle;
    if (vehicle == null) {
      return;
    }

    _plateController.text = vehicle.licensePlate;
    _brandController.text = vehicle.brand ?? '';
    _modelController.text = vehicle.model ?? '';
    _yearController.text = vehicle.year?.toString() ?? '';
    _colorController.text = vehicle.color ?? '';
    _vehicleType = vehicle.vehicleType;
    _fuelType = vehicle.fuelType;
    _transmissionType = vehicle.transmissionType;
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final vehicle = widget.initialVehicle;
      if (vehicle == null) {
        await widget.dataSource.createVehicle(
          licensePlate: _plateController.text,
          vehicleType: _vehicleType,
          brand: _brandController.text,
          model: _modelController.text,
          year: int.tryParse(_yearController.text.trim()),
          color: _colorController.text,
          fuelType: _fuelType,
          transmissionType: _transmissionType,
        );
      } else {
        await widget.dataSource.updateVehicle(
          id: vehicle.id,
          licensePlate: _plateController.text,
          vehicleType: _vehicleType,
          brand: _brandController.text,
          model: _modelController.text,
          year: int.tryParse(_yearController.text.trim()),
          color: _colorController.text,
          fuelType: _fuelType,
          transmissionType: _transmissionType,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } on GarageVehicleAlreadyExistsException {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorMessage = l10n.vehiclesPlateAlreadyExists;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorMessage = l10n.vehiclesSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing
                    ? l10n.vehiclesEditFormTitle
                    : l10n.vehiclesFormTitle,
                style: const TextStyle(
                  color: Color(0xFF181411),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: l10n.vehiclesPlateLabel),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.vehiclesPlateRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: InputDecoration(labelText: l10n.vehiclesTypeLabel),
                items: [
                  DropdownMenuItem(
                    value: 'car',
                    child: Text(l10n.vehiclesTypeCar),
                  ),
                  DropdownMenuItem(
                    value: 'motorcycle',
                    child: Text(l10n.vehiclesTypeMotorcycle),
                  ),
                  DropdownMenuItem(
                    value: 'pickup',
                    child: Text(l10n.vehiclesTypePickup),
                  ),
                  DropdownMenuItem(
                    value: 'suv',
                    child: Text(l10n.vehiclesTypeSuv),
                  ),
                  DropdownMenuItem(
                    value: 'truck',
                    child: Text(l10n.vehiclesTypeTruck),
                  ),
                ],
                onChanged: (value) => setState(() => _vehicleType = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(labelText: l10n.vehiclesBrandLabel),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: InputDecoration(labelText: l10n.vehiclesModelLabel),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.vehiclesYearLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: InputDecoration(
                        labelText: l10n.vehiclesColorLabel,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _fuelType,
                decoration: InputDecoration(labelText: l10n.vehiclesFuelLabel),
                items: [
                  DropdownMenuItem(
                    value: 'gasoline',
                    child: Text(l10n.vehiclesFuelGasoline),
                  ),
                  DropdownMenuItem(
                    value: 'diesel',
                    child: Text(l10n.vehiclesFuelDiesel),
                  ),
                  DropdownMenuItem(
                    value: 'electric',
                    child: Text(l10n.vehiclesFuelElectric),
                  ),
                  DropdownMenuItem(
                    value: 'hybrid',
                    child: Text(l10n.vehiclesFuelHybrid),
                  ),
                ],
                onChanged: (value) => setState(() => _fuelType = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _transmissionType,
                decoration: InputDecoration(
                  labelText: l10n.vehiclesTransmissionLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'manual',
                    child: Text(l10n.vehiclesTransmissionManual),
                  ),
                  DropdownMenuItem(
                    value: 'automatic',
                    child: Text(l10n.vehiclesTransmissionAutomatic),
                  ),
                ],
                onChanged: (value) => setState(() => _transmissionType = value),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFB7B2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFE32119),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF7A1E18),
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.vehiclesSaveAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
