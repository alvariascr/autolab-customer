import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../payments/application/laropay_checkout_launcher.dart';
import '../../../payments/application/laropay_return_navigation_controller.dart';
import '../../../products/presentation/widgets/product_image.dart';
import '../../application/cart_cubit.dart';
import '../../domain/entities/cart_checkout.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with WidgetsBindingObserver {
  static const _checkoutLaunchTimeout = Duration(seconds: 45);
  static const _externalCheckoutTransitionTimeout = Duration(seconds: 5);
  static const _paymentReturnFallbackDelay = Duration(seconds: 3);

  bool _showCheckout = false;
  String? _selectedWorkshopId;
  _CartCheckoutLoadingPhase? _checkoutLoadingPhase;
  Completer<void>? _externalCheckoutTransitionCompleter;
  Timer? _checkoutReturnFallbackTimer;
  bool _awaitingCheckoutReturn = false;
  bool _checkoutReturnFallbackScheduled = false;
  int? _checkoutReturnBaselineCallbackCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelCheckoutReturnFallback();
    _completeExternalCheckoutTransition();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _completeExternalCheckoutTransition();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _handleCheckoutReturnIfAbandoned();
    }
  }

  // Called when the app comes back to the foreground while a Laropay
  // checkout was in flight. A brief delay gives a deep-link payment result
  // (which navigates on its own) a chance to arrive first; if nothing
  // arrives, the customer closed the gateway without finishing.
  void _handleCheckoutReturnIfAbandoned() {
    if (!_awaitingCheckoutReturn) {
      return;
    }
    if (_checkoutReturnFallbackScheduled) {
      return;
    }
    _checkoutReturnFallbackScheduled = true;

    // The gateway is no longer "opening" once we're back -- update the
    // overlay copy so it doesn't read as if we're about to reopen it while
    // we briefly wait to see whether a real result is on its way.
    setState(
      () => _checkoutLoadingPhase = _CartCheckoutLoadingPhase.confirmingReturn,
    );

    final baselineCallbackCount = _checkoutReturnBaselineCallbackCount;

    _checkoutReturnFallbackTimer = Timer(_paymentReturnFallbackDelay, () {
      if (!mounted || !_awaitingCheckoutReturn) {
        return;
      }
      if (LaropayReturnNavigationController.handledCallbackCount.value !=
          baselineCallbackCount) {
        // A real Laropay deep-link result was processed while we were
        // waiting -- it owns navigation, not this fallback.
        _awaitingCheckoutReturn = false;
        _cancelCheckoutReturnFallback();
        return;
      }
      _awaitingCheckoutReturn = false;
      _cancelCheckoutReturnFallback();
      final l10n = AppLocalizations.of(context)!;
      setState(() => _checkoutLoadingPhase = null);
      showAppSnackBar(
        context,
        message: l10n.laropayPaymentGatewayClosedMessage,
        type: AppMessageType.warning,
      );
      context.go('/purchases');
    });
  }

  void _startAwaitingCheckoutReturn() {
    _cancelCheckoutReturnFallback();
    _checkoutReturnBaselineCallbackCount =
        LaropayReturnNavigationController.handledCallbackCount.value;
    _awaitingCheckoutReturn = true;
  }

  void _cancelCheckoutReturnFallback() {
    _checkoutReturnFallbackTimer?.cancel();
    _checkoutReturnFallbackTimer = null;
    _checkoutReturnFallbackScheduled = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        final workshopCarts = cart.workshopCarts;
        final selectedWorkshopId = _resolveSelectedWorkshopId(
          cart,
          workshopCarts,
        );
        final isShowingCartList =
            cart.items.isNotEmpty &&
            workshopCarts.length > 1 &&
            selectedWorkshopId == null;
        final activeCart = selectedWorkshopId == null
            ? cart
            : cart.forWorkshop(selectedWorkshopId);
        final showCheckout =
            _showCheckout && !isShowingCartList && activeCart.items.isNotEmpty;
        final hasDeliveryAddress = activeCart.hasCompleteDeliveryDetails;
        final isCheckingOut = cart.checkoutStatus.isLoading;
        final showPaymentLoading =
            isCheckingOut || _checkoutLoadingPhase != null;
        final canCheckout =
            activeCart.items.isNotEmpty &&
            !showPaymentLoading &&
            !isShowingCartList &&
            (!showCheckout || !activeCart.homeDelivery || hasDeliveryAddress);
        final showBackButton =
            widget.showBackButton ||
            showCheckout ||
            (selectedWorkshopId != null && workshopCarts.length > 1);

        return Scaffold(
          backgroundColor: AutolabCustomer.customerBackgroundColor(context),
          body: SafeArea(
            child: Stack(
              children: [
                Center(
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
                            AutolabCustomer.spacingLg +
                                MediaQuery.paddingOf(context).bottom +
                                kBottomNavigationBarHeight,
                          ),
                          sliver: SliverList.list(
                            children: [
                              _CartHeader(
                                title: showCheckout
                                    ? l10n.cartCheckoutTitle
                                    : isShowingCartList
                                    ? l10n.cartCartsTitle
                                    : l10n.cartTitle,
                                subtitle: showCheckout || isShowingCartList
                                    ? null
                                    : l10n.cartProductCount(
                                        activeCart.totalQuantity,
                                      ),
                                showBackButton: showBackButton,
                                onBackTap: showCheckout
                                    ? () =>
                                          setState(() => _showCheckout = false)
                                    : selectedWorkshopId != null &&
                                          workshopCarts.length > 1
                                    ? () => setState(
                                        () => _selectedWorkshopId = null,
                                      )
                                    : () => Navigator.maybePop(context),
                              ),
                              const SizedBox(
                                height: AutolabCustomer.spacingSmd,
                              ),
                              if (cart.items.isEmpty)
                                _EmptyCartState()
                              else if (isShowingCartList)
                                _CartWorkshopCartsView(
                                  carts: workshopCarts,
                                  onOpenCart: _openWorkshopCart,
                                  onOpenWorkshop: _openWorkshop,
                                )
                              else if (showCheckout)
                                _CartCheckoutView(cart: activeCart)
                              else
                                _CartItemsView(cart: activeCart),
                              const SizedBox(height: AutolabCustomer.spacingMd),
                              if (!showCheckout &&
                                  !isShowingCartList &&
                                  activeCart.items.isNotEmpty) ...[
                                _CartDeliverySection(cart: activeCart),
                                const SizedBox(
                                  height: AutolabCustomer.spacingSmd,
                                ),
                                _CartSummaryCard(
                                  cart: activeCart,
                                  includeShipping: true,
                                ),
                              ],
                              const SizedBox(height: AutolabCustomer.spacingSm),
                              if (!isShowingCartList &&
                                  activeCart.items.isNotEmpty)
                                _CartPrimaryButton(
                                  label: showCheckout
                                      ? isCheckingOut
                                            ? l10n.cartCreatingOrder
                                            : l10n.cartFinishPurchase
                                      : l10n.cartContinueToCheckout,
                                  enabled: canCheckout,
                                  onPressed: !canCheckout
                                      ? null
                                      : () async {
                                          if (!showCheckout) {
                                            await context
                                                .read<CartCubit>()
                                                .refreshWorkshopDeliveryFee(
                                                  workshopId:
                                                      selectedWorkshopId,
                                                );
                                            if (!mounted) return;
                                            setState(
                                              () => _showCheckout = true,
                                            );
                                            return;
                                          }

                                          _createCartOrder(
                                            context,
                                            workshopId: selectedWorkshopId,
                                          );
                                        },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showPaymentLoading)
                  _CartCheckoutLoadingOverlay(
                    phase:
                        _checkoutLoadingPhase ??
                        _CartCheckoutLoadingPhase.creatingOrder,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _resolveSelectedWorkshopId(
    CartState cart,
    List<CartWorkshopCart> workshopCarts,
  ) {
    if (cart.items.isEmpty) {
      return null;
    }

    if (workshopCarts.length == 1) {
      return workshopCarts.single.workshopId;
    }

    final selectedWorkshopId = _selectedWorkshopId;
    if (selectedWorkshopId == null ||
        !workshopCarts.any((cart) => cart.workshopId == selectedWorkshopId)) {
      return null;
    }

    return selectedWorkshopId;
  }

  Future<void> _openWorkshopCart(String workshopId) async {
    setState(() {
      _selectedWorkshopId = workshopId;
      _showCheckout = false;
    });
    await context.read<CartCubit>().refreshWorkshopDeliveryFee(
      workshopId: workshopId,
    );
  }

  void _openWorkshop(String workshopId) {
    context.go('/workshops/$workshopId?section=products');
  }

  Future<void> _createCartOrder(
    BuildContext context, {
    required String? workshopId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final cartCubit = context.read<CartCubit>();
    final targetWorkshopId = workshopId?.trim().isNotEmpty == true
        ? workshopId!.trim()
        : cartCubit.state.singleWorkshopId;

    setState(
      () => _checkoutLoadingPhase = _CartCheckoutLoadingPhase.creatingOrder,
    );
    await WidgetsBinding.instance.endOfFrame;

    final result = await cartCubit.createOrder(workshopId: targetWorkshopId);

    if (!mounted || !context.mounted) return;

    if (result == null) {
      setState(() => _checkoutLoadingPhase = null);
      final errorMessage = _checkoutErrorMessage(
        l10n,
        cartCubit.state.checkoutError,
      );
      showAppSnackBar(
        context,
        message: errorMessage,
        type: AppMessageType.error,
      );
      return;
    }

    try {
      setState(
        () => _checkoutLoadingPhase = _CartCheckoutLoadingPhase.openingLaropay,
      );
      await WidgetsBinding.instance.endOfFrame;
      await sl<LaropayCheckoutLauncher>()
          .launchForOrder(orderId: result.orderId)
          .timeout(_checkoutLaunchTimeout);
      if (!mounted || !context.mounted) return;
      _startAwaitingCheckoutReturn();
      await _waitForExternalCheckoutTransition();
      if (!mounted || !context.mounted) return;
      if (targetWorkshopId == null) {
        cartCubit.clear();
      } else {
        cartCubit.clearWorkshop(targetWorkshopId);
      }
      setState(() {
        _showCheckout = false;
        _selectedWorkshopId = null;
      });
      // Keep the payment overlay visible; only navigate away if the
      // customer comes back without a payment result already having taken
      // over (see _handleCheckoutReturnIfAbandoned).
      _handleCheckoutReturnIfAbandoned();
    } on LaropayCheckoutLaunchException {
      if (!mounted || !context.mounted) return;
      setState(() => _checkoutLoadingPhase = null);
      await _showPaymentReviewDialog(
        context,
        cartCubit,
        result,
        targetWorkshopId,
      );
    } on TimeoutException {
      if (!mounted || !context.mounted) return;
      setState(() => _checkoutLoadingPhase = null);
      await _showPaymentReviewDialog(
        context,
        cartCubit,
        result,
        targetWorkshopId,
      );
    } catch (_) {
      if (!mounted || !context.mounted) return;
      setState(() => _checkoutLoadingPhase = null);
      await _showPaymentReviewDialog(
        context,
        cartCubit,
        result,
        targetWorkshopId,
      );
    }
  }

  Future<void> _waitForExternalCheckoutTransition() async {
    final transitionCompleter = Completer<void>();
    _externalCheckoutTransitionCompleter = transitionCompleter;

    try {
      await transitionCompleter.future.timeout(
        _externalCheckoutTransitionTimeout,
      );
    } on TimeoutException {
      // Some in-app browser implementations do not emit lifecycle changes.
      // Keep the payment overlay visible briefly, then continue with the
      // existing flow instead of leaving the customer blocked.
    } finally {
      if (identical(
        _externalCheckoutTransitionCompleter,
        transitionCompleter,
      )) {
        _externalCheckoutTransitionCompleter = null;
      }
    }
  }

  void _completeExternalCheckoutTransition() {
    final completer = _externalCheckoutTransitionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    if (identical(_externalCheckoutTransitionCompleter, completer)) {
      _externalCheckoutTransitionCompleter = null;
    }
  }

  Future<void> _showPaymentReviewDialog(
    BuildContext context,
    CartCubit cartCubit,
    CartCheckoutResult result,
    String? workshopId,
  ) async {
    if (workshopId == null) {
      cartCubit.clear();
    } else {
      cartCubit.clearWorkshop(workshopId);
    }
    setState(() {
      _showCheckout = false;
      _selectedWorkshopId = null;
    });
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _CartPaymentReviewDialog(result: result),
    );
  }

  String _checkoutErrorMessage(AppLocalizations l10n, String? errorKey) {
    return switch (errorKey) {
      'cart_product_stock_unavailable' => l10n.cartStockLimitReached,
      'cart_delivery_details_required' => l10n.cartAddressRequired,
      _ => l10n.cartCreateOrderError,
    };
  }
}

enum _CartCheckoutLoadingPhase {
  creatingOrder,
  openingLaropay,
  confirmingReturn,
}

class _CartCheckoutLoadingOverlay extends StatelessWidget {
  const _CartCheckoutLoadingOverlay({required this.phase});

  final _CartCheckoutLoadingPhase phase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (title, message) = switch (phase) {
      _CartCheckoutLoadingPhase.openingLaropay => (
        l10n.cartOpeningLaropayTitle,
        l10n.cartOpeningLaropayMessage,
      ),
      _CartCheckoutLoadingPhase.confirmingReturn => (
        l10n.cartConfirmingPaymentTitle,
        l10n.cartConfirmingPaymentMessage,
      ),
      _CartCheckoutLoadingPhase.creatingOrder => (
        l10n.cartCreatingOrder,
        l10n.cartCreatingOrderMessage,
      ),
    };

    return Positioned.fill(
      child: ColoredBox(
        color: AutolabCustomer.overlayBlackMedium,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AutolabCustomer.customerSurfaceColor(context),
              borderRadius: BorderRadius.circular(AutolabCustomer.radiusLg),
              boxShadow: AutolabCustomer.shadowLevel2,
              border: Border.all(
                color: AutolabCustomer.customerBorderColor(context),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AutolabCustomer.spacingLg,
                vertical: AutolabCustomer.spacingLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AutolabCustomer.primary,
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingMd),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AutolabCustomer.body.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingXs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        height: 1.25,
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
}

class _CartPaymentReviewDialog extends StatelessWidget {
  const _CartPaymentReviewDialog({required this.result});

  final CartCheckoutResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AutolabCustomer.transparent,
      insetPadding: const EdgeInsets.all(AutolabCustomer.spacingLg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AutolabCustomer.customerSurfaceColor(context),
          borderRadius: BorderRadius.circular(AutolabCustomer.radiusLg),
          border: Border.all(
            color: AutolabCustomer.customerBorderColor(context),
          ),
          boxShadow: AutolabCustomer.shadowLevel2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AutolabCustomer.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AutolabCustomer.warning, width: 5),
                ),
                child: Icon(
                  Icons.priority_high_rounded,
                  color: AutolabCustomer.warning,
                  size: AutolabCustomer.iconLg,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingLg),
              Text(
                l10n.cartPaymentReviewTitle,
                textAlign: TextAlign.center,
                style: AutolabCustomer.h3.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingSm),
              Text(
                l10n.cartPaymentReviewMessage,
                textAlign: TextAlign.center,
                style: AutolabCustomer.body.copyWith(
                  color: AutolabCustomer.customerSecondaryTextColor(context),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingLg),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AutolabCustomer.customerBackgroundColor(context),
                  borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
                  border: Border.all(
                    color: AutolabCustomer.customerBorderColor(context),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
                  child: Column(
                    children: [
                      _CartSuccessRow(
                        label: l10n.cartOrderNumberLabel,
                        value: result.orderNumber,
                      ),
                      const SizedBox(height: AutolabCustomer.spacingSm),
                      _CartSuccessRow(
                        label: l10n.cartTotal,
                        value: _formatCurrency(result.totalAmount),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingLg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: AutolabCustomer.primaryButton,
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cartPaymentReviewAction,
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
    );
  }
}

class _CartSuccessRow extends StatelessWidget {
  const _CartSuccessRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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

class _CartWorkshopCartsView extends StatelessWidget {
  const _CartWorkshopCartsView({
    required this.carts,
    required this.onOpenCart,
    required this.onOpenWorkshop,
  });

  final List<CartWorkshopCart> carts;
  final ValueChanged<String> onOpenCart;
  final ValueChanged<String> onOpenWorkshop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: carts
          .map(
            (cart) => Padding(
              padding: const EdgeInsets.only(bottom: AutolabCustomer.spacingSm),
              child: _CartWorkshopCartCard(
                cart: cart,
                onOpenCart: () => onOpenCart(cart.workshopId),
                onOpenWorkshop: () => onOpenWorkshop(cart.workshopId),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _CartWorkshopCartCard extends StatelessWidget {
  const _CartWorkshopCartCard({
    required this.cart,
    required this.onOpenCart,
    required this.onOpenWorkshop,
  });

  final CartWorkshopCart cart;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenWorkshop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workshopName = cart.workshopName.isEmpty
        ? l10n.mapSheetLabelWorkshop
        : cart.workshopName;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
        boxShadow: AutolabCustomer.shadowLevel1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CartWorkshopAvatar(cart: cart),
                const SizedBox(width: AutolabCustomer.spacingSmd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workshopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AutolabCustomer.bodyLarge.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AutolabCustomer.spacingXs),
                      Text(
                        '${l10n.cartProductCount(cart.totalQuantity)} - '
                        '${_formatCurrency(cart.productsTotal)}',
                        style: AutolabCustomer.body.copyWith(
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz_rounded,
                  color: AutolabCustomer.customerSecondaryTextColor(context),
                ),
              ],
            ),
            const SizedBox(height: AutolabCustomer.spacingSmd),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: AutolabCustomer.primaryButton,
                onPressed: onOpenCart,
                child: Text(
                  l10n.cartViewCartAction,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingSm),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: AutolabCustomer.secondaryButton.copyWith(
                  side: const WidgetStatePropertyAll(
                    BorderSide(color: AutolabCustomer.primary, width: 1.5),
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    AutolabCustomer.customerTextColor(context),
                  ),
                ),
                onPressed: onOpenWorkshop,
                child: Text(
                  l10n.cartViewWorkshopAction,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartWorkshopAvatar extends StatelessWidget {
  const _CartWorkshopAvatar({required this.cart});

  final CartWorkshopCart cart;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = cart.workshopAvatarUrl.trim();

    return CircleAvatar(
      radius: 30,
      backgroundColor: AutolabCustomer.customerSoftSurfaceColor(context),
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Icon(
              Icons.storefront_rounded,
              color: AutolabCustomer.primary,
              size: AutolabCustomer.iconMd,
            )
          : null,
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
    return _CartProductBaseCard(
      item: item,
      bottom: Row(
        children: [
          Expanded(
            child: Text(
              '${_formatCurrency(item.unitPrice)} x ${item.quantity}',
              style: AutolabCustomer.caption.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
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
    );
  }
}

class _CartProductBaseCard extends StatelessWidget {
  const _CartProductBaseCard({
    required this.item,
    required this.bottom,
    this.titleTrailing,
    this.descriptionSpacing = AutolabCustomer.spacingSm,
  });

  final CartItem item;
  final Widget bottom;
  final Widget? titleTrailing;
  final double descriptionSpacing;

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
                      ?titleTrailing,
                    ],
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
                  SizedBox(height: descriptionSpacing),
                  bottom,
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
                    child: InputChip(
                      selected: address.id == cart.selectedDeliveryAddressId,
                      label: Text(address.shortLabel),
                      onSelected: (_) => context
                          .read<CartCubit>()
                          .selectDeliveryAddress(address),
                      onDeleted: () =>
                          _confirmDeleteDeliveryAddress(context, address),
                      deleteIcon: Icon(
                        Icons.close_rounded,
                        size: AutolabCustomer.iconXs,
                        color: address.id == cart.selectedDeliveryAddressId
                            ? AutolabCustomer.white
                            : AutolabCustomer.customerTextColor(context),
                      ),
                      tooltip: l10n.vehiclesDeleteAction,
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

Future<void> _confirmDeleteDeliveryAddress(
  BuildContext context,
  CustomerDeliveryAddress address,
) async {
  final l10n = AppLocalizations.of(context)!;
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AutolabCustomer.customerSurfaceColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AutolabCustomer.radiusLg),
          side: BorderSide(color: AutolabCustomer.customerBorderColor(context)),
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
            child: Text(
              l10n.cartDeleteAddressCancel,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.cartDeleteAddressConfirm,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (shouldDelete != true || !context.mounted) {
    return;
  }

  final wasDeleted = await context.read<CartCubit>().deleteDeliveryAddress(
    address.id,
  );

  if (!wasDeleted && context.mounted) {
    showAppSnackBar(
      context,
      message: l10n.cartDeleteAddressError,
      type: AppMessageType.error,
    );
  } else if (context.mounted) {
    showAppSnackBar(
      context,
      message: l10n.cartDeleteAddressSuccess,
      type: AppMessageType.success,
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
  final cartCubit = context.read<CartCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AutolabCustomer.transparent,
    builder: (sheetContext) {
      return _DeliveryDetailsSheet(cart: cart, cartCubit: cartCubit);
    },
  );
}

class _DeliveryDetailsSheet extends StatefulWidget {
  const _DeliveryDetailsSheet({required this.cart, required this.cartCubit});

  final CartState cart;
  final CartCubit cartCubit;

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
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _isSaving = true);
    final wasSaved = await widget.cartCubit.saveDeliveryAddress(
      province: _provinceController.text,
      canton: _cantonController.text,
      district: _districtController.text,
      exactAddress: _exactAddressController.text,
      phoneNumber: _phoneController.text,
    );
    if (!mounted) return;

    if (wasSaved) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      return;
    } else {
      showAppSnackBar(
        context,
        message: AppLocalizations.of(context)!.cartSaveAddressError,
        type: AppMessageType.error,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}

class _DeliveryDetailsField extends StatelessWidget {
  const _DeliveryDetailsField({
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

    return _CartProductBaseCard(
      item: item,
      descriptionSpacing: AutolabCustomer.spacingXs,
      titleTrailing: IconButton(
        tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
        visualDensity: VisualDensity.compact,
        onPressed: () => context.read<CartCubit>().removeProduct(product.id),
        icon: Icon(
          Icons.delete_outline_rounded,
          color: AutolabCustomer.customerSecondaryTextColor(context),
          size: AutolabCustomer.iconSm,
        ),
      ),
      bottom: Row(
        children: [
          Expanded(
            child: Text(
              _formatCurrency(item.unitPrice),
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _QuantityStepper(item: item),
        ],
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
            onPressed: () {
              final wasIncreased = context.read<CartCubit>().increaseQuantity(
                item.product.id,
              );
              if (!wasIncreased) {
                showAppSnackBar(
                  context,
                  message: AppLocalizations.of(context)!.cartStockLimitReached,
                  type: AppMessageType.warning,
                );
              }
            },
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
      child: SizedBox.square(
        dimension: 48,
        child: Center(
          child: Icon(
            icon,
            color: AutolabCustomer.primary,
            size: AutolabCustomer.iconXs,
          ),
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
        style: AutolabCustomer.primaryButton,
        onPressed: enabled ? onPressed : null,
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
  const _CartCircleButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        tooltip: tooltip,
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
  return NumberFormat.currency(
    locale: 'es_CR',
    symbol: '₡',
    decimalDigits: 0,
  ).format(value);
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
