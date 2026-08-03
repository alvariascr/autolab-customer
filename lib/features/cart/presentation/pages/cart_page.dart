import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/presentation/widgets/product_image.dart';
import '../../application/cart_cubit.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _showCheckout = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        final hasDeliveryAddress = cart.hasCompleteDeliveryDetails;
        final isCheckingOut = cart.checkoutStatus.isLoading;
        final canCheckout =
            cart.items.isNotEmpty &&
            !isCheckingOut &&
            (!_showCheckout || !cart.homeDelivery || hasDeliveryAddress);

        return Scaffold(
          backgroundColor: AutolabCustomer.customerBackgroundColor(context),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AutolabCustomer.responsiveScreenMargin(context),
                        AutolabCustomer.spacingSmd,
                        AutolabCustomer.responsiveScreenMargin(context),
                        AutolabCustomer.spacingLg,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _CartHeader(
                            title: _showCheckout
                                ? l10n.cartCheckoutTitle
                                : l10n.cartTitle,
                            subtitle: _showCheckout
                                ? null
                                : l10n.cartProductCount(cart.totalQuantity),
                            showBackButton:
                                widget.showBackButton || _showCheckout,
                            onBackTap: _showCheckout
                                ? () => setState(() => _showCheckout = false)
                                : () => Navigator.maybePop(context),
                          ),
                          const SizedBox(height: AutolabCustomer.spacingSmd),
                          _ShippingBanner(),
                          const SizedBox(height: AutolabCustomer.spacingSmd),
                          if (cart.items.isEmpty)
                            _EmptyCartState()
                          else if (_showCheckout)
                            _CartCheckoutView(cart: cart)
                          else
                            _CartItemsView(cart: cart),
                          const SizedBox(height: AutolabCustomer.spacingMd),
                          if (!_showCheckout && cart.items.isNotEmpty) ...[
                            _CartDeliverySection(cart: cart),
                            const SizedBox(height: AutolabCustomer.spacingSmd),
                            _CartSummaryCard(cart: cart, includeShipping: true),
                          ],
                          const SizedBox(height: AutolabCustomer.spacingSm),
                          _CartPrimaryButton(
                            label: _showCheckout
                                ? isCheckingOut
                                      ? l10n.cartCreatingOrder
                                      : l10n.cartFinishPurchase
                                : l10n.cartContinueToCheckout,
                            enabled: canCheckout,
                            onPressed: !canCheckout
                                ? null
                                : () {
                                    if (!_showCheckout) {
                                      setState(() => _showCheckout = true);
                                      return;
                                    }

                                    _createCartOrder(context);
                                  },
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
      },
    );
  }

  Future<void> _createCartOrder(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final cartCubit = context.read<CartCubit>();
    final result = await cartCubit.createOrder();

    if (!mounted) return;

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.cartCreateOrderError)),
      );
      return;
    }

    setState(() => _showCheckout = false);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.cartCreateOrderSuccess(result.orderNumber))),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({
    required this.title,
    required this.showBackButton,
    required this.onBackTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (showBackButton)
              Align(
                alignment: Alignment.centerLeft,
                child: _CartCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: onBackTap,
                ),
              ),
            const Center(child: AutolabLogoMark(width: 74, height: 28)),
          ],
        ),
        const SizedBox(height: AutolabCustomer.spacingSmd),
        Text(
          title,
          style: AutolabCustomer.h3.copyWith(
            color: AutolabCustomer.customerTextColor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AutolabCustomer.spacingXs),
          Text(
            subtitle!,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShippingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.successSoftBackground.withValues(
          alpha: AutolabCustomer.isDark(context) ? 0.12 : 1,
        ),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AutolabCustomer.spacingSmd,
          vertical: AutolabCustomer.spacingSm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              color: AutolabCustomer.success,
              size: AutolabCustomer.iconSm,
            ),
            const SizedBox(width: AutolabCustomer.spacingSm),
            Expanded(
              child: Text(
                l10n.cartFreeShippingBanner,
                style: AutolabCustomer.caption.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AutolabCustomer.customerSecondaryTextColor(context),
              size: AutolabCustomer.iconSm,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemsView extends StatelessWidget {
  const _CartItemsView({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cart.items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingSm),
              child: _CartItemCard(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _CartCheckoutView extends StatelessWidget {
  const _CartCheckoutView({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...cart.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingSm),
            child: _CartReviewItemCard(item: item),
          ),
        ),
        if (cart.homeDelivery && cart.hasCompleteDeliveryDetails) ...[
          const SizedBox(height: AutolabCustomer.spacingSm),
          _CartReviewInfoCard(
            title: l10n.cartDeliveryAddressDetails,
            icon: Icons.location_on_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cart.deliverySummary,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                Text(
                  cart.deliveryPhoneNumber,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AutolabCustomer.spacingLg),
        _CartSummaryCard(cart: cart, includeShipping: true),
      ],
    );
  }
}

class _CartReviewItemCard extends StatelessWidget {
  const _CartReviewItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ProductImage(
                imageUrl: product.primaryImageUrl,
                height: 72,
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                placeholderIconSize: AutolabCustomer.iconMd,
              ),
            ),
            const SizedBox(width: AutolabCustomer.spacingSmd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AutolabCustomer.body.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingXs),
                  Text(
                    product.effectiveDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AutolabCustomer.caption.copyWith(
                      color: AutolabCustomer.customerSecondaryTextColor(
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingSm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_formatCurrency(item.unitPrice)} x ${item.quantity}',
                          style: AutolabCustomer.caption.copyWith(
                            color: AutolabCustomer.customerSecondaryTextColor(
                              context,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _formatCurrency(item.lineSubtotal),
                        style: AutolabCustomer.body.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartReviewInfoCard extends StatelessWidget {
  const _CartReviewInfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AutolabCustomer.primary),
                const SizedBox(width: AutolabCustomer.spacingSm),
                Text(
                  title,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AutolabCustomer.spacingSm),
            child,
          ],
        ),
      ),
    );
  }
}

class _CartDeliverySection extends StatelessWidget {
  const _CartDeliverySection({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.cartDeliveryServiceTitle,
                        style: AutolabCustomer.bodyLarge.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      Text(
                        cart.homeDelivery
                            ? l10n.cartDeliveryAddressDetails
                            : l10n.cartDeliveryDisabledMessage,
                        style: AutolabCustomer.caption.copyWith(
                          color: cart.homeDelivery
                              ? AutolabCustomer.primary
                              : AutolabCustomer.customerSecondaryTextColor(
                                  context,
                                ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: cart.homeDelivery,
                  activeThumbColor: AutolabCustomer.white,
                  activeTrackColor: AutolabCustomer.primary,
                  onChanged: context.read<CartCubit>().setHomeDelivery,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: cart.homeDelivery
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: AutolabCustomer.spacingSm,
                      ),
                      child: Column(
                        children: [
                          if (cart.deliveryAddresses.isNotEmpty) ...[
                            _SavedDeliveryAddressesList(cart: cart),
                            const SizedBox(height: AutolabCustomer.spacingSm),
                          ],
                          _DeliveryAddressCard(cart: cart),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedDeliveryAddressesList extends StatelessWidget {
  const _SavedDeliveryAddressesList({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.cartSavedAddressesTitle,
                style: AutolabCustomer.caption.copyWith(
                  color: AutolabCustomer.customerSecondaryTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<CartCubit>().startNewDeliveryAddress();
                _showDeliveryDetailsSheet(
                  context,
                  context.read<CartCubit>().state,
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.cartNewAddressAction,
                style: AutolabCustomer.caption.copyWith(
                  color: AutolabCustomer.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AutolabCustomer.spacingXs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cart.deliveryAddresses
                .map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(
                      right: AutolabCustomer.spacingXs,
                    ),
                    child: ChoiceChip(
                      selected: address.id == cart.selectedDeliveryAddressId,
                      label: Text(address.shortLabel),
                      onSelected: (_) => context
                          .read<CartCubit>()
                          .selectDeliveryAddress(address),
                      selectedColor: AutolabCustomer.primary,
                      backgroundColor: AutolabCustomer.customerBackgroundColor(
                        context,
                      ),
                      labelStyle: AutolabCustomer.caption.copyWith(
                        color: address.id == cart.selectedDeliveryAddressId
                            ? AutolabCustomer.white
                            : AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                      side: BorderSide(
                        color: address.id == cart.selectedDeliveryAddressId
                            ? AutolabCustomer.primary
                            : AutolabCustomer.customerBorderColor(context),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasDetails = cart.hasCompleteDeliveryDetails;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerBackgroundColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(
          color: hasDetails
              ? AutolabCustomer.customerBorderColor(context)
              : AutolabCustomer.error,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on_outlined,
              color: hasDetails
                  ? AutolabCustomer.primary
                  : AutolabCustomer.error,
              size: AutolabCustomer.iconSm,
            ),
            const SizedBox(width: AutolabCustomer.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDetails
                        ? cart.deliverySummary
                        : l10n.cartAddressRequired,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AutolabCustomer.body.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (cart.deliveryPhoneNumber.trim().isNotEmpty) ...[
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    Text(
                      cart.deliveryPhoneNumber,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showDeliveryDetailsSheet(context, cart),
              style: TextButton.styleFrom(
                foregroundColor: AutolabCustomer.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AutolabCustomer.spacingSm,
                ),
              ),
              child: Text(
                hasDetails
                    ? l10n.cartEditAddressAction
                    : l10n.cartAddAddressAction,
                style: AutolabCustomer.caption.copyWith(
                  color: AutolabCustomer.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showDeliveryDetailsSheet(BuildContext context, CartState cart) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AutolabCustomer.transparent,
    builder: (sheetContext) {
      return _DeliveryDetailsSheet(cart: cart);
    },
  );
}

class _DeliveryDetailsSheet extends StatefulWidget {
  const _DeliveryDetailsSheet({required this.cart});

  final CartState cart;

  @override
  State<_DeliveryDetailsSheet> createState() => _DeliveryDetailsSheetState();
}

class _DeliveryDetailsSheetState extends State<_DeliveryDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  late final TextEditingController _provinceController;
  late final TextEditingController _cantonController;
  late final TextEditingController _districtController;
  late final TextEditingController _exactAddressController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final cart = widget.cart;
    _provinceController = TextEditingController(text: cart.deliveryProvince);
    _cantonController = TextEditingController(text: cart.deliveryCanton);
    _districtController = TextEditingController(text: cart.deliveryDistrict);
    _exactAddressController = TextEditingController(
      text: cart.deliveryExactAddress,
    );
    _phoneController = TextEditingController(text: cart.deliveryPhoneNumber);
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AutolabCustomer.customerSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AutolabCustomer.radiusModal),
          ),
        ),
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
                          l10n.cartDeliveryFormTitle,
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
                              AutolabCustomer.customerSecondaryTextColor(
                                context,
                              ),
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AutolabCustomer.spacingSmd),
                  _DeliveryDetailsField(
                    controller: _provinceController,
                    label: l10n.cartProvinceLabel,
                  ),
                  _DeliveryDetailsField(
                    controller: _cantonController,
                    label: l10n.cartCantonLabel,
                  ),
                  _DeliveryDetailsField(
                    controller: _districtController,
                    label: l10n.cartDistrictLabel,
                  ),
                  _DeliveryDetailsField(
                    controller: _exactAddressController,
                    label: l10n.cartExactAddressLabel,
                    maxLines: 3,
                  ),
                  _DeliveryDetailsField(
                    controller: _phoneController,
                    label: l10n.cartPhoneLabel,
                    keyboardType: TextInputType.phone,
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
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<CartCubit>().saveDeliveryAddress(
        province: _provinceController.text,
        canton: _cantonController.text,
        district: _districtController.text,
        exactAddress: _exactAddressController.text,
        phoneNumber: _phoneController.text,
      );
      if (!mounted) return;

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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

class _DeliveryDetailsField extends StatelessWidget {
  const _DeliveryDetailsField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingSm),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AutolabCustomer.body.copyWith(
          color: AutolabCustomer.customerTextColor(context),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? l10n.cartFieldRequired
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AutolabCustomer.body.copyWith(
            color: AutolabCustomer.customerSecondaryTextColor(context),
          ),
          filled: true,
          fillColor: AutolabCustomer.customerBackgroundColor(context),
          border: _cartInputBorder(context),
          enabledBorder: _cartInputBorder(context),
          errorBorder: _cartInputBorder(context, color: AutolabCustomer.error),
          focusedErrorBorder: _cartInputBorder(
            context,
            color: AutolabCustomer.error,
            width: 1.5,
          ),
          focusedBorder: _cartInputBorder(
            context,
            color: AutolabCustomer.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ProductImage(
                imageUrl: product.primaryImageUrl,
                height: 72,
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                placeholderIconSize: AutolabCustomer.iconMd,
              ),
            ),
            const SizedBox(width: AutolabCustomer.spacingSmd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AutolabCustomer.body.copyWith(
                            color: AutolabCustomer.customerTextColor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            context.read<CartCubit>().removeProduct(product.id),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                          size: AutolabCustomer.iconSm,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    product.effectiveDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AutolabCustomer.caption.copyWith(
                      color: AutolabCustomer.customerSecondaryTextColor(
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingXs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatCurrency(item.unitPrice),
                          style: AutolabCustomer.body.copyWith(
                            color: AutolabCustomer.customerSecondaryTextColor(
                              context,
                            ),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _QuantityStepper(item: item),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerBackgroundColor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove_rounded,
            onPressed: () =>
                context.read<CartCubit>().decreaseQuantity(item.product.id),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AutolabCustomer.spacingSm,
            ),
            child: Text(
              item.quantity.toString(),
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _QuantityButton(
            icon: Icons.add_rounded,
            onPressed: () =>
                context.read<CartCubit>().increaseQuantity(item.product.id),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingXs),
        child: Icon(
          icon,
          color: AutolabCustomer.primary,
          size: AutolabCustomer.iconXs,
        ),
      ),
    );
  }
}

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({required this.cart, this.includeShipping = false});

  final CartState cart;
  final bool includeShipping;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cartSummaryTitle,
              style: AutolabCustomer.bodyLarge.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingSm),
            _SummaryRow(
              label: l10n.cartSubtotal(cart.totalQuantity),
              value: _formatCurrency(cart.subtotal),
            ),
            if (includeShipping)
              _SummaryRow(
                label: l10n.cartShipping,
                value: cart.homeDelivery && cart.shippingCost == 0
                    ? l10n.cartFreeShipping
                    : _formatCurrency(cart.shippingCost),
                highlight: cart.homeDelivery && cart.shippingCost == 0,
              ),
            _SummaryRow(
              label: l10n.cartTaxes,
              value: _formatCurrency(cart.taxes),
            ),
            Divider(color: AutolabCustomer.customerDividerColor(context)),
            _SummaryRow(
              label: l10n.cartTotal,
              value: _formatCurrency(cart.total),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? AutolabCustomer.primary
        : AutolabCustomer.customerTextColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingXs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: AutolabCustomer.body.copyWith(
              color: color,
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPrimaryButton extends StatelessWidget {
  const _CartPrimaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AutolabCustomer.responsiveDouble(
        context,
        compact: 52,
        regular: 56,
        tablet: 60,
      ),
      child: ElevatedButton(
        style: AutolabCustomer.primaryButton.copyWith(
          backgroundColor: WidgetStatePropertyAll(
            enabled
                ? AutolabCustomer.primary
                : AutolabCustomer.customerDisabledTextColor(context),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: AutolabCustomer.bodyLarge.copyWith(
            color: AutolabCustomer.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AutolabCustomer.spacingXxl),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: AutolabCustomer.primary,
            size: AutolabCustomer.iconLg * 2,
          ),
          const SizedBox(height: AutolabCustomer.spacingMd),
          Text(
            l10n.cartEmptyTitle,
            textAlign: TextAlign.center,
            style: AutolabCustomer.h3.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AutolabCustomer.spacingSm),
          Text(
            l10n.cartEmptyMessage,
            textAlign: TextAlign.center,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartCircleButton extends StatelessWidget {
  const _CartCircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AutolabCustomer.customerSurfaceColor(context),
          foregroundColor: AutolabCustomer.customerSecondaryTextColor(context),
        ),
        icon: Icon(icon, size: AutolabCustomer.iconXs),
      ),
    );
  }
}

String _formatCurrency(double value) {
  return '₡${value.toStringAsFixed(0)}';
}

OutlineInputBorder _cartInputBorder(
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
