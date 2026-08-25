import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/domain/entities/cart_checkout.dart';
import '../../../cart/domain/usecases/delete_delivery_address.dart';
import '../../../cart/domain/usecases/load_delivery_addresses.dart';
import '../../../cart/domain/usecases/save_delivery_address.dart';
import '../../../cart/domain/usecases/set_default_delivery_address.dart';
import '../widgets/customer_page_header.dart';

class DeliveryAddressesPage extends StatefulWidget {
  const DeliveryAddressesPage({super.key});

  static const routePath = '/addresses';

  @override
  State<DeliveryAddressesPage> createState() => _DeliveryAddressesPageState();
}

class _DeliveryAddressesPageState extends State<DeliveryAddressesPage> {
  late Future<List<CustomerDeliveryAddress>> _addressesFuture;

  LoadDeliveryAddresses get _loadAddresses => sl<LoadDeliveryAddresses>();

  SaveDeliveryAddress get _saveAddress => sl<SaveDeliveryAddress>();

  SetDefaultDeliveryAddress get _setDefaultAddress =>
      sl<SetDefaultDeliveryAddress>();

  DeleteDeliveryAddress get _deleteAddress => sl<DeleteDeliveryAddress>();

  @override
  void initState() {
    super.initState();
    _addressesFuture = _loadAddresses();
  }

  void _reload() {
    setState(() {
      _addressesFuture = _loadAddresses();
    });
  }

  Future<void> _openAddressForm({CustomerDeliveryAddress? address}) async {
    final wasSaved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AutolabCustomer.customerSurfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AutolabCustomer.radiusLg),
        ),
      ),
      builder: (context) {
        return _DeliveryAddressFormSheet(
          address: address,
          onSave: (request) => _saveAddress(request, addressId: address?.id),
        );
      },
    );

    if (wasSaved == true && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.garageAddressesSaveSuccess)),
        );
      _reload();
    }
  }

  Future<void> _setDefault(CustomerDeliveryAddress address) async {
    if (address.isDefault) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _setDefaultAddress(address.id);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.garageAddressesDefaultSuccess)),
        );
      _reload();
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.cartSaveAddressError)));
    }
  }

  Future<void> _confirmDelete(CustomerDeliveryAddress address) async {
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
            l10n.cartDeleteAddressTitle,
            style: AutolabCustomer.h3.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            l10n.cartDeleteAddressMessage,
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
      await _deleteAddress(address.id);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.cartDeleteAddressSuccess)));
      _reload();
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.cartDeleteAddressError)));
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
            CustomerPageHeader(
              title: l10n.garageAddresses,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            Expanded(
              child: FutureBuilder<List<CustomerDeliveryAddress>>(
                future: _addressesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _AddressesMessage(
                      icon: Icons.error_outline_rounded,
                      title: l10n.favoritesLoadErrorTitle,
                      message: l10n.myAppointmentsRetryMessage,
                      actionLabel: l10n.myAppointmentsRetryAction,
                      onAction: _reload,
                    );
                  }

                  final addresses =
                      snapshot.data ?? const <CustomerDeliveryAddress>[];

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
                        _AddressesSummary(
                          count: addresses.length,
                          onAdd: () => _openAddressForm(),
                        ),
                        const SizedBox(height: AutolabCustomer.spacingSmd),
                        if (addresses.isEmpty)
                          _AddressesMessage(
                            icon: Icons.location_on_outlined,
                            title: l10n.garageAddressesEmptyTitle,
                            message: l10n.garageAddressesEmptyMessage,
                          )
                        else
                          for (final address in addresses)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AutolabCustomer.spacingSmd,
                              ),
                              child: _DeliveryAddressCard(
                                address: address,
                                onEdit: () =>
                                    _openAddressForm(address: address),
                                onDelete: () => _confirmDelete(address),
                                onSetDefault: () => _setDefault(address),
                              ),
                            ),
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

