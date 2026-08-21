import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/utils/uuid_validator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
import '../../../profile/presentation/widgets/customer_page_header.dart';
import '../../domain/entities/laropay_purchase.dart';
import '../../domain/usecases/get_laropay_purchases.dart';
import '../../domain/usecases/refresh_laropay_purchase_status.dart';
import '../widgets/laropay_payment_result_dialog.dart';

class MyPurchasesPage extends StatefulWidget {
  const MyPurchasesPage({
    super.key,
    this.showBottomNavigation = true,
    this.paymentLinkId,
  });

  final bool showBottomNavigation;
  final String? paymentLinkId;

  @override
  State<MyPurchasesPage> createState() => _MyPurchasesPageState();
}

class _MyPurchasesPageState extends State<MyPurchasesPage> {
  late Future<List<LaropayPurchase>> _future;
  final Set<String> _refreshingPurchaseIds = <String>{};
  String? _handledPaymentLinkId;
  bool _isProcessingPaymentReturn = false;
  DateTimeRange? _dateFilter;

  @override
  void initState() {
    super.initState();
    _future = _loadPurchases();
    _schedulePaymentReturnRefresh();
  }

  @override
  void didUpdateWidget(covariant MyPurchasesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paymentLinkId != widget.paymentLinkId) {
      _schedulePaymentReturnRefresh();
    }
  }

  Future<void> _reload() {
    final nextFuture = _loadPurchases();
    setState(() {
      _future = nextFuture;
    });
    return nextFuture;
  }

  void _schedulePaymentReturnRefresh() {
    final paymentLinkId = widget.paymentLinkId?.trim() ?? '';
    if (!isValidUuid(paymentLinkId) || _handledPaymentLinkId == paymentLinkId) {
      return;
    }

    _handledPaymentLinkId = paymentLinkId;
    _isProcessingPaymentReturn = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _refreshReturnedPayment(paymentLinkId);
    });
  }

  Future<List<LaropayPurchase>> _loadPurchases() async {
    final result = await sl<GetLaropayPurchases>()();
    return result.fold((_) => throw const _PurchaseLoadException(), (items) {
      return items;
    });
  }

  Future<void> _pickDateFilter() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _dateFilter,
    );

    if (picked != null && mounted) {
      setState(() => _dateFilter = picked);
    }
  }

  bool _isWithinDateFilter(LaropayPurchase purchase, DateTimeRange range) {
    final createdAt = purchase.createdAt;
    if (createdAt == null) {
      return false;
    }

    final local = createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final endInclusive = DateTime(range.end.year, range.end.month, range.end.day);
    return !day.isBefore(range.start) && !day.isAfter(endInclusive);
  }

  String _formattedDateFilter(DateTimeRange range) {
    final formatter = DateFormat('d MMM', 'es_CR');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
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
              title: l10n.myPurchasesTitle,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                children: [
                  Material(
                    color: AutolabCustomer.customerSurfaceColor(context),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _pickDateFilter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AutolabCustomer.customerBorderColor(
                              context,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 15,
                              color: AutolabCustomer.customerSecondaryTextColor(
                                context,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _dateFilter == null
                                  ? l10n.myPurchasesFilterByDateAction
                                  : _formattedDateFilter(_dateFilter!),
                              style: AutolabCustomer.caption.copyWith(
                                color:
                                    AutolabCustomer.customerSecondaryTextColor(
                                      context,
                                    ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_dateFilter != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _dateFilter = null),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<LaropayPurchase>>(
                future: _future,
                builder: (context, snapshot) {
                  if (_isProcessingPaymentReturn ||
                      snapshot.connectionState == ConnectionState.waiting) {
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
                  final dateFilter = _dateFilter;
                  final visiblePurchases = dateFilter == null
                      ? purchases
                      : purchases
                            .where((p) => _isWithinDateFilter(p, dateFilter))
                            .toList(growable: false);

                  if (visiblePurchases.isEmpty) {
                    final isFiltered = dateFilter != null;
                    return RefreshIndicator(
                      onRefresh: _reload,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: _PurchaseMessageState(
                                icon: isFiltered
                                    ? Icons.event_busy_outlined
                                    : Icons.shopping_bag_outlined,
                                title: isFiltered
                                    ? l10n.myPurchasesFilterEmptyTitle
                                    : l10n.myPurchasesEmptyTitle,
                                message: isFiltered
                                    ? l10n.myPurchasesFilterEmptyMessage
                                    : l10n.myPurchasesEmptyMessage,
                                color: AutolabCustomer.primary,
                                actionLabel: isFiltered
                                    ? l10n.myPurchasesClearFilterAction
                                    : null,
                                onAction: isFiltered
                                    ? () => setState(() => _dateFilter = null)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
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
                          purchase: visiblePurchases[index - 1],
                          onOpenLink: _openPurchaseLink,
                          onRefreshStatus: _refreshPurchaseStatus,
                          refreshing: _refreshingPurchaseIds.contains(
                            visiblePurchases[index - 1].id,
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemCount: visiblePurchases.length + 1,
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

  Future<void> _refreshReturnedPayment(String paymentLinkId) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final result = await sl<RefreshLaropayPurchaseStatus>()(paymentLinkId);
      if (!mounted) {
        return;
      }

      final purchase = result.fold((_) => null, (purchase) => purchase);
      if (purchase == null) {
        _showMessage(
          message: l10n.myPurchasesStatusRefreshError,
          color: AutolabCustomer.error,
        );
        return;
      }

      await showLaropayPaymentResultDialog(
        context: context,
        status: _effectiveReturnedPaymentStatus(purchase),
        actionsBuilder: (dialogContext) => [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.laropayPaymentResultCloseAction),
          ),
        ],
      );

      if (mounted) {
        await _reload();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPaymentReturn = false);
        context.replace('/purchases');
      }
    }
  }

  // laropay_payment_links.status can lag orders.payment_status for orders
  // with a service balance paid at the workshop (product paid online =
  // order partially/fully settled, even if the link itself hasn't been
  // marked 'paid' yet) -- prefer the order-level signal in that case.
  String _effectiveReturnedPaymentStatus(LaropayPurchase purchase) {
    final status = purchase.status.toLowerCase();
    final orderPaymentStatus = purchase.orderPaymentStatus?.toLowerCase();
    if (status != 'paid' &&
        (orderPaymentStatus == 'paid' || orderPaymentStatus == 'partial')) {
      return 'paid';
    }

    return purchase.status;
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

class _PurchaseCard extends StatefulWidget {
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
  State<_PurchaseCard> createState() => _PurchaseCardState();
}

class _PurchaseCardState extends State<_PurchaseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final purchase = widget.purchase;
    final viewState = _PurchaseViewState.fromPurchase(purchase, l10n);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textScaler: TextScaler.noScaling,
                        style: AutolabCustomer.bodyLarge.copyWith(
                          color: AutolabCustomer.customerTextColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        purchase.summaryLine(l10n),
                        style: AutolabCustomer.caption.copyWith(
                          color: AutolabCustomer.customerSecondaryTextColor(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusBadge(viewState: viewState),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topLeft,
              child: !_expanded
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewState.message,
                            style: AutolabCustomer.caption.copyWith(
                              color: AutolabCustomer.customerSecondaryTextColor(
                                context,
                              ),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded
                          ? l10n.myPurchasesHideDetailAction
                          : l10n.myPurchasesShowDetailAction,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: AutolabCustomer.customerSecondaryTextColor(
                        context,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (purchase.canReopenLink || purchase.canRefreshStatus) ...[
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: AutolabCustomer.customerBorderColor(context),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (purchase.canReopenLink)
                    Expanded(
                      child: _PurchaseActionButton(
                        onPressed: () => widget.onOpenLink(purchase),
                        icon: Icons.open_in_new_rounded,
                        label: l10n.myPurchasesOpenLinkAction,
                      ),
                    ),
                  if (purchase.canReopenLink && purchase.canRefreshStatus)
                    const SizedBox(width: 8),
                  if (purchase.canRefreshStatus)
                    _PurchaseActionButton(
                      onPressed: widget.refreshing
                          ? null
                          : () => widget.onRefreshStatus(purchase),
                      tooltip: l10n.myPurchasesRefreshStatusAction,
                      icon: Icons.sync_rounded,
                      loading: widget.refreshing,
                    ),
                ],
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: viewState.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
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
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
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

class _PurchaseActionButton extends StatelessWidget {
  const _PurchaseActionButton({
    required this.onPressed,
    required this.icon,
    this.label,
    this.tooltip,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final String? tooltip;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final borderColor = AutolabCustomer.customerBorderColor(
      context,
    ).withValues(alpha: disabled ? 0.5 : 1);
    final contentColor = AutolabCustomer.customerSecondaryTextColor(
      context,
    ).withValues(alpha: disabled ? 0.5 : 1);

    final iconWidget = loading
        ? SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: contentColor,
            ),
          )
        : Icon(icon, size: 17, color: contentColor);

    final button = Material(
      color: AutolabCustomer.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          width: label == null ? 38 : null,
          padding: label == null
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: label == null
              ? iconWidget
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconWidget,
                    const SizedBox(width: 6),
                    Text(
                      label!,
                      style: AutolabCustomer.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AutolabCustomer.customerTextColor(
                          context,
                        ).withValues(alpha: disabled ? 0.5 : 1),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(message: tooltip!, child: button);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AutolabCustomer.customerSecondaryTextColor(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AutolabCustomer.caption.copyWith(
                    color:
                        valueColor ?? AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
      _PurchaseState.cancelled => _PurchaseViewState(
        label: l10n.myPurchasesCancelledStatus,
        message: l10n.myPurchasesCancelledMessage,
        color: AutolabCustomer.error,
        icon: Icons.block_outlined,
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
  cancelled,
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

    if (normalizedStatus == 'cancelled' || normalizedStatus == 'canceled') {
      return _PurchaseState.cancelled;
    }

    if (normalizedStatus == 'rejected' ||
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

  String formattedCreatedAtShort(AppLocalizations l10n) {
    final date = createdAt;
    if (date == null) {
      return l10n.myPurchasesUnknownValue;
    }

    return DateFormat('d MMM', 'es_CR').format(date.toLocal());
  }

  // Collapsed-card summary: date + total, so the customer sees the
  // essentials without the full amount breakdown always on screen.
  String summaryLine(AppLocalizations l10n) {
    final amount = hasOrderAmounts
        ? formattedOrderTotalAmount
        : formattedPaidAmount;
    return '${formattedCreatedAtShort(l10n)} · $amount';
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
