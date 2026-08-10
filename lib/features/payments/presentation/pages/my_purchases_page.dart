import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
import '../../domain/entities/laropay_purchase.dart';
import '../../domain/usecases/get_laropay_purchases.dart';
import '../../domain/usecases/refresh_laropay_purchase_status.dart';

class MyPurchasesPage extends StatefulWidget {
  const MyPurchasesPage({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  State<MyPurchasesPage> createState() => _MyPurchasesPageState();
}

class _MyPurchasesPageState extends State<MyPurchasesPage> {
  late Future<List<LaropayPurchase>> _future;
  final Set<String> _refreshingPurchaseIds = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _loadPurchases();
  }

  Future<void> _reload() {
    final nextFuture = _loadPurchases();
    setState(() {
      _future = nextFuture;
    });
    return nextFuture;
  }

  Future<List<LaropayPurchase>> _loadPurchases() async {
    final result = await sl<GetLaropayPurchases>()();
    return result.fold((_) => throw const _PurchaseLoadException(), (items) {
      return items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _CustomerPageHeader(
              title: l10n.myPurchasesTitle,
              notificationTooltip: l10n.myAppointmentsNotificationsTooltip,
              onBack: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                  return;
                }

                context.go('/home-customer');
              },
            ),
            Expanded(
              child: FutureBuilder<List<LaropayPurchase>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _PurchaseMessageState(
                      icon: Icons.cloud_off_rounded,
                      title: l10n.myPurchasesLoadErrorTitle,
                      message: snapshot.error is _PurchaseLoadException
                          ? l10n.authErrorSessionExpired
                          : l10n.myAppointmentsRetryMessage,
                      color: AutolabCustomer.error,
                      actionLabel: l10n.myPurchasesRetryAction,
                      onAction: _reload,
                    );
                  }

                  final purchases = snapshot.data ?? const <LaropayPurchase>[];
                  if (purchases.isEmpty) {
                    return _PurchaseMessageState(
                      icon: Icons.shopping_bag_outlined,
                      title: l10n.myPurchasesEmptyTitle,
                      message: l10n.myPurchasesEmptyMessage,
                      color: AutolabCustomer.primary,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Text(
                            l10n.myPurchasesSubtitle,
                            textAlign: TextAlign.center,
                            style: AutolabCustomer.body.copyWith(
                              color: AutolabCustomer.customerSecondaryTextColor(
                                context,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }

                        return _PurchaseCard(
                          purchase: purchases[index - 1],
                          onOpenLink: _openPurchaseLink,
                          onRefreshStatus: _refreshPurchaseStatus,
                          refreshing: _refreshingPurchaseIds.contains(
                            purchases[index - 1].id,
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemCount: purchases.length + 1,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNavigation
          ? CustomBottomNavbar(
              currentIndex: 4,
              onTap: (index) => NavigationHandler.handle(context, index),
            )
          : null,
    );
  }

  Future<void> _openPurchaseLink(LaropayPurchase purchase) async {
    final linkUrl = purchase.linkUrl;
    final l10n = AppLocalizations.of(context)!;

    if (linkUrl == null || !linkUrl.isScheme('https')) {
      _showMessage(
        message: l10n.myPurchasesLinkOpenError,
        color: AutolabCustomer.error,
      );
      return;
    }

    final opened = await launchUrl(
      linkUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showMessage(
        message: l10n.myPurchasesLinkOpenError,
        color: AutolabCustomer.error,
      );
      return;
    }
  }

  Future<void> _refreshPurchaseStatus(LaropayPurchase purchase) async {
    final l10n = AppLocalizations.of(context)!;
    if (_refreshingPurchaseIds.contains(purchase.id)) {
      return;
    }

    setState(() => _refreshingPurchaseIds.add(purchase.id));

    try {
      final result = await sl<RefreshLaropayPurchaseStatus>()(purchase.id);
      if (!mounted) {
        return;
      }

      result.fold(
        (_) => _showMessage(
          message: l10n.myPurchasesStatusRefreshError,
          color: AutolabCustomer.error,
        ),
        (_) {
          _showMessage(
            message: l10n.myPurchasesStatusRefreshSuccess,
            color: AutolabCustomer.success,
          );
          _reload();
        },
      );
    } finally {
      if (mounted) {
        setState(() => _refreshingPurchaseIds.remove(purchase.id));
      }
    }
  }

  void _showMessage({required String message, required Color color}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        content: Text(message),
      ),
    );
  }
}

class _CustomerPageHeader extends StatelessWidget {
  const _CustomerPageHeader({
    required this.title,
    required this.notificationTooltip,
    required this.onBack,
  });

  final String title;
  final String notificationTooltip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalMargin,
        AutolabCustomer.spacingSm,
        horizontalMargin,
        0,
      ),
      child: SizedBox(
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(left: 0, top: 0, child: _CustomerHeaderLogo()),
            Positioned(
              left: 0,
              bottom: 0,
              child: _HeaderCircleButton(onTap: onBack),
            ),
            Positioned(
              bottom: 0,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AutolabCustomer.h3.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton(
                tooltip: notificationTooltip,
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: AutolabCustomer.customerTextColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: AutolabCustomer.customerSurfaceColor(context),
          foregroundColor: AutolabCustomer.customerSecondaryTextColor(context),
        ),
        icon: const Icon(
          Icons.arrow_back_rounded,
          size: AutolabCustomer.iconSm,
        ),
      ),
    );
  }
}

class _CustomerHeaderLogo extends StatelessWidget {
  const _CustomerHeaderLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 58,
      height: 22,
      child: CustomPaint(painter: _CustomerHeaderLogoPainter()),
    );
  }
}

