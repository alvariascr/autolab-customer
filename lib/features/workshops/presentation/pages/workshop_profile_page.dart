import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/logging/feature_logger.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../payments/domain/usecases/refresh_laropay_purchase_status.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/presentation/widgets/product_image.dart';
import '../../../products/presentation/widgets/product_price_text.dart';
import '../../domain/entities/workshop.dart';
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
  });

  final String workshopId;
  final String? paymentLinkId;

  @override
  State<WorkshopProfilePage> createState() => _WorkshopProfilePageState();
}

class _WorkshopProfilePageState extends State<WorkshopProfilePage> {
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static const _paymentStatusTimeout = Duration(seconds: 45);

  late Future<Either<Failure, Workshop?>> _workshopFuture;
  String? _shownPaymentResultKey;

  @override
  void initState() {
    super.initState();
    _workshopFuture = sl<WorkshopRepository>().getWorkshopById(
      widget.workshopId,
    );
    _schedulePaymentResultDialog();
  }

  @override
  void didUpdateWidget(covariant WorkshopProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paymentLinkId != widget.paymentLinkId) {
      _schedulePaymentResultDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Either<Failure, Workshop?>>(
              future: _workshopFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final result = snapshot.data;

                if (result == null) {
                  return _ProfileMessage(
                    message: l10n.workshopProfileLoadError,
                  );
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

                    return _WorkshopProfileContent(workshop: workshop);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _schedulePaymentResultDialog() {
    final paymentLinkId = widget.paymentLinkId?.trim() ?? '';
    if (!_uuidRegex.hasMatch(paymentLinkId)) {
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
    String paymentStatus;
    try {
      final result = await sl<RefreshLaropayPurchaseStatus>()(
        paymentLinkId,
      ).timeout(_paymentStatusTimeout);
      paymentStatus = result.fold(
        (_) => 'error',
        (purchase) => purchase.status,
      );
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

    await _showPaymentResultDialog(paymentStatus);
  }

  Future<void> _showPaymentResultDialog(String paymentStatus) async {
    final l10n = AppLocalizations.of(context)!;
    final notice = _LaropayPaymentNoticeData.fromStatus(paymentStatus, l10n);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            icon: Icon(notice.icon, color: notice.color, size: 42),
            title: Text(
              notice.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              notice.message,
              textAlign: TextAlign.center,
              style: AutolabCustomer.body.copyWith(height: 1.35),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _clearPaymentQuery();
                },
                child: Text(l10n.laropayPaymentResultBackToWorkshopAction),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go('/purchases');
                },
                child: Text(l10n.laropayPaymentResultViewPurchasesAction),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearPaymentQuery() {
    context.go('/workshops/${widget.workshopId}');
  }
}

class _LaropayPaymentNoticeData {
  const _LaropayPaymentNoticeData({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String title;
  final String message;
  final Color color;
  final IconData icon;

  factory _LaropayPaymentNoticeData.fromStatus(
    String status,
    AppLocalizations l10n,
  ) {
    return switch (status.trim().toLowerCase()) {
      'paid' => _LaropayPaymentNoticeData(
        title: l10n.laropayPaymentResultPaidTitle,
        message: l10n.laropayPaymentResultPaidMessage,
        color: AutolabCustomer.success,
        icon: Icons.check_circle_outline,
      ),
      'rejected' => _LaropayPaymentNoticeData(
        title: l10n.laropayPaymentResultRejectedTitle,
        message: l10n.laropayPaymentResultRejectedMessage,
        color: AutolabCustomer.error,
        icon: Icons.cancel_outlined,
      ),
      'expired' => _LaropayPaymentNoticeData(
        title: l10n.laropayPaymentResultExpiredTitle,
        message: l10n.laropayPaymentResultExpiredMessage,
        color: AutolabCustomer.warning,
        icon: Icons.hourglass_disabled_outlined,
      ),
      'pending' => _LaropayPaymentNoticeData(
        title: l10n.laropayPaymentResultPendingTitle,
        message: l10n.laropayPaymentResultPendingMessage,
        color: AutolabCustomer.info,
        icon: Icons.pending_actions_outlined,
      ),
      'error' => _LaropayPaymentNoticeData(
        title: l10n.laropayPaymentResultPendingTitle,
        message: l10n.laropayPaymentStartError,
        color: AutolabCustomer.error,
        icon: Icons.error_outline,
      ),
      _ => _LaropayPaymentNoticeData(
        title: l10n.laropayPaymentResultPendingTitle,
        message: l10n.laropayPaymentStartError,
        color: AutolabCustomer.error,
        icon: Icons.error_outline,
      ),
    };
  }
}
