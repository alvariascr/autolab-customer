import 'dart:async';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/logging/feature_logger.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/utils/uuid_validator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/widgets/cart_floating_checkout_button.dart';
import '../../../payments/application/laropay_payment_url_policy.dart';
import '../../../payments/domain/usecases/refresh_laropay_purchase_status.dart';
import '../../../payments/presentation/widgets/laropay_payment_result_dialog.dart';
import '../../../products/application/product_inventory_refresh_notifier.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/presentation/widgets/product_image.dart';
import '../../../products/presentation/widgets/product_price_text.dart';
import '../../domain/entities/workshop.dart';
import '../../domain/repositories/favorite_workshops_repository.dart';
import '../../domain/repositories/workshop_repository.dart';
import '../../domain/services/workshop_today_business_hours_resolver.dart';
import '../widgets/workshop_avatar.dart';
import '../widgets/workshop_menu_action.dart';
import '../workshop_empty_state_resolver.dart';

part 'workshop_profile_content.dart';
part 'workshop_profile_hero.dart';
part 'workshop_profile_actions.dart';
part 'workshop_business_details_sheet.dart';
part 'workshop_products_section.dart';
part 'workshop_profile_message.dart';

class WorkshopProfilePage extends StatefulWidget {
  const WorkshopProfilePage({
    super.key,
    required this.workshopId,
    this.paymentLinkId,
    this.initialCatalogSection,
    this.showCartAddedMessage = false,
  });

  final String workshopId;
  final String? paymentLinkId;
  final String? initialCatalogSection;
  final bool showCartAddedMessage;

  @override
  State<WorkshopProfilePage> createState() => _WorkshopProfilePageState();
}

class _WorkshopProfilePageState extends State<WorkshopProfilePage> {
  static const _paymentStatusTimeout = Duration(seconds: 45);
  static const _cartAddedMessageDuration = Duration(seconds: 3);

  late Future<Either<Failure, Workshop?>> _workshopFuture;
  String? _shownPaymentResultKey;
  Timer? _cartAddedMessageTimer;
  bool _showCartAddedBanner = false;

  @override
  void initState() {
    super.initState();
    _workshopFuture = sl<WorkshopRepository>().getWorkshopById(
      widget.workshopId,
    );
    _schedulePaymentResultDialog();
    _scheduleCartAddedMessage();
  }

  @override
  void didUpdateWidget(covariant WorkshopProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paymentLinkId != widget.paymentLinkId) {
      _schedulePaymentResultDialog();
    }
    if (!oldWidget.showCartAddedMessage && widget.showCartAddedMessage) {
      _scheduleCartAddedMessage();
    }
  }

  @override
  void dispose() {
    _cartAddedMessageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Either<Failure, Workshop?>>(
            future: _workshopFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final result = snapshot.data;

              if (result == null) {
                return _ProfileMessage(message: l10n.workshopProfileLoadError);
              }

              return result.fold(
                (failure) => _ProfileMessage(
                  message: WorkshopEmptyStateResolver().resolveLoadError(
                    failure,
                    l10n,
                  ),
                ),
                (workshop) {
                  if (workshop == null) {
                    return _ProfileMessage(
                      message: l10n.workshopProfileNotFound,
                    );
                  }

                  return _WorkshopProfileContent(
                    workshop: workshop,
                    initialCatalogSection: widget.initialCatalogSection,
                    favoriteRepository: sl<FavoriteWorkshopsRepository>(),
                  );
                },
              );
            },
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: AutolabCustomer.spacingMd,
            child: Center(child: CartFloatingCheckoutButton()),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + AutolabCustomer.spacingSmd,
            left: AutolabCustomer.spacingLg,
            right: AutolabCustomer.spacingLg,
            child: _CartAddedBanner(visible: _showCartAddedBanner),
          ),
        ],
      ),
    );
  }

  void _scheduleCartAddedMessage() {
    if (!widget.showCartAddedMessage) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _cartAddedMessageTimer?.cancel();
      setState(() => _showCartAddedBanner = true);
      _cartAddedMessageTimer = Timer(_cartAddedMessageDuration, () {
        if (mounted) {
          setState(() => _showCartAddedBanner = false);
        }
      });
    });
  }

  void _schedulePaymentResultDialog() {
    final paymentLinkId = widget.paymentLinkId?.trim() ?? '';
    if (!isValidUuid(paymentLinkId)) {
      return;
    }

    if (_shownPaymentResultKey == paymentLinkId) {
      return;
    }
    _shownPaymentResultKey = paymentLinkId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _validateAndShowPaymentResult(paymentLinkId);
    });
  }

  Future<void> _validateAndShowPaymentResult(String paymentLinkId) async {
    String paymentStatus = 'error';
    Uri? linkUrl;
    try {
      final result = await sl<RefreshLaropayPurchaseStatus>()(
        paymentLinkId,
      ).timeout(_paymentStatusTimeout);
      result.fold((_) => paymentStatus = 'error', (purchase) {
        paymentStatus = purchase.status;
        linkUrl = purchase.linkUrl;
      });
    } on Exception catch (error, stackTrace) {
      sl<FeatureLogger>().warn(
        feature: 'payments',
        action: 'refresh_laropay_return_status_failed',
        error: error,
        stackTrace: stackTrace,
      );
      paymentStatus = 'error';
    }

    if (!mounted) {
      return;
    }

    await _showPaymentResultDialog(paymentStatus, linkUrl);
  }

  Future<void> _showPaymentResultDialog(
    String paymentStatus,
    Uri? linkUrl,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final canRetry =
        linkUrl != null && paymentStatus.trim().toLowerCase() == 'pending';

    await showLaropayPaymentResultDialog(
      context: context,
      status: paymentStatus,
      actionsBuilder: (dialogContext) => [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            _clearPaymentQuery();
          },
          child: Text(l10n.laropayPaymentResultBackToWorkshopAction),
        ),
        if (canRetry)
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _reopenPaymentLink(linkUrl);
            },
            child: Text(l10n.myPurchasesOpenLinkAction),
          ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            context.go('/purchases');
          },
          child: Text(l10n.laropayPaymentResultViewPurchasesAction),
        ),
      ],
    );
  }

  Future<void> _reopenPaymentLink(Uri linkUrl) async {
    if (!LaropayPaymentUrlPolicy.isAllowed(linkUrl)) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final opened = await launchUrl(
      linkUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AutolabCustomer.error,
          content: Text(l10n.myPurchasesLinkOpenError),
        ),
      );
    }
  }

  void _clearPaymentQuery() {
    context.go('/workshops/${widget.workshopId}');
  }
}

class _CartAddedBanner extends StatelessWidget {
  const _CartAddedBanner({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IgnorePointer(
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, -0.35),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: visible ? 1 : 0,
          child: Material(
            color: AutolabCustomer.successSoftBackground,
            borderRadius: BorderRadius.circular(14),
            elevation: 8,
            shadowColor: AutolabCustomer.shadowBlackStrong,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AutolabCustomer.spacingMd,
                vertical: AutolabCustomer.spacingSmd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AutolabCustomer.success,
                    size: 20,
                  ),
                  const SizedBox(width: AutolabCustomer.spacingSm),
                  Expanded(
                    child: Text(
                      l10n.productDetailAddedToCartMessage,
                      style: AutolabCustomer.body.copyWith(
                        color: AutolabCustomer.success,
                        fontWeight: FontWeight.w800,
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
