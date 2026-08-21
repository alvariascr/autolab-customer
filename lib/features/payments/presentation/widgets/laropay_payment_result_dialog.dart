import 'package:flutter/material.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';

/// Icon/title/message/color for a Laropay payment result, shared between
/// every screen that shows the outcome of a checkout (Mis compras, la
/// pantalla de taller al volver de una cita) so they stay visually
/// consistent.
class LaropayPaymentNotice {
  const LaropayPaymentNotice({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String title;
  final String message;
  final Color color;
  final IconData icon;

  factory LaropayPaymentNotice.fromStatus(
    String status,
    AppLocalizations l10n,
  ) {
    return switch (status.trim().toLowerCase()) {
      'paid' => LaropayPaymentNotice(
        title: l10n.laropayPaymentResultPaidTitle,
        message: l10n.laropayPaymentResultPaidMessage,
        color: AutolabCustomer.success,
        icon: Icons.check_circle_outline,
      ),
      // Matches AutolabCustomer.appointmentCancelled, the app's existing
      // convention for a cancelled state -- distinct from rejected only by
      // icon/copy, not by inventing a separate color.
      'cancelled' || 'canceled' => LaropayPaymentNotice(
        title: l10n.laropayPaymentResultCancelledTitle,
        message: l10n.laropayPaymentResultCancelledMessage,
        color: AutolabCustomer.error,
        icon: Icons.block_outlined,
      ),
      'rejected' => LaropayPaymentNotice(
        title: l10n.laropayPaymentResultRejectedTitle,
        message: l10n.laropayPaymentResultRejectedMessage,
        color: AutolabCustomer.error,
        icon: Icons.cancel_outlined,
      ),
      'expired' => LaropayPaymentNotice(
        title: l10n.laropayPaymentResultExpiredTitle,
        message: l10n.laropayPaymentResultExpiredMessage,
        color: AutolabCustomer.warning,
        icon: Icons.hourglass_disabled_outlined,
      ),
      'pending' => LaropayPaymentNotice(
        title: l10n.laropayPaymentResultPendingTitle,
        message: l10n.laropayPaymentResultPendingMessage,
        color: AutolabCustomer.info,
        icon: Icons.pending_actions_outlined,
      ),
      'error' => LaropayPaymentNotice(
        title: l10n.laropayPaymentResultPendingTitle,
        message: l10n.laropayPaymentStartError,
        color: AutolabCustomer.error,
        icon: Icons.error_outline,
      ),
      _ => LaropayPaymentNotice(
        title: l10n.laropayPaymentResultPendingTitle,
        message: l10n.laropayPaymentStartError,
        color: AutolabCustomer.error,
        icon: Icons.error_outline,
      ),
    };
  }
}

/// Shows the shared payment-result dialog (icon + title + message, rounded
/// card) instead of a plain SnackBar. `actionsBuilder` receives the dialog's
/// own [BuildContext] so callers can pop it via `Navigator.of(dialogContext)`.
Future<void> showLaropayPaymentResultDialog({
  required BuildContext context,
  required String status,
  required List<Widget> Function(BuildContext dialogContext) actionsBuilder,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final notice = LaropayPaymentNotice.fromStatus(status, l10n);

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
          content: notice.message.trim().isEmpty
              ? null
              : Text(
                  notice.message,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.body.copyWith(height: 1.35),
                ),
          actionsAlignment: MainAxisAlignment.center,
          actions: actionsBuilder(dialogContext),
        ),
      );
    },
  );
}
