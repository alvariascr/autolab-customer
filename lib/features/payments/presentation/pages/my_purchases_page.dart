import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/utils/uuid_validator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
import '../../../profile/presentation/widgets/customer_page_header.dart';
import '../../application/laropay_payment_url_policy.dart';
import '../../domain/entities/laropay_purchase.dart';
import '../../domain/usecases/get_laropay_purchases.dart';
import '../../domain/usecases/refresh_laropay_purchase_status.dart';
import '../widgets/laropay_payment_result_dialog.dart';

part 'my_purchases_date_filter.dart';
part 'my_purchases_widgets.dart';

final _colonesFormatter = NumberFormat.currency(
  locale: 'es_CR',
  symbol: '₡',
  decimalDigits: 2,
);
final _usdFormatter = NumberFormat.currency(
  locale: 'es_CR',
  symbol: r'$',
  decimalDigits: 2,
);

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
    final result = await showModalBottomSheet<_PurchaseDateFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AutolabCustomer.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      builder: (_) => _PurchaseDateFilterSheet(
        initialRange: _dateFilter,
        firstDay: DateTime(now.year - 2, now.month, now.day),
        lastDay: DateTime(now.year, now.month, now.day),
      ),
    );

    if (result != null && mounted) {
      setState(() => _dateFilter = result.range);
    }
  }

  bool _isWithinDateFilter(LaropayPurchase purchase, DateTimeRange range) {
    final createdAt = purchase.createdAt;
    if (createdAt == null) {
      return false;
    }

    final local = createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final endInclusive = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
    );
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
            const SizedBox(height: AutolabCustomer.spacingLg),
            Text(
              l10n.myPurchasesSubtitle,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingLg),
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
                            color: AutolabCustomer.customerBorderColor(context),
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
                        return _PurchaseCard(
                          purchase: visiblePurchases[index],
                          onOpenLink: _openPurchaseLink,
                          onRefreshStatus: _refreshPurchaseStatus,
                          refreshing: _refreshingPurchaseIds.contains(
                            visiblePurchases[index].id,
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemCount: visiblePurchases.length,
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

    if (!LaropayPaymentUrlPolicy.isAllowed(linkUrl)) {
      _showMessage(
        message: l10n.myPurchasesLinkOpenError,
        color: AutolabCustomer.error,
      );
      return;
    }

    final opened = await launchUrl(
      linkUrl!,
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
    var shouldClearPaymentLink = false;

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
      shouldClearPaymentLink = true;

      if (mounted) {
        await _reload();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPaymentReturn = false);
        if (shouldClearPaymentLink) {
          context.replace('/purchases');
        }
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
