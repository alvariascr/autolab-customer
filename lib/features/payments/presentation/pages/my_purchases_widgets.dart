part of 'my_purchases_page.dart';

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

    return Material(
      color: AutolabCustomer.customerSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
            border: Border.all(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AutolabCustomer.body.copyWith(
                            color: AutolabCustomer.customerSecondaryTextColor(
                              context,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(viewState: viewState),
                ],
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              Divider(color: AutolabCustomer.customerBorderColor(context)),
              const SizedBox(height: AutolabCustomer.spacingSm),
              Row(
                children: [
                  Expanded(
                    child: _PurchaseMetaItem(
                      icon: Icons.calendar_today_rounded,
                      label: purchase.formattedCreatedAtShort(l10n),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 18,
                    color: AutolabCustomer.customerBorderColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PurchaseMetaItem(
                      icon: Icons.payments_outlined,
                      label: purchase.hasOrderAmounts
                          ? purchase.formattedOrderTotalAmount
                          : purchase.formattedPaidAmount,
                    ),
                  ),
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
                                color:
                                    AutolabCustomer.customerSecondaryTextColor(
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
              Padding(
                padding: const EdgeInsets.only(top: 10),
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
                        fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _PurchaseMetaItem extends StatelessWidget {
  const _PurchaseMetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AutolabCustomer.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
        color: AutolabCustomer.primary,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      ),
      child: Icon(viewState.icon, color: AutolabCustomer.white, size: 24),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.viewState});

  final _PurchaseViewState viewState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AutolabCustomer.transparent,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.primary),
      ),
      child: Text(
        viewState.label,
        style: AutolabCustomer.caption.copyWith(
          color: AutolabCustomer.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
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
                        valueColor ??
                        AutolabCustomer.customerTextColor(context),
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
    return switch (purchase.purchaseState) {
      LaropayPurchaseState.partial => _PurchaseViewState(
        label: l10n.myPurchasesPartialStatus,
        message: l10n.myPurchasesPartialMessage,
        color: AutolabCustomer.warning,
        icon: Icons.info_outline_rounded,
      ),
      LaropayPurchaseState.approved => _PurchaseViewState(
        label: l10n.myPurchasesApprovedStatus,
        message: l10n.myPurchasesApprovedMessage,
        color: AutolabCustomer.success,
        icon: Icons.check_circle_outline_rounded,
      ),
      LaropayPurchaseState.cancelled => _PurchaseViewState(
        label: l10n.myPurchasesCancelledStatus,
        message: l10n.myPurchasesCancelledMessage,
        color: AutolabCustomer.error,
        icon: Icons.block_outlined,
      ),
      LaropayPurchaseState.rejected => _PurchaseViewState(
        label: l10n.myPurchasesRejectedStatus,
        message: l10n.myPurchasesRejectedMessage,
        color: AutolabCustomer.error,
        icon: Icons.cancel_outlined,
      ),
      LaropayPurchaseState.expired => _PurchaseViewState(
        label: l10n.myPurchasesExpiredStatus,
        message: l10n.myPurchasesExpiredMessage,
        color: AutolabCustomer.warning,
        icon: Icons.hourglass_disabled_outlined,
      ),
      LaropayPurchaseState.pending => _PurchaseViewState(
        label: l10n.myPurchasesPendingStatus,
        message: l10n.myPurchasesPendingMessage,
        color: AutolabCustomer.warning,
        icon: Icons.hourglass_top_rounded,
      ),
      LaropayPurchaseState.workshopPayment => _PurchaseViewState(
        label: l10n.myPurchasesWorkshopPaymentStatus,
        message: l10n.myPurchasesWorkshopPaymentMessage,
        color: AutolabCustomer.warning,
        icon: Icons.handshake_outlined,
      ),
      LaropayPurchaseState.unknown => _PurchaseViewState(
        label: l10n.myPurchasesUnknownStatus,
        message: l10n.myPurchasesUnknownMessage,
        color: AutolabCustomer.secondary,
        icon: Icons.help_outline_rounded,
      ),
    };
  }
}

extension _LaropayPurchaseView on LaropayPurchase {
  String title(AppLocalizations l10n) {
    return detail.isEmpty ? l10n.myPurchasesDefaultTitle : detail;
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
    if (code.toUpperCase() == 'USD') {
      return _usdFormatter.format(value);
    }

    return formatColones(value);
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
