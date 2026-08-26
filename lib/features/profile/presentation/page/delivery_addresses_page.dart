import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/location/current_location.dart';
import '../../../../core/location/geocoding_client.dart';
import '../../../../core/location/location_cubit.dart';
import '../../../../core/location/location_state.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/customer_location.dart';
import '../../domain/repositories/customer_location_repository.dart';

class DeliveryAddressesPage extends StatefulWidget {
  const DeliveryAddressesPage({
    super.key,
    this.openFormOnStart = false,
    this.closeAfterSave = false,
  });

  static const routePath = '/addresses';

  final bool openFormOnStart;
  final bool closeAfterSave;

  @override
  State<DeliveryAddressesPage> createState() => _DeliveryAddressesPageState();
}

class _DeliveryAddressesPageState extends State<DeliveryAddressesPage> {
  late Future<List<CustomerLocation>> _locationsFuture;

  CustomerLocationRepository get _locationsRepository =>
      sl<CustomerLocationRepository>();

  GeocodingClient get _geocodingClient => sl<GeocodingClient>();

  @override
  void initState() {
    super.initState();
    _locationsFuture = _locationsRepository.loadLocations();
    if (widget.openFormOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openAddressForm();
        }
      });
    }
  }

  void _reload() {
    setState(() {
      _locationsFuture = _locationsRepository.loadLocations();
    });
  }

  Future<void> _openAddressForm({CustomerLocation? location}) async {
    final savedLocation = await showModalBottomSheet<CustomerLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AutolabCustomer.customerSurfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AutolabCustomer.radiusLg),
        ),
      ),
      builder: (context) {
        return _UserLocationFormSheet(
          location: location,
          onSave: (request) => _locationsRepository.saveLocation(
            request,
            locationId: location?.id,
          ),
          geocodingClient: _geocodingClient,
        );
      },
    );

    if (savedLocation != null && mounted) {
      if (widget.closeAfterSave) {
        context.pop(savedLocation);
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      _activateLocation(savedLocation);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.garageAddressesSaveSuccess)),
        );
      _reload();
    }
  }

  void _selectLocation(CustomerLocation location) {
    if (widget.closeAfterSave) {
      context.pop(location);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    _activateLocation(location);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.garageLocationsUseSuccess)));
  }

  void _activateLocation(CustomerLocation location) {
    context.read<LocationCubit>().useSavedLocation(
      location: CurrentLocation(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      placeName: location.displayLabel,
    );
  }

  Future<void> _confirmDelete(CustomerLocation location) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AutolabCustomer.customerSurfaceColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusLg),
            side: BorderSide(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          title: Text(
            l10n.garageLocationsDeleteTitle,
            style: AutolabCustomer.h3.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            l10n.garageLocationsDeleteMessage,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cartDeleteAddressCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                l10n.cartDeleteAddressConfirm,
                style: const TextStyle(color: AutolabCustomer.primary),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _locationsRepository.deleteLocation(location.id);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.garageLocationsDeleteSuccess)),
        );
      _reload();
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.garageLocationsSaveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _AddressesHeader(
              title: l10n.garageAddresses,
              addLabel: l10n.garageAddressesHeaderAddAction,
              onAdd: () => _openAddressForm(),
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            Expanded(
              child: FutureBuilder<List<CustomerLocation>>(
                future: _locationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _AddressesMessage(
                      icon: Icons.error_outline_rounded,
                      title: l10n.garageLocationsLoadErrorTitle,
                      message: l10n.garageLocationsLoadErrorMessage,
                      actionLabel: l10n.myAppointmentsRetryAction,
                      onAction: _reload,
                    );
                  }

                  final locations = snapshot.data ?? const <CustomerLocation>[];

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    color: AutolabCustomer.primary,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        AutolabCustomer.responsiveScreenMargin(context),
                        AutolabCustomer.spacingSmd,
                        AutolabCustomer.responsiveScreenMargin(context),
                        AutolabCustomer.spacingXl +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      children: [
                        Text(
                          l10n.garageAddressesManageSubtitle,
                          style: AutolabCustomer.body.copyWith(
                            color: AutolabCustomer.customerSecondaryTextColor(
                              context,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AutolabCustomer.spacingMd),
                        if (locations.isEmpty)
                          _AddressesMessage(
                            icon: Icons.location_on_outlined,
                            title: l10n.garageAddressesEmptyTitle,
                            message: l10n.garageAddressesEmptyMessage,
                          )
                        else
                          for (final location in locations)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AutolabCustomer.spacingSmd,
                              ),
                              child: BlocBuilder<LocationCubit, LocationState>(
                                builder: (context, locationState) {
                                  return _DeliveryAddressCard(
                                    location: location,
                                    isActive: _isActiveLocation(
                                      location,
                                      locationState.location,
                                    ),
                                    onSelect: () => _selectLocation(location),
                                    onEdit: () =>
                                        _openAddressForm(location: location),
                                    onDelete: () => _confirmDelete(location),
                                  );
                                },
                              ),
                            ),
                        const SizedBox(height: AutolabCustomer.spacingXxl),
                        _AddAddressButton(onPressed: () => _openAddressForm()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isActiveLocation(CustomerLocation saved, CurrentLocation? active) {
  if (active == null) {
    return false;
  }

  const tolerance = 0.000001;
  return (saved.latitude - active.latitude).abs() < tolerance &&
      (saved.longitude - active.longitude).abs() < tolerance;
}

class _AddressesHeader extends StatelessWidget {
  const _AddressesHeader({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.onBack,
  });

  final String title;
  final String addLabel;
  final VoidCallback onAdd;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AutolabCustomer.responsiveScreenMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AutolabCustomer.spacingSm,
        horizontalPadding,
        AutolabCustomer.spacingSm,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _AddressesBackButton(onPressed: onBack),
              ),
              const AutolabLogoMark(width: 96, height: 36),
            ],
          ),
          const SizedBox(height: AutolabCustomer.spacingLg),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AutolabCustomer.h2.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                  foregroundColor: AutolabCustomer.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AutolabCustomer.spacingSm,
                  ),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  addLabel,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressesBackButton extends StatelessWidget {
  const _AddressesBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 36,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AutolabCustomer.customerSecondaryTextColor(context),
            size: AutolabCustomer.iconSm,
          ),
        ),
      ),
    );
  }
}