class _CustomerHeaderLogoPainter extends CustomPainter {
  const _CustomerHeaderLogoPainter();

  static const _sourceWidth = 622.0;
  static const _sourceHeight = 224.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / _sourceWidth).clamp(
      0.0,
      size.height / _sourceHeight,
    );
    final dx = (size.width - _sourceWidth * scale) / 2;
    final dy = (size.height - _sourceHeight * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final paint = Paint()
      ..color = AutolabCustomer.primary
      ..style = PaintingStyle.fill;
    final starPaint = Paint()
      ..color = AutolabCustomer.primary
      ..style = PaintingStyle.fill;

    final left = Path()
      ..moveTo(0, 169)
      ..lineTo(65, 60)
      ..lineTo(185, 60)
      ..lineTo(246, 169)
      ..lineTo(154, 169)
      ..lineTo(127, 120)
      ..lineTo(97, 169)
      ..close();
    final center = Path()
      ..moveTo(220, 60)
      ..lineTo(338, 60)
      ..lineTo(400, 169)
      ..lineTo(309, 169)
      ..lineTo(280, 119)
      ..lineTo(252, 169)
      ..lineTo(160, 169)
      ..close();
    final right = Path()
      ..moveTo(360, 60)
      ..lineTo(482, 60)
      ..lineTo(548, 169)
      ..lineTo(455, 169)
      ..lineTo(425, 119)
      ..lineTo(398, 169)
      ..lineTo(306, 169)
      ..close();

    canvas
      ..drawPath(left, paint)
      ..drawPath(center, paint)
      ..drawPath(right, paint);

    final star = Path()
      ..moveTo(522, 21)
      ..lineTo(535, 48)
      ..lineTo(565, 52)
      ..lineTo(543, 73)
      ..lineTo(548, 103)
      ..lineTo(522, 89)
      ..lineTo(495, 103)
      ..lineTo(500, 73)
      ..lineTo(478, 52)
      ..lineTo(509, 48)
      ..close();
    canvas.drawPath(star, starPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.purchase,
    required this.onOpenLink,
    required this.onRefreshStatus,
    required this.refreshing,
  });

  final LaropayPurchase purchase;
  final ValueChanged<LaropayPurchase> onOpenLink;
  final ValueChanged<LaropayPurchase> onRefreshStatus;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewState = _PurchaseViewState.fromPurchase(purchase, l10n);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AutolabCustomer.secondary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PurchaseStatusIcon(viewState: viewState),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase.title(l10n),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textScaler: TextScaler.noScaling,
                        style: AutolabCustomer.bodyLarge.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        viewState.message,
                        style: AutolabCustomer.caption.copyWith(
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusBadge(viewState: viewState),
              ],
            ),
            const SizedBox(height: 16),
            _PurchaseDetailRow(
              icon: Icons.payments_outlined,
              label: purchase.hasOrderAmounts
                  ? purchase.hasPaymentLink
                        ? l10n.myPurchasesPaidOnlineLabel
                        : l10n.myPurchasesPaidLabel
                  : l10n.myPurchasesAmountLabel,
              value: purchase.formattedPaidAmount,
            ),
            if (purchase.hasOrderAmounts) ...[
              _PurchaseDetailRow(
                icon: Icons.account_balance_wallet_outlined,
                label: l10n.myPurchasesPendingAtWorkshopLabel,
                value: purchase.formattedRemainingAmount,
                valueColor: purchase.hasOutstandingBalance
                    ? AutolabCustomer.warning
                    : null,
              ),
              _PurchaseDetailRow(
                icon: Icons.receipt_long_outlined,
                label: l10n.myPurchasesOrderTotalLabel,
                value: purchase.formattedOrderTotalAmount,
              ),
            ],
            _PurchaseDetailRow(
              icon: Icons.calendar_month_outlined,
              label: l10n.myPurchasesDateLabel,
              value: purchase.formattedCreatedAt(l10n),
            ),
            _PurchaseDetailRow(
              icon: Icons.confirmation_number_outlined,
              label: l10n.myPurchasesReferenceLabel,
              value: purchase.reference,
            ),
            if (purchase.canReopenLink) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => onOpenLink(purchase),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(l10n.myPurchasesOpenLinkAction),
                ),
              ),
            ],
            if (purchase.canRefreshStatus) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: refreshing
                      ? null
                      : () => onRefreshStatus(purchase),
                  icon: refreshing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(l10n.myPurchasesRefreshStatusAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PurchaseStatusIcon extends StatelessWidget {
  const _PurchaseStatusIcon({required this.viewState});

  final _PurchaseViewState viewState;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: viewState.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(viewState.icon, color: viewState.color),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.viewState});

  final _PurchaseViewState viewState;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: viewState.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          viewState.label,
          style: AutolabCustomer.caption.copyWith(
            color: viewState.color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PurchaseDetailRow extends StatelessWidget {
  const _PurchaseDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AutolabCustomer.customerSecondaryTextColor(context),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AutolabCustomer.caption.copyWith(
                color: valueColor ?? AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseMessageState extends StatelessWidget {
  const _PurchaseMessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AutolabCustomer.h3.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PurchaseViewState {
  const _PurchaseViewState({
    required this.label,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String label;
  final String message;
  final Color color;
  final IconData icon;

  factory _PurchaseViewState.fromPurchase(
    LaropayPurchase purchase,
    AppLocalizations l10n,
  ) {
    return switch (purchase.state) {
      _PurchaseState.partial => _PurchaseViewState(
        label: l10n.myPurchasesPartialStatus,
        message: l10n.myPurchasesPartialMessage,
        color: AutolabCustomer.warning,
        icon: Icons.info_outline_rounded,
      ),
      _PurchaseState.approved => _PurchaseViewState(
        label: l10n.myPurchasesApprovedStatus,
        message: l10n.myPurchasesApprovedMessage,
        color: AutolabCustomer.success,
        icon: Icons.check_circle_outline_rounded,
      ),
      _PurchaseState.rejected => _PurchaseViewState(
        label: l10n.myPurchasesRejectedStatus,
        message: l10n.myPurchasesRejectedMessage,
        color: AutolabCustomer.error,
        icon: Icons.cancel_outlined,
      ),
      _PurchaseState.expired => _PurchaseViewState(
        label: l10n.myPurchasesExpiredStatus,
        message: l10n.myPurchasesExpiredMessage,
        color: AutolabCustomer.warning,
        icon: Icons.hourglass_disabled_outlined,
      ),
      _PurchaseState.pending => _PurchaseViewState(
        label: l10n.myPurchasesPendingStatus,
        message: l10n.myPurchasesPendingMessage,
        color: AutolabCustomer.warning,
        icon: Icons.hourglass_top_rounded,
      ),
      _PurchaseState.workshopPayment => _PurchaseViewState(
        label: l10n.myPurchasesWorkshopPaymentStatus,
        message: l10n.myPurchasesWorkshopPaymentMessage,
        color: AutolabCustomer.warning,
        icon: Icons.handshake_outlined,
      ),
      _PurchaseState.unknown => _PurchaseViewState(
        label: l10n.myPurchasesUnknownStatus,
        message: l10n.myPurchasesUnknownMessage,
        color: AutolabCustomer.secondary,
        icon: Icons.help_outline_rounded,
      ),
    };
  }
}

enum _PurchaseState {
  pending,
  partial,
  approved,
  rejected,
  expired,
  workshopPayment,
  unknown,
}

extension _LaropayPurchaseView on LaropayPurchase {
  String title(AppLocalizations l10n) {
    return detail.isEmpty ? l10n.myPurchasesDefaultTitle : detail;
  }

  bool get canReopenLink {
    return hasPaymentLink && linkUrl != null && state == _PurchaseState.pending;
  }

  bool get canRefreshStatus {
    return hasPaymentLink && state == _PurchaseState.pending;
  }

  _PurchaseState get state {
    if (hasPaymentLink && hasOutstandingBalance && isLaropayApproved) {
      return _PurchaseState.partial;
    }

    if (!hasPaymentLink && hasOutstandingBalance) {
      return _PurchaseState.workshopPayment;
    }

    final normalizedStatus = status.toLowerCase().trim();
    final normalizedResponse = responseCode.toLowerCase().trim();
    final normalizedDescription = responseDescription.toLowerCase().trim();

    if (normalizedStatus == 'expired') {
      return _PurchaseState.expired;
    }

    if (normalizedStatus == 'paid' ||
        normalizedStatus == 'approved' ||
        normalizedStatus == 'completed') {
      return _PurchaseState.approved;
    }

    if (normalizedStatus == 'rejected' ||
        normalizedStatus == 'cancelled' ||
        normalizedStatus == 'canceled' ||
        normalizedStatus == 'failed' ||
        normalizedStatus == 'error') {
      return _PurchaseState.rejected;
    }

    if (normalizedStatus == 'created' ||
        normalizedStatus == 'pending' ||
        normalizedStatus.isEmpty) {
      if (expiresAt != null && expiresAt!.isBefore(DateTime.now().toUtc())) {
        return _PurchaseState.expired;
      }

      return _PurchaseState.pending;
    }

    if ((normalizedResponse.isNotEmpty && normalizedResponse != '00') ||
        normalizedDescription.contains('rechaz')) {
      return _PurchaseState.rejected;
    }

    return _PurchaseState.unknown;
  }

  bool get isLaropayApproved {
    final normalizedStatus = status.toLowerCase().trim();
    return normalizedStatus == 'paid' ||
        normalizedStatus == 'approved' ||
        normalizedStatus == 'completed';
  }

  bool get hasOrderAmounts {
    return orderTotalAmount != null ||
        orderPaidAmount != null ||
        orderRemainingAmount != null;
  }

  bool get hasOutstandingBalance {
    return (orderRemainingAmount ?? 0) > 0;
  }

  String get formattedPaidAmount {
    return _formatCurrency(orderPaidAmount ?? amount, currencyCode);
  }

  String get formattedRemainingAmount {
    return _formatCurrency(orderRemainingAmount ?? 0, currencyCode);
  }

  String get formattedOrderTotalAmount {
    return _formatCurrency(orderTotalAmount ?? amount, currencyCode);
  }

  String _formatCurrency(double value, String code) {
    final formatter = NumberFormat.currency(
      locale: 'es_CR',
      symbol: code.toUpperCase() == 'USD' ? r'$' : '₡',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  String formattedCreatedAt(AppLocalizations l10n) {
    final date = createdAt;
    if (date == null) {
      return l10n.myPurchasesUnknownValue;
    }

    return DateFormat('dd/MM/yyyy h:mm a', 'es_CR').format(date.toLocal());
  }

  String get reference {
    if (hasPaymentLink && linkId.isNotEmpty) {
      return linkId;
    }

    final displayOrderNumber = orderNumber?.trim();
    return displayOrderNumber == null || displayOrderNumber.isEmpty
        ? id
        : displayOrderNumber;
  }
}

class _PurchaseLoadException implements Exception {
  const _PurchaseLoadException();
}
