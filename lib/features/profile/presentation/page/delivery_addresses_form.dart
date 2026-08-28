part of 'delivery_addresses_page.dart';

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
