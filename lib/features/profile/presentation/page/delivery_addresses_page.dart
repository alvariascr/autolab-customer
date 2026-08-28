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

part 'delivery_addresses_widgets.dart';
part 'delivery_addresses_form.dart';
part 'delivery_addresses_messages.dart';

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