class _AddressesSummary extends StatelessWidget {
  const _AddressesSummary({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.garageAddressesCount(count),
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            backgroundColor: AutolabCustomer.primary,
            foregroundColor: AutolabCustomer.white,
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.garageAddressesAddAction),
        ),
      ],
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final CustomerDeliveryAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
          border: Border.all(
            color: address.isDefault
                ? AutolabCustomer.primary
                : AutolabCustomer.customerBorderColor(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AutolabCustomer.primary,
                  size: AutolabCustomer.iconSm,
                ),
                const SizedBox(width: AutolabCustomer.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              address.shortLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AutolabCustomer.bodyLarge.copyWith(
                                color: AutolabCustomer.customerTextColor(
                                  context,
                                ),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (address.isDefault)
                            _DefaultBadge(
                              label: l10n.garageAddressesDefaultLabel,
                            ),
                        ],
                      ),
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      Text(
                        address.summary,
                        style: AutolabCustomer.caption.copyWith(
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      Text(
                        address.phone,
                        style: AutolabCustomer.caption.copyWith(
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AutolabCustomer.spacingMd),
            if (!address.isDefault) ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: AutolabCustomer.primaryButton.copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
                    textStyle: WidgetStatePropertyAll(
                      AutolabCustomer.label.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  onPressed: onSetDefault,
                  child: Text(
                    l10n.garageAddressesSetDefaultAction,
                    style: AutolabCustomer.label.copyWith(
                      color: AutolabCustomer.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingXs),
            ],
            Row(
              children: [
                TextButton(
                  style: AutolabCustomer.ghostButton.copyWith(
                    foregroundColor: WidgetStatePropertyAll(
                      AutolabCustomer.customerTextColor(context),
                    ),
                    minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
                  ),
                  onPressed: onEdit,
                  child: Text(
                    l10n.cartEditAddressAction,
                    style: AutolabCustomer.label.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  style: AutolabCustomer.ghostButton.copyWith(
                    foregroundColor: const WidgetStatePropertyAll(
                      AutolabCustomer.primary,
                    ),
                    minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
                  ),
                  onPressed: onDelete,
                  child: Text(
                    l10n.cartDeleteAddressConfirm,
                    style: AutolabCustomer.label.copyWith(
                      color: AutolabCustomer.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
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

class _DeliveryAddressFormSheet extends StatefulWidget {
  const _DeliveryAddressFormSheet({required this.onSave, this.address});

  final CustomerDeliveryAddress? address;
  final Future<CustomerDeliveryAddress> Function(
    CustomerDeliveryAddressRequest request,
  )
  onSave;

  @override
  State<_DeliveryAddressFormSheet> createState() =>
      _DeliveryAddressFormSheetState();
}

class _DeliveryAddressFormSheetState extends State<_DeliveryAddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _provinceController;
  late final TextEditingController _cantonController;
  late final TextEditingController _districtController;
  late final TextEditingController _exactAddressController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _provinceController = TextEditingController(text: address?.province ?? '');
    _cantonController = TextEditingController(text: address?.canton ?? '');
    _districtController = TextEditingController(text: address?.district ?? '');
    _exactAddressController = TextEditingController(
      text: address?.exactAddress ?? '',
    );
    _phoneController = TextEditingController(text: address?.phone ?? '');
  }

  @override
  void dispose() {
    _provinceController.dispose();
    _cantonController.dispose();
    _districtController.dispose();
    _exactAddressController.dispose();
    _phoneController.dispose();
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
                        widget.address == null
                            ? l10n.garageAddressesNewTitle
                            : l10n.garageAddressesEditTitle,
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
                      onPressed: () => Navigator.pop(context, false),
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
                  controller: _provinceController,
                  label: l10n.cartProvinceLabel,
                ),
                _AddressDetailsField(
                  controller: _cantonController,
                  label: l10n.cartCantonLabel,
                ),
                _AddressDetailsField(
                  controller: _districtController,
                  label: l10n.cartDistrictLabel,
                ),
                _AddressDetailsField(
                  controller: _exactAddressController,
                  label: l10n.cartExactAddressLabel,
                  maxLines: 3,
                ),
                _AddressDetailsField(
                  controller: _phoneController,
                  label: l10n.cartPhoneLabel,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                  ],
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) {
                      return l10n.cartFieldRequired;
                    }
                    if (!RegExp(r'^[0-9+\s-]{8,15}$').hasMatch(phone)) {
                      return l10n.cartPhoneInvalid;
                    }
                    return null;
                  },
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
                          ? l10n.cartSavingAddressAction
                          : l10n.cartSaveAddressAction,
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
      await widget.onSave(
        CustomerDeliveryAddressRequest(
          province: _provinceController.text,
          canton: _cantonController.text,
          district: _districtController.text,
          exactAddress: _exactAddressController.text,
          phone: _phoneController.text,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cartSaveAddressError),
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
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingSm),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: AutolabCustomer.body.copyWith(
          color: AutolabCustomer.customerTextColor(context),
        ),
        validator:
            validator ??
            (value) => value == null || value.trim().isEmpty
                ? l10n.cartFieldRequired
                : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AutolabCustomer.body.copyWith(
            color: AutolabCustomer.customerSecondaryTextColor(context),
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
