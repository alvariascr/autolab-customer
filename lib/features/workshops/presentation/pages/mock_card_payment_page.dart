import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';

class MockCardPaymentPage extends StatefulWidget {
  const MockCardPaymentPage({
    super.key,
    required this.appointmentId,
    required this.amountLabel,
    required this.workshopName,
    required this.onClose,
    this.paymentWindow = const Duration(minutes: 5),
  });

  final String appointmentId;
  final String amountLabel;
  final String workshopName;
  final VoidCallback onClose;
  final Duration paymentWindow;

  @override
  State<MockCardPaymentPage> createState() => _MockCardPaymentPageState();
}

class _MockCardPaymentPageState extends State<MockCardPaymentPage> {
  late Duration _remaining;
  Timer? _timer;
  bool _isApproved = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.paymentWindow;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        setState(() => _remaining = Duration.zero);
        _timer?.cancel();
        return;
      }

      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final isExpired = _remaining == Duration.zero;
    final canApprove = !isExpired && !_isApproved;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.onClose();
        }
      },
      child: Scaffold(
        backgroundColor: AutolabCustomer.customerSurfaceColor(context),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _mockPaymentSoftBackground(
                          context,
                          lightColor: AutolabCustomer.errorSoftBackground,
                          accentColor: primary,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: primary),
                      ),
                      child: Text(
                        l10n.appointmentMockPaymentBadge,
                        style: TextStyle(
                          fontFamily: AutolabCustomer.primaryFont,
                          color: primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AutolabCustomer.customerElevatedSurfaceColor(
                            context,
                          ),
                          border: Border.all(
                            color: AutolabCustomer.customerBorderColor(context),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AutolabCustomer.shadowBlackMedium,
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.credit_card_outlined,
                                color: AutolabCustomer.white,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              _isApproved
                                  ? l10n.appointmentMockPaymentApprovedTitle
                                  : l10n.appointmentMockPaymentTitle,
                              style: AutolabCustomer.h1.copyWith(
                                color: AutolabCustomer.customerTextColor(
                                  context,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isApproved
                                  ? l10n.appointmentMockPaymentApprovedSubtitle
                                  : l10n.appointmentMockPaymentSubtitle,
                              style: TextStyle(
                                fontFamily: AutolabCustomer.primaryFont,
                                color:
                                    AutolabCustomer.customerSecondaryTextColor(
                                      context,
                                    ),
                                fontSize: 16,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Divider(
                              height: 34,
                              color: AutolabCustomer.customerDividerColor(
                                context,
                              ),
                            ),
                            if (_isApproved)
                              _MockPaymentStatusCard(
                                icon: Icons.check_circle_outline,
                                message: l10n.appointmentCreatedSuccess,
                                color: AutolabCustomer.successText,
                                background: _mockPaymentSoftBackground(
                                  context,
                                  lightColor:
                                      AutolabCustomer.successSoftBackground,
                                  accentColor: AutolabCustomer.successText,
                                ),
                              )
                            else
                              _MockPaymentTimer(
                                remaining: _remaining,
                                isExpired: isExpired,
                              ),
                            const SizedBox(height: 18),
                            _MockPaymentDetailRow(
                              label: l10n.appointmentMockPaymentAmountLabel,
                              value: widget.amountLabel,
                              emphasize: true,
                            ),
                            _MockPaymentDetailRow(
                              label: l10n.appointmentMockPaymentMerchantLabel,
                              value: widget.workshopName,
                            ),
                            _MockPaymentDetailRow(
                              label: l10n.appointmentMockPaymentReferenceLabel,
                              value: widget.appointmentId,
                            ),
                            const SizedBox(height: 22),
                            _MockPaymentNotice(
                              message: _isApproved
                                  ? l10n.appointmentMockPaymentApprovedNotice
                                  : isExpired
                                  ? l10n.appointmentMockPaymentExpired
                                  : l10n.appointmentMockPaymentNotice,
                            ),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton.icon(
                                onPressed: _isApproved
                                    ? widget.onClose
                                    : canApprove
                                    ? _approvePayment
                                    : null,
                                icon: Icon(
                                  _isApproved
                                      ? Icons.check_circle_outline
                                      : Icons.check_rounded,
                                ),
                                label: Text(
                                  _isApproved
                                      ? l10n.appointmentMockPaymentApprovedAction
                                      : l10n.appointmentMockPaymentApproveAction,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: OutlinedButton(
                                onPressed: widget.onClose,
                                child: Text(
                                  l10n.appointmentMockPaymentBackAction,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  void _approvePayment() {
    _timer?.cancel();
    setState(() {
      _isApproved = true;
    });
  }
}

class _MockPaymentStatusCard extends StatelessWidget {
  const _MockPaymentStatusCard({
    required this.icon,
    required this.message,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                color: AutolabCustomer.customerTextColor(context),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockPaymentTimer extends StatelessWidget {
  const _MockPaymentTimer({required this.remaining, required this.isExpired});

  final Duration remaining;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = isExpired
        ? AutolabCustomer.errorDarkText
        : Theme.of(context).colorScheme.primary;
    final background = _mockPaymentSoftBackground(
      context,
      lightColor: isExpired
          ? AutolabCustomer.errorSoftBackground
          : AutolabCustomer.warningSoftBackground,
      accentColor: color,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.appointmentMockPaymentTimeRemaining,
              style: TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                color: AutolabCustomer.customerTextColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            _formatDuration(remaining),
            style: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _MockPaymentNotice extends StatelessWidget {
  const _MockPaymentNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _mockPaymentSoftBackground(
          context,
          lightColor: AutolabCustomer.warningSoftBackground,
          accentColor: AutolabCustomer.warningText,
        ),
        border: Border.all(
          color: AutolabCustomer.warningText.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AutolabCustomer.warningText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                color: AutolabCustomer.customerTextColor(context),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockPaymentDetailRow extends StatelessWidget {
  const _MockPaymentDetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                color: AutolabCustomer.customerSecondaryTextColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                color: emphasize
                    ? Theme.of(context).colorScheme.primary
                    : AutolabCustomer.customerTextColor(context),
                fontSize: emphasize ? 22 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _mockPaymentSoftBackground(
  BuildContext context, {
  required Color lightColor,
  required Color accentColor,
}) {
  if (!AutolabCustomer.isDark(context)) {
    return lightColor;
  }

  return accentColor.withValues(alpha: 0.16);
}
