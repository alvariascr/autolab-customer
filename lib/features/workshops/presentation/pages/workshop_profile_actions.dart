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

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE9E2DC)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCell(
                    title: workshop.hasValidDeliveryRadius
                        ? l10n.workshopProfileCoverageValue(
                            workshop.deliveryRadiusKm.toStringAsFixed(0),
                          )
                        : l10n.workshopProfileCoverageUnavailable,
                    subtitle: l10n.workshopProfileCoverageAreaSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ContactAction(
                icon: Icons.call_outlined,
                label: l10n.workshopProfileCallAction,
                enabled: workshop.phone.isNotEmpty,
                onTap: () =>
                    _ProfileActions.launchPhone(context, workshop.phone),
              ),
            ),
            const SizedBox(width: 10),
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
        ),
        if (workshop.locationAddress.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BusinessInfoTile(
            icon: Icons.location_on_outlined,
            title: workshop.locationAddress,
            trailing: Icons.copy_rounded,
          ),
        ],
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF181411),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B5F57), fontSize: 13),
          ),
        ],
      ),
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
      color: enabled ? const Color(0xFFF7F7F7) : const Color(0xFFE8E8E8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessInfoTile extends StatelessWidget {
  const _BusinessInfoTile({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: const Color(0xFF6B5F57)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF181411),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Icon(trailing, size: 26, color: const Color(0xFF9A9A9A)),
        ],
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
