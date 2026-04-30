part of 'workshop_profile_page.dart';

class _BusinessDetailsSheet extends StatelessWidget {
  const _BusinessDetailsSheet({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = workshop.serviceCategories.isEmpty
        ? l10n.workshopProfileServicesEmpty
        : workshop.serviceCategories.join(' • ');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  _LocationPreview(workshop: workshop),
                  Positioned(
                    top: 18,
                    left: 20,
                    child: _HeroIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.name,
                      style: const TextStyle(
                        color: Color(0xFF181411),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      categories,
                      style: const TextStyle(
                        color: Color(0xFF6B5F57),
                        fontSize: 16,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InfoListRow(
                      icon: Icons.location_on_outlined,
                      title: workshop.locationAddress.isNotEmpty
                          ? workshop.locationAddress
                          : l10n.mapSheetFallbackAddress,
                      trailing: Icons.copy_rounded,
                    ),
                    const Divider(height: 28),
                    _InfoListRow(
                      icon: Icons.schedule_rounded,
                      title: _hoursSummary(context, workshop.businessHours),
                      trailing: Icons.keyboard_arrow_down_rounded,
                    ),
                    const Divider(height: 28),
                    _InfoListRow(
                      icon: Icons.local_shipping_outlined,
                      title: workshop.offersHomeService
                          ? l10n.workshopProfileHomeServiceAvailable
                          : l10n.workshopProfileHomeServiceUnavailable,
                      subtitle: workshop.hasValidDeliveryRadius
                          ? l10n.workshopProfileCoverageValue(
                              workshop.deliveryRadiusKm.toStringAsFixed(0),
                            )
                          : l10n.workshopProfileCoverageUnavailable,
                    ),
                    const Divider(height: 28),
                    const _InfoListRow(
                      icon: Icons.star_border_rounded,
                      title: '4.6 (290+ calificaciones)',
                      trailing: Icons.info_outline_rounded,
                    ),
                    const Divider(height: 28),
                    _InfoListRow(
                      icon: Icons.info_outline_rounded,
                      title: l10n.workshopProfileAboutTitle,
                      subtitle: workshop.description.isNotEmpty
                          ? workshop.description
                          : l10n.workshopCardDescriptionFallback,
                    ),
                    const Divider(height: 28),
                    const _InfoListRow(
                      icon: Icons.person_add_alt_1_outlined,
                      title: '120+ pidieron de nuevo',
                      subtitle: 'en el año pasado',
                    ),
                    if (workshop.phone.isNotEmpty) ...[
                      const Divider(height: 28),
                      _InfoListRow(
                        icon: Icons.call_outlined,
                        title: workshop.phone,
                      ),
                    ],
                    if (workshop.paymentMethods.isNotEmpty) ...[
                      const Divider(height: 28),
                      _InfoListRow(
                        icon: Icons.payments_outlined,
                        title: l10n.workshopProfilePaymentMethodsTitle,
                        subtitle: workshop.paymentMethods.join(' • '),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            _ProfileActions.openLocation(context, workshop),
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l10n.workshopProfileOpenLocationAction),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _hoursSummary(BuildContext context, List<WorkshopBusinessHour> hours) {
    final l10n = AppLocalizations.of(context)!;

    if (hours.isEmpty) {
      return l10n.workshopProfileBusinessHoursEmpty;
    }

    final openHour = hours.where((hour) => !hour.isClosed).firstOrNull;

    if (openHour == null) {
      return l10n.workshopProfileClosed;
    }

    if (openHour.closeTime.isEmpty) {
      return l10n.workshopProfileBusinessHoursEmpty;
    }

    return 'Abierto hasta las ${_trimTime(openHour.closeTime)}';
  }

  String _trimTime(String value) {
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFFE4E9EC)),
          CustomPaint(painter: _MapPreviewPainter()),
          Align(
            alignment: const Alignment(-0.16, 0.25),
            child: _MapDot(label: '210 m'),
          ),
          Align(alignment: const Alignment(0.32, -0.28), child: _MapPin()),
          Positioned(
            left: 24,
            right: 24,
            bottom: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  workshop.locationAddress.isNotEmpty
                      ? workshop.locationAddress
                      : AppLocalizations.of(context)!.mapSheetFallbackAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF181411),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final mainRoadPaint = Paint()
      ..color = const Color(0xFFB8C8EA)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    final routePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var index = -1; index < 5; index++) {
      final y = size.height * (0.2 + index * 0.18);
      canvas.drawLine(
        Offset(-20, y),
        Offset(size.width + 20, y + 28),
        roadPaint,
      );
    }

    for (var index = 0; index < 5; index++) {
      final x = size.width * (0.05 + index * 0.23);
      canvas.drawLine(
        Offset(x, -20),
        Offset(x + 42, size.height + 20),
        roadPaint,
      );
    }

    canvas.drawLine(
      Offset(size.width * 0.36, size.height),
      Offset(size.width * 0.63, 0),
      mainRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.39, size.height * 0.67),
      Offset(size.width * 0.6, size.height * 0.32),
      routePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapDot extends StatelessWidget {
  const _MapDot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 8),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const _MapPin(size: 28),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size * 0.34,
          height: size * 0.34,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _InfoListRow extends StatelessWidget {
  const _InfoListRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 30, color: const Color(0xFF6B5F57)),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF181411),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFF6B5F57),
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Icon(trailing, size: 28, color: const Color(0xFF9A9A9A)),
        ],
      ],
    );
  }
}
