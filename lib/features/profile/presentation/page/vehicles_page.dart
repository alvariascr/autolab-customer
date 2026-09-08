import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/garage_vehicle_controller.dart';
import '../../application/garage_vehicle_image_service.dart';
import '../../domain/entities/garage_vehicle.dart';
import '../../domain/repositories/garage_vehicle_repository.dart';
import '../../domain/usecases/get_garage_vehicles.dart';
import '../helpers/garage_vehicle_display.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  static const _newVehicleImageKey =
      GarageVehicleImageService.newVehicleImageKey;
  late final GarageVehicleRepository _repository;
  late final GetGarageVehicles _getGarageVehicles;
  late final GarageVehicleImageService _imageService;
  GarageVehicleController? _garageVehicleController;
  var _status = _VehiclesStatus.loading;
  var _vehicles = <GarageVehicle>[];
  GarageVehicle? _selectedVehicle;
  final _vehicleImagePaths = <String, String>{};
  var _formVersion = 0;

  @override
  void initState() {
    super.initState();
    _repository = sl<GarageVehicleRepository>();
    _getGarageVehicles = sl<GetGarageVehicles>();
    _imageService = sl<GarageVehicleImageService>();
    _garageVehicleController = sl.isRegistered<GarageVehicleController>()
        ? sl<GarageVehicleController>()
        : null;
    _loadVehicles();
    _loadVehicleImages();
  }

  Future<void> _loadVehicles() async {
    if (!mounted) return;

    setState(() => _status = _VehiclesStatus.loading);

    try {
      var vehicles = await _getGarageVehicles();
      if (await _imageService.uploadLegacyImages(vehicles)) {
        vehicles = await _getGarageVehicles();
      }
      final defaultVehicle = vehicles
          .where((vehicle) => vehicle.isDefault)
          .firstOrNull;
      if (!mounted) return;

      setState(() {
        _vehicles = vehicles;
        if (_selectedVehicle != null) {
          _selectedVehicle = vehicles
              .where((vehicle) => vehicle.id == _selectedVehicle!.id)
              .firstOrNull;
        }
        if (_selectedVehicle == null && defaultVehicle != null) {
          _selectedVehicle = defaultVehicle;
        }
        if (_selectedVehicle != null &&
            vehicles.every((vehicle) => vehicle.id != _selectedVehicle!.id)) {
          _selectedVehicle = null;
        }
        _status = _VehiclesStatus.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _VehiclesStatus.failure);
    }
  }

  Future<void> _openVehicleForm({GarageVehicle? vehicle}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AutolabCustomer.transparent,
      builder: (_) =>
          _VehicleForm(repository: _repository, initialVehicle: vehicle),
    );

    if (saved == true && mounted) {
      await _loadVehicles();
      _garageVehicleController?.notifyVehiclesChanged();
    }
  }

  Future<void> _deleteVehicle(GarageVehicle vehicle) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AutolabCustomer.customerSurfaceColor(context),
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

    if (confirmed != true) return;

    // Decide the replacement using the list we already have in memory —
    // no need to reload just to find out whether one is needed.
    final replacement = vehicle.isDefault
        ? _vehicles.where((item) => item.id != vehicle.id).firstOrNull
        : null;

    try {
      if (_garageVehicleController != null) {
        await _garageVehicleController!.deleteVehicle(vehicle.id);
      } else {
        await _repository.deleteVehicle(vehicle.id);
      }
      if (!mounted) return;

      if (replacement != null) {
        await _setDefaultVehicleRemote(replacement.id);
        if (!mounted) return;
        setState(() {
          _selectedVehicle = replacement;
          _formVersion++;
        });
      }

      if (!mounted) return;
      await _loadVehicles();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.vehiclesDeleteFailed)));
    }
  }

  void _startNewVehicle() {
    setState(() {
      _selectedVehicle = null;
      _vehicleImagePaths.remove(_newVehicleImageKey);
      _formVersion++;
    });
    _imageService.removeNewVehicleImage();
  }

  /// Shows [vehicle]'s data in the preview/form below without changing
  /// which vehicle is active app-wide. Tapping a card should only let the
  /// customer look at (or edit) that vehicle's details.
  void _viewVehicle(GarageVehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _formVersion++;
    });
  }

  Future<void> _setDefaultVehicleRemote(String vehicleId) {
    if (_garageVehicleController != null) {
      return _garageVehicleController!.setDefaultVehicle(vehicleId);
    }
    return _repository.setDefaultVehicle(vehicleId);
  }

  Future<void> _activateVehicle(GarageVehicle vehicle) async {
    try {
      await _setDefaultVehicleRemote(vehicle.id);
      if (!mounted) return;
      setState(() {
        _selectedVehicle = vehicle;
        _formVersion++;
      });
      await _loadVehicles();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.vehiclesSaveFailed),
        ),
      );
    }
  }

  Future<void> _handleVehicleSaved(String? vehicleId) async {
    if (vehicleId != null && vehicleId.isNotEmpty) {
      try {
        final movedImage = await _imageService.moveAndUploadNewVehicleImage(
          vehicleId,
        );
        if (movedImage != null) {
          if (mounted) {
            setState(() {
              _vehicleImagePaths
                ..remove(_newVehicleImageKey)
                ..[movedImage.preferenceKey] = movedImage.localPath;
            });
          }
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.vehiclesSaveFailed),
            ),
          );
        }
      }
    }

    _startNewVehicle();
    await _loadVehicles();
    _garageVehicleController?.notifyVehiclesChanged();
    if (vehicleId != null &&
        vehicleId.isNotEmpty &&
        !_vehicles.any((vehicle) => vehicle.isDefault)) {
      final vehicle = _vehicles
          .where((item) => item.id == vehicleId)
          .firstOrNull;
      if (vehicle != null) await _activateVehicle(vehicle);
    }
  }

  Future<void> _pickVehicleImage() async {
    final image = await ImagePickerPlatform.instance.getImageFromSource(
      source: ImageSource.gallery,
      options: const ImagePickerOptions(imageQuality: 85),
    );

    if (image == null || !mounted) return;

    final key = _vehicleImageKey(_selectedVehicle);
    final persistedImagePath = await _imageService.persistImage(
      sourcePath: image.path,
      preferenceKey: key,
    );

    if (!mounted) return;

    setState(() {
      _vehicleImagePaths[key] = persistedImagePath;
    });

    final selectedVehicleId = _selectedVehicle?.id;
    if (selectedVehicleId != null) {
      try {
        await _imageService.uploadPersistedImage(
          vehicleId: selectedVehicleId,
          localPath: persistedImagePath,
          preferenceKey: key,
        );
        await _loadVehicles();
        _garageVehicleController?.notifyVehiclesChanged();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.vehiclesSaveFailed),
          ),
        );
      }
    }
  }

  Future<void> _loadVehicleImages() async {
    final loadedPaths = await _imageService.loadLocalImages();

    if (!mounted) return;

    setState(() {
      _vehicleImagePaths
        ..clear()
        ..addAll(loadedPaths);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: RefreshIndicator(
          color: AutolabCustomer.primary,
          onRefresh: _loadVehicles,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AutolabCustomer.responsiveScreenMargin(context),
              AutolabCustomer.spacingLg,
              AutolabCustomer.responsiveScreenMargin(context),
              AutolabCustomer.spacingXxl,
            ),
            children: [
              _VehiclesBackButton(onTap: () => _goBack(context)),
              const SizedBox(height: AutolabCustomer.spacingMd),
              const _VehiclesTitleRow(),
              const SizedBox(height: AutolabCustomer.spacingMd),
              SizedBox(
                height: AutolabCustomer.responsiveDouble(
                  context,
                  compact: 112,
                  regular: 124,
                  tablet: 136,
                ),
                child: _buildVehicleSelector(l10n),
              ),
              const SizedBox(height: AutolabCustomer.spacingLg),
              Divider(color: AutolabCustomer.customerBorderColor(context)),
              const SizedBox(height: AutolabCustomer.spacingLg),
              if (_status == _VehiclesStatus.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AutolabCustomer.spacingXl),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_status == _VehiclesStatus.failure)
                _VehiclesMessage(
                  icon: Icons.error_outline_rounded,
                  message: l10n.vehiclesLoadFailed,
                )
              else ...[
                _VehiclePreview(
                  vehicle: _selectedVehicle,
                  imagePath:
                      _vehicleImagePaths[_vehicleImageKey(_selectedVehicle)],
                  imageUrl: _selectedVehicle?.imageUrl,
                  onChangeImage: _pickVehicleImage,
                  onActivate: () {
                    final vehicle = _selectedVehicle;
                    if (vehicle != null) _activateVehicle(vehicle);
                  },
                ),
                const SizedBox(height: AutolabCustomer.spacingMd),
                _VehicleForm(
                  key: ValueKey(
                    '${_selectedVehicle?.id ?? 'new'}-$_formVersion',
                  ),
                  repository: _repository,
                  initialVehicle: _selectedVehicle,
                  embedded: true,
                  onSaved: _handleVehicleSaved,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleSelector(AppLocalizations l10n) {
    if (_vehicles.isEmpty) {
      return Row(
        children: [
          Expanded(child: _EmptyVehicleCard(message: l10n.vehiclesEmpty)),
          const SizedBox(width: AutolabCustomer.spacingMd),
          _AddVehicleCircleButton(onTap: _startNewVehicle),
        ],
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _vehicles.length + 1,
      separatorBuilder: (context, index) =>
          const SizedBox(width: AutolabCustomer.spacingMd),
      itemBuilder: (context, index) {
        if (index == _vehicles.length) {
          return Center(
            child: _AddVehicleCircleButton(onTap: _startNewVehicle),
          );
        }

        final vehicle = _vehicles[index];
        return _VehicleCompactCard(
          vehicle: vehicle,
          selected: vehicle.isDefault,
          onTap: () => _viewVehicle(vehicle),
          onEdit: () => _openVehicleForm(vehicle: vehicle),
          onDelete: () => _deleteVehicle(vehicle),
        );
      },
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/home-customer?tab=profile');
  }
}

enum _VehiclesStatus { loading, success, failure }

class _VehiclesBackButton extends StatelessWidget {
  const _VehiclesBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: AutolabCustomer.customerSurfaceColor(context),
            foregroundColor: AutolabCustomer.customerSecondaryTextColor(
              context,
            ),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
        ),
      ),
    );
  }
}

class _VehiclesTitleRow extends StatelessWidget {
  const _VehiclesTitleRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text(
      l10n.vehiclesTitle,
      style: AutolabCustomer.bodyLarge.copyWith(
        color: AutolabCustomer.customerTextColor(context),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _VehicleCompactCard extends StatelessWidget {
  const _VehicleCompactCard({
    required this.vehicle,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final GarageVehicle vehicle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AutolabCustomer.responsiveDouble(
        context,
        compact: 80,
        regular: 92,
        tablet: 108,
      ),
      child: Material(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        child: InkWell(
          onTap: onTap,
          onLongPress: onEdit,
          borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(AutolabCustomer.spacingSm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
              border: Border.all(
                color: selected
                    ? AutolabCustomer.primary
                    : AutolabCustomer.transparent,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: _VehicleCompactImage(vehicle: vehicle),
                      ),
                    ),
                    Text(
                      garageVehicleTitle(vehicle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.label.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      selected
                          ? AppLocalizations.of(context)!.garageActiveVehicle
                          : garageVehicleSelectorSubtitle(vehicle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.caption.copyWith(
                        color: selected
                            ? AutolabCustomer.primary
                            : AutolabCustomer.customerSecondaryTextColor(
                                context,
                              ),
                        fontSize: 9,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        selected
                            ? Icons.check_circle_outline_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? AutolabCustomer.primary
                            : AutolabCustomer.customerSecondaryTextColor(
                                context,
                              ),
                        size: 10,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: -8,
                  top: -8,
                  child: PopupMenuButton<String>(
                    color: AutolabCustomer.customerSurfaceColor(context),
                    icon: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AutolabCustomer.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        size: 16,
                        color: AutolabCustomer.secondary,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                        return;
                      }
                      onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          AppLocalizations.of(context)!.vehiclesEditAction,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          AppLocalizations.of(context)!.vehiclesDeleteAction,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleCompactImage extends StatelessWidget {
  const _VehicleCompactImage({required this.vehicle});

  final GarageVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final imageUrl = vehicle.imageUrl;
    final placeholder = Icon(
      Icons.directions_car_filled_rounded,
      color: AutolabCustomer.customerTextColor(context),
      size: AutolabCustomer.responsiveDouble(
        context,
        compact: 34,
        regular: 42,
        tablet: 48,
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      child: SizedBox.expand(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
          loadingBuilder: (context, child, loadingProgress) =>
              loadingProgress == null ? child : placeholder,
        ),
      ),
    );
  }
}

class _EmptyVehicleCard extends StatelessWidget {
  const _EmptyVehicleCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_car_filled_outlined,
            color: AutolabCustomer.primary,
          ),
          const SizedBox(width: AutolabCustomer.spacingMd),
          Expanded(
            child: Text(
              message,
              style: AutolabCustomer.caption.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddVehicleCircleButton extends StatelessWidget {
  const _AddVehicleCircleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          foregroundColor: AutolabCustomer.primary,
          side: const BorderSide(color: AutolabCustomer.primary),
        ),
        child: const Icon(Icons.add_rounded, size: AutolabCustomer.iconSm),
      ),
    );
  }
}

class _VehiclePreview extends StatelessWidget {
  const _VehiclePreview({
    required this.vehicle,
    required this.onChangeImage,
    required this.onActivate,
    this.imagePath,
    this.imageUrl,
  });

  final GarageVehicle? vehicle;
  final String? imagePath;
  final String? imageUrl;
  final VoidCallback onChangeImage;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasSelectedVehicle = vehicle != null;
    final title = hasSelectedVehicle ? garageVehicleTitle(vehicle!) : '';
    final showActivateAction = vehicle != null && !vehicle!.isDefault;

    return Column(
      children: [
        SizedBox(
          height: AutolabCustomer.responsiveDouble(
            context,
            compact: 92,
            regular: 114,
            tablet: 136,
          ),
          child: _VehiclePreviewImage(imagePath: imagePath, imageUrl: imageUrl),
        ),
        if (hasSelectedVehicle) ...[
          const SizedBox(height: AutolabCustomer.spacingXs),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: AutolabCustomer.spacingSm),
        SizedBox(
          height: 36,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AutolabCustomer.customerSurfaceColor(context),
              foregroundColor: AutolabCustomer.customerSecondaryTextColor(
                context,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
              ),
            ),
            onPressed: onChangeImage,
            icon: const Icon(
              Icons.image_outlined,
              size: AutolabCustomer.iconSm,
            ),
            label: Text(
              l10n.vehiclesChangeImageAction,
              style: AutolabCustomer.caption.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (showActivateAction) ...[
          const SizedBox(height: AutolabCustomer.spacingSm),
          SizedBox(
            height: 36,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AutolabCustomer.primary,
                foregroundColor: AutolabCustomer.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                ),
              ),
              onPressed: onActivate,
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                size: AutolabCustomer.iconSm,
              ),
              label: Text(
                l10n.vehiclesSetActiveAction,
                style: AutolabCustomer.caption.copyWith(
                  color: AutolabCustomer.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VehiclePreviewImage extends StatelessWidget {
  const _VehiclePreviewImage({this.imagePath, this.imageUrl});

  final String? imagePath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;

    if (path != null && path.isNotEmpty) {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const _VehiclePreviewPlaceholder(),
      );
    }

    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const _VehiclePreviewPlaceholder(),
      );
    }

    return const _VehiclePreviewPlaceholder();
  }
}

class _VehiclePreviewPlaceholder extends StatelessWidget {
  const _VehiclePreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.directions_car_filled_rounded,
      color: AutolabCustomer.customerTextColor(context),
      size: AutolabCustomer.responsiveDouble(
        context,
        compact: 82,
        regular: 104,
        tablet: 126,
      ),
    );
  }
}

class _VehiclesMessage extends StatelessWidget {
  const _VehiclesMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AutolabCustomer.spacingLg),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AutolabCustomer.primary),
          const SizedBox(height: AutolabCustomer.spacingSm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleForm extends StatefulWidget {
  const _VehicleForm({
    required this.repository,
    this.initialVehicle,
    this.embedded = false,
    this.onSaved,
    super.key,
  });

  final GarageVehicleRepository repository;
  final GarageVehicle? initialVehicle;
  final bool embedded;
  final Future<void> Function(String? vehicleId)? onSaved;

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

  @override
  void initState() {
    super.initState();
    _loadInitialVehicle();
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

  void _loadInitialVehicle() {
    final vehicle = widget.initialVehicle;
    _plateController.text = vehicle?.licensePlate ?? '';
    _brandController.text = vehicle?.brand ?? '';
    _modelController.text = vehicle?.model ?? '';
    _yearController.text = vehicle?.year?.toString() ?? '';
    _colorController.text = vehicle?.color ?? '';
    _vehicleType = vehicle?.vehicleType;
    _fuelType = vehicle?.fuelType;
    _transmissionType = vehicle?.transmissionType;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final vehicle = widget.initialVehicle;
      String? savedVehicleId;
      if (vehicle == null) {
        savedVehicleId = await widget.repository.createVehicle(
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
        await widget.repository.updateVehicle(
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

      if (!mounted) return;

      if (widget.onSaved != null) {
        await widget.onSaved!(savedVehicleId);
        return;
      }

      Navigator.pop(context, true);
    } on GarageVehicleAlreadyExistsException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = l10n.vehiclesPlateAlreadyExists;
      });
    } catch (_) {
      if (!mounted) return;
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
    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _VehicleTextField(
            controller: _plateController,
            hintText: l10n.vehiclesPlateLabel,
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              final l10n = AppLocalizations.of(context)!;
              return value == null || value.trim().isEmpty
                  ? l10n.vehiclesPlateRequired
                  : null;
            },
          ),
          const SizedBox(height: AutolabCustomer.spacingSm),
          _VehicleTypeField(
            value: _vehicleType,
            onChanged: (value) => setState(() => _vehicleType = value),
          ),
          const SizedBox(height: AutolabCustomer.spacingSm),
          _VehicleTextField(
            controller: _brandController,
            hintText: l10n.vehiclesBrandLabel,
            suffixIcon: Icons.chevron_right_rounded,
          ),
          const SizedBox(height: AutolabCustomer.spacingSm),
          _VehicleTextField(
            controller: _modelController,
            hintText: l10n.vehiclesModelLabel,
            suffixIcon: Icons.chevron_right_rounded,
          ),
          const SizedBox(height: AutolabCustomer.spacingSm),
          _VehicleTextField(
            controller: _yearController,
            hintText: l10n.vehiclesYearLabel,
            keyboardType: TextInputType.number,
            suffixIcon: Icons.chevron_right_rounded,
          ),
          const SizedBox(height: AutolabCustomer.spacingSm),
          _VehicleTextField(
            controller: _colorController,
            hintText: l10n.vehiclesColorLabel,
          ),
          const SizedBox(height: AutolabCustomer.spacingSm),
          _VehicleFuelField(
            value: _fuelType,
            onChanged: (value) => setState(() => _fuelType = value),
          ),
          const SizedBox(height: AutolabCustomer.spacingSm),
          _VehicleTransmissionField(
            value: _transmissionType,
            onChanged: (value) => setState(() => _transmissionType = value),
          ),
          const SizedBox(height: AutolabCustomer.spacingLg),
          if (_errorMessage != null) ...[
            _VehicleErrorMessage(message: _errorMessage!),
            const SizedBox(height: AutolabCustomer.spacingMd),
          ],
          SizedBox(
            width: double.infinity,
            height: AutolabCustomer.responsiveDouble(
              context,
              compact: 48,
              regular: 54,
              tablet: 58,
            ),
            child: ElevatedButton(
              style: AutolabCustomer.primaryButton,
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.vehiclesSaveAction,
                      style: AutolabCustomer.body.copyWith(
                        color: AutolabCustomer.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AutolabCustomer.spacingMd),
          SizedBox(
            width: double.infinity,
            height: AutolabCustomer.responsiveDouble(
              context,
              compact: 48,
              regular: 54,
              tablet: 58,
            ),
            child: OutlinedButton(
              style: AutolabCustomer.secondaryButton.copyWith(
                foregroundColor: WidgetStatePropertyAll(
                  AutolabCustomer.customerTextColor(context),
                ),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.go('/home-customer?tab=profile');
              },
              child: Text(
                l10n.vehiclesNextAction,
                style: AutolabCustomer.body.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return form;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        AutolabCustomer.spacingLg,
        AutolabCustomer.spacingLg,
        AutolabCustomer.spacingLg,
        AutolabCustomer.spacingLg + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(child: form),
    );
  }
}

class _VehicleTypeField extends StatelessWidget {
  const _VehicleTypeField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AutolabCustomer.customerSurfaceColor(context),
      icon: Icon(
        Icons.chevron_right_rounded,
        color: AutolabCustomer.customerSecondaryTextColor(context),
      ),
      decoration: _vehicleInputDecoration(context, l10n.vehiclesTypeLabel),
      style: AutolabCustomer.body.copyWith(
        color: AutolabCustomer.customerTextColor(context),
      ),
      items: [
        DropdownMenuItem(value: 'car', child: Text(l10n.vehiclesTypeCar)),
        DropdownMenuItem(
          value: 'motorcycle',
          child: Text(l10n.vehiclesTypeMotorcycle),
        ),
        DropdownMenuItem(value: 'pickup', child: Text(l10n.vehiclesTypePickup)),
        DropdownMenuItem(value: 'suv', child: Text(l10n.vehiclesTypeSuv)),
        DropdownMenuItem(value: 'truck', child: Text(l10n.vehiclesTypeTruck)),
      ],
      onChanged: onChanged,
    );
  }
}

class _VehicleFuelField extends StatelessWidget {
  const _VehicleFuelField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _VehicleDropdownField(
      value: value,
      hintText: l10n.vehiclesFuelLabel,
      items: [
        DropdownMenuItem(
          value: 'gasoline',
          child: Text(l10n.vehiclesFuelGasoline),
        ),
        DropdownMenuItem(value: 'diesel', child: Text(l10n.vehiclesFuelDiesel)),
        DropdownMenuItem(
          value: 'electric',
          child: Text(l10n.vehiclesFuelElectric),
        ),
        DropdownMenuItem(value: 'hybrid', child: Text(l10n.vehiclesFuelHybrid)),
      ],
      onChanged: onChanged,
    );
  }
}

class _VehicleTransmissionField extends StatelessWidget {
  const _VehicleTransmissionField({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _VehicleDropdownField(
      value: value,
      hintText: l10n.vehiclesTransmissionLabel,
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
      onChanged: onChanged,
    );
  }
}

class _VehicleDropdownField extends StatelessWidget {
  const _VehicleDropdownField({
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hintText;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AutolabCustomer.customerSurfaceColor(context),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AutolabCustomer.customerSecondaryTextColor(context),
      ),
      decoration: _vehicleInputDecoration(context, hintText),
      style: AutolabCustomer.body.copyWith(
        color: AutolabCustomer.customerTextColor(context),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _VehicleTextField extends StatelessWidget {
  const _VehicleTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: AutolabCustomer.body.copyWith(
        color: AutolabCustomer.customerTextColor(context),
      ),
      decoration: _vehicleInputDecoration(
        context,
        hintText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _VehicleErrorMessage extends StatelessWidget {
  const _VehicleErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AutolabCustomer.spacingSm),
      decoration: BoxDecoration(
        color: AutolabCustomer.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.error),
      ),
      child: Text(
        message,
        style: AutolabCustomer.caption.copyWith(
          color: AutolabCustomer.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

InputDecoration _vehicleInputDecoration(
  BuildContext context,
  String hintText, {
  IconData? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AutolabCustomer.body.copyWith(
      color: AutolabCustomer.customerSecondaryTextColor(context),
    ),
    filled: true,
    fillColor: AutolabCustomer.customerSurfaceColor(context),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AutolabCustomer.spacingMd,
      vertical: AutolabCustomer.spacingSm,
    ),
    suffixIcon: suffixIcon == null
        ? null
        : Icon(
            suffixIcon,
            color: AutolabCustomer.customerSecondaryTextColor(context),
          ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      borderSide: const BorderSide(color: AutolabCustomer.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      borderSide: const BorderSide(color: AutolabCustomer.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      borderSide: const BorderSide(color: AutolabCustomer.error),
    ),
  );
}

String _vehicleImageKey(GarageVehicle? vehicle) {
  return vehicle == null
      ? _VehiclesPageState._newVehicleImageKey
      : GarageVehicleImageService.vehicleImageKey(vehicle.id);
}