class _AddAddressButton extends StatelessWidget {
  const _AddAddressButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: AutolabCustomer.primaryButton,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: Text(
          l10n.garageAddressesAddNewAction,
          style: AutolabCustomer.bodyLarge.copyWith(
            color: AutolabCustomer.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AddressIconBadge extends StatelessWidget {
  const _AddressIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AutolabCustomer.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: AutolabCustomer.primary.withValues(alpha: 0.45),
        ),
      ),
      child: const Icon(
        Icons.location_on_outlined,
        color: AutolabCustomer.primary,
        size: AutolabCustomer.iconMd,
      ),
    );
  }
}

class _AddressCircleAction extends StatelessWidget {
  const _AddressCircleAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive
        ? AutolabCustomer.primary
        : AutolabCustomer.customerTextColor(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: destructive
            ? AutolabCustomer.primary.withValues(alpha: 0.12)
            : AutolabCustomer.customerSurfaceColor(context),
        shape: CircleBorder(
          side: BorderSide(
            color: destructive
                ? AutolabCustomer.primary.withValues(alpha: 0.45)
                : AutolabCustomer.customerBorderColor(context),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 48,
            child: Icon(icon, color: foreground, size: AutolabCustomer.iconSm),
          ),
        ),
      ),
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({
    required this.location,
    required this.isActive,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomerLocation location;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        child: Ink(
          padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            border: Border.all(
              color: isActive
                  ? AutolabCustomer.primary.withValues(alpha: 0.85)
                  : AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _AddressIconBadge(),
              const SizedBox(width: AutolabCustomer.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      location.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      _DefaultBadge(label: l10n.garageLocationsActiveLabel),
                    ],
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    Text(
                      location.address,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.body.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSmd),
              _AddressCircleAction(
                icon: Icons.edit_outlined,
                tooltip: l10n.cartEditAddressAction,
                onPressed: onEdit,
              ),
              const SizedBox(width: AutolabCustomer.spacingSm),
              _AddressCircleAction(
                icon: Icons.delete_outline_rounded,
                tooltip: l10n.cartDeleteAddressConfirm,
                onPressed: onDelete,
                destructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AutolabCustomer.spacingSm,
        vertical: AutolabCustomer.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AutolabCustomer.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusChip),
      ),
      child: Text(
        label,
        style: AutolabCustomer.label.copyWith(
          color: AutolabCustomer.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _UserLocationFormSheet extends StatefulWidget {
  const _UserLocationFormSheet({
    required this.onSave,
    required this.geocodingClient,
    this.location,
  });

  final CustomerLocation? location;
  final Future<CustomerLocation> Function(CustomerLocationRequest request)
  onSave;
  final GeocodingClient geocodingClient;

  @override
  State<_UserLocationFormSheet> createState() => _UserLocationFormSheetState();
}

class _UserLocationFormSheetState extends State<_UserLocationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _countryController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cantonController;
  late final TextEditingController _districtController;
  late final TextEditingController _exactAddressController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _labelController = TextEditingController(text: location?.label ?? '');
    _countryController = TextEditingController(
      text: location?.country.trim().isNotEmpty == true
          ? location!.country
          : 'Costa Rica',
    );
    _provinceController = TextEditingController(text: location?.province ?? '');
    _cantonController = TextEditingController(text: location?.canton ?? '');
    _districtController = TextEditingController(text: location?.district ?? '');
    _exactAddressController = TextEditingController(
      text: location?.exactAddress ?? '',
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _countryController.dispose();
    _provinceController.dispose();
    _cantonController.dispose();
    _districtController.dispose();
    _exactAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AutolabCustomer.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AutolabCustomer.customerDividerColor(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.location == null
                            ? l10n.garageLocationsNewTitle
                            : l10n.garageLocationsEditTitle,
                        style: AutolabCustomer.h3.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AutolabCustomer.customerBackgroundColor(context),
                        foregroundColor:
                            AutolabCustomer.customerSecondaryTextColor(context),
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AutolabCustomer.spacingSmd),
                _AddressDetailsField(
                  controller: _labelController,
                  label: l10n.garageLocationsLabelField,
                  hintText: l10n.garageLocationsLabelHint,
                  requiredField: false,
                ),
                _AddressDetailsField(
                  controller: _countryController,
                  label: l10n.garageLocationsCountryField,
                  hintText: l10n.garageLocationsCountryHint,
                ),
                _AddressDetailsField(
                  controller: _provinceController,
                  label: l10n.garageLocationsProvinceField,
                  hintText: l10n.garageLocationsProvinceHint,
                ),
                _AddressDetailsField(
                  controller: _cantonController,
                  label: l10n.garageLocationsCantonField,
                  hintText: l10n.garageLocationsCantonHint,
                ),
                _AddressDetailsField(
                  controller: _districtController,
                  label: l10n.garageLocationsDistrictField,
                  hintText: l10n.garageLocationsDistrictHint,
                ),
                _AddressDetailsField(
                  controller: _exactAddressController,
                  label: l10n.garageLocationsExactAddressField,
                  hintText: l10n.garageLocationsExactAddressHint,
                  maxLines: 2,
                  requiredField: false,
                ),
                const SizedBox(height: AutolabCustomer.spacingSm),
                Text(
                  l10n.garageLocationsGeocodeHint,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingMd),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: AutolabCustomer.primaryButton,
                    onPressed: _isSaving ? null : _save,
                    child: Text(
                      _isSaving
                          ? l10n.garageLocationsSavingAction
                          : l10n.garageLocationsSaveAction,
                      style: AutolabCustomer.body.copyWith(
                        color: AutolabCustomer.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final country = _countryController.text.trim();
      final province = _provinceController.text.trim();
      final canton = _cantonController.text.trim();
      final district = _districtController.text.trim();
      final exactAddress = _exactAddressController.text.trim();
      final address = [
        exactAddress,
        district,
        canton,
        province,
        country,
      ].where((part) => part.isNotEmpty).join(', ');
      final locations = await widget.geocodingClient.locationFromAddress(
        address,
      );
      if (locations.isEmpty) {
        throw StateError('location_not_found');
      }

      final resolvedLocation = locations.first;
      final savedLocation = await widget.onSave(
        CustomerLocationRequest(
          label: _labelController.text,
          address: address,
          country: country,
          province: province,
          canton: canton,
          district: district,
          exactAddress: exactAddress,
          latitude: resolvedLocation.latitude,
          longitude: resolvedLocation.longitude,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, savedLocation);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.garageLocationsSaveError,
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _AddressDetailsField extends StatelessWidget {
  const _AddressDetailsField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.hintText,
    this.requiredField = true,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? hintText;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingSm),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: AutolabCustomer.body.copyWith(
          color: AutolabCustomer.customerTextColor(context),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? (requiredField ? l10n.cartFieldRequired : null)
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: AutolabCustomer.body.copyWith(
            color: AutolabCustomer.customerSecondaryTextColor(context),
          ),
          hintStyle: AutolabCustomer.caption.copyWith(
            color: AutolabCustomer.customerHintColor(context),
          ),
          filled: true,
          fillColor: AutolabCustomer.customerBackgroundColor(context),
          border: _addressInputBorder(context),
          enabledBorder: _addressInputBorder(context),
          errorBorder: _addressInputBorder(
            context,
            color: AutolabCustomer.error,
          ),
          focusedErrorBorder: _addressInputBorder(
            context,
            color: AutolabCustomer.error,
            width: 1.5,
          ),
          focusedBorder: _addressInputBorder(
            context,
            color: AutolabCustomer.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _AddressesMessage extends StatelessWidget {
  const _AddressesMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AutolabCustomer.primary, size: 58),
            const SizedBox(height: AutolabCustomer.spacingMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AutolabCustomer.h3.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AutolabCustomer.spacingLg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AutolabCustomer.primary,
                  foregroundColor: AutolabCustomer.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

OutlineInputBorder _addressInputBorder(
  BuildContext context, {
  Color? color,
  double width = 1,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
    borderSide: BorderSide(
      color: color ?? AutolabCustomer.customerBorderColor(context),
      width: width,
    ),
  );
}
