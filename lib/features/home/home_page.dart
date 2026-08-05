import 'package:flutter/material.dart';

import '../../core/theme/autolab_customer.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/home_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return HomeScaffold(
      title: l10n.adminHomeTitle,
      subtitle: l10n.adminHomeSubtitle,
      heroLabel: l10n.adminHomeHeroLabel,
      heroValue: l10n.adminHomeHeroValue,
      summaryTitle: l10n.adminHomeSummaryTitle,
      quickActionsTitle: l10n.adminHomeQuickActionsTitle,
      currentStatusTitle: l10n.adminHomeCurrentStatusTitle,
      highlights: buildHomeInfoItems([
        (
          title: l10n.adminHomeHighlightAgendaTitle,
          description: l10n.adminHomeHighlightAgendaDescription,
          icon: Icons.calendar_month_outlined,
        ),
        (
          title: l10n.adminHomeHighlightTrackingTitle,
          description: l10n.adminHomeHighlightTrackingDescription,
          icon: Icons.build_circle_outlined,
        ),
        (
          title: l10n.adminHomeHighlightCustomersTitle,
          description: l10n.adminHomeHighlightCustomersDescription,
          icon: Icons.people_alt_outlined,
        ),
      ]),
      quickActions: buildHomeInfoItems([
        (
          title: l10n.adminHomeQuickActionRegisterTitle,
          description: l10n.adminHomeQuickActionRegisterDescription,
          icon: Icons.add_road_outlined,
        ),
        (
          title: l10n.adminHomeQuickActionOrdersTitle,
          description: l10n.adminHomeQuickActionOrdersDescription,
          icon: Icons.receipt_long_outlined,
        ),
        (
          title: l10n.adminHomeQuickActionDeliveriesTitle,
          description: l10n.adminHomeQuickActionDeliveriesDescription,
          icon: Icons.local_shipping_outlined,
        ),
      ]),
      statusCards: buildHomeStatusItems([
        (
          label: l10n.adminHomeStatusCapacityLabel,
          value: '76%',
          caption: l10n.adminHomeStatusCapacityCaption,
          tone: AutolabCustomer.success,
        ),
        (
          label: l10n.adminHomeStatusCriticalDeliveriesLabel,
          value: '03',
          caption: l10n.adminHomeStatusCriticalDeliveriesCaption,
          tone: AutolabCustomer.warning,
        ),
        (
          label: l10n.adminHomeStatusPendingApprovalsLabel,
          value: '08',
          caption: l10n.adminHomeStatusPendingApprovalsCaption,
          tone: AutolabCustomer.primary,
        ),
      ]),
    );
  }
}
