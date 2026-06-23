part of 'workshop_profile_page.dart';

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _SegmentedPill(
            children: [
              _PillTab(label: l10n.workshopProfileDeliveryTab, selected: true),
              _PillTab(label: l10n.workshopProfilePickupTab),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _ActionPill(
          key: const ValueKey('workshop-profile-schedule-button'),
          icon: Icons.calendar_month_outlined,
          label: l10n.workshopProfileScheduleAction,
          onTap: () => context.push(appointmentRoute(workshop.id)),
        ),
      ],
    );
  }

  static String appointmentRoute(String workshopId) {
    return '/workshops/$workshopId/appointments/new';
  }

  static Future<void> launchPhone(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);

    if (!await launchUrl(uri)) {
      if (!context.mounted) {
        return;
      }
      showActionError(context);
    }
  }

  static Future<void> openLocation(
    BuildContext context,
    Workshop workshop,
  ) async {
    final query = workshop.hasValidCoordinates
        ? '${workshop.latitude},${workshop.longitude}'
        : workshop.locationAddress;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) {
        return;
      }
      showActionError(context);
    }
  }

  static void showActionError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.workshopProfileActionError),
      ),
    );
  }
}

class _SegmentedPill extends StatelessWidget {
  const _SegmentedPill({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: children),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF181411) : const Color(0xFF6B5F57),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F1F1),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliverySummary extends StatelessWidget {
  const _DeliverySummary({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _ContactAction(
            icon: Icons.call_outlined,
            label: l10n.workshopProfileCallAction,
            enabled: workshop.phone.isNotEmpty,
            onTap: () => _ProfileActions.launchPhone(context, workshop.phone),
          ),
        ),
        const SizedBox(width: AutolabCustomer.spacingMd),
        Expanded(
          child: _ContactAction(
            icon: Icons.map_outlined,
            label: l10n.workshopProfileOpenLocationAction,
            enabled:
                workshop.hasValidCoordinates ||
                workshop.locationAddress.isNotEmpty,
            onTap: () => _ProfileActions.openLocation(context, workshop),
          ),
        ),
      ],
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AutolabCustomer.primary
          : AutolabCustomer.customerDisabledTextColor(context),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AutolabCustomer.responsiveDouble(
              context,
              compact: AutolabCustomer.spacingSm,
              regular: AutolabCustomer.spacingSmd,
              tablet: AutolabCustomer.spacingMd,
            ),
            vertical: AutolabCustomer.responsiveDouble(
              context,
              compact: AutolabCustomer.spacingSm,
              regular: AutolabCustomer.spacingSm + 2,
              tablet: AutolabCustomer.spacingSmd,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AutolabCustomer.white),
              const SizedBox(width: AutolabCustomer.spacingSm),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.bodyLarge.copyWith(
                    color: AutolabCustomer.white,
                    fontWeight: FontWeight.w800,
                    fontSize: AutolabCustomer.responsiveDouble(
                      context,
                      compact: 12,
                      regular: 14,
                      tablet: 16,
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

class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.icon,
    required this.title,
    this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 30, color: const Color(0xFF181411)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap == null
          ? null
          : () {
              Navigator.of(context).pop();
              onTap!();
            },
    );
  }
}
