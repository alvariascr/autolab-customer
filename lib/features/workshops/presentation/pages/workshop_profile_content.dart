part of 'workshop_profile_page.dart';

class _WorkshopProfileContent extends StatelessWidget {
  const _WorkshopProfileContent({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final screenMargin = AutolabCustomer.responsiveScreenMargin(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _ProfileHero(workshop: workshop),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: -58,
                    left: 0,
                    right: 0,
                    child: Center(child: _WorkshopAvatar(workshop: workshop)),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      screenMargin,
                      64,
                      screenMargin,
                      AutolabCustomer.spacingLg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderSummary(workshop: workshop),
                        const SizedBox(height: AutolabCustomer.spacingMd),
                        _DeliverySummary(workshop: workshop),
                        const SizedBox(height: AutolabCustomer.spacingMd),
                        Divider(
                          height: 1,
                          color: AutolabCustomer.customerDividerColor(context),
                        ),
                        const SizedBox(height: AutolabCustomer.spacingMd),
                        _ProductsSection(workshopId: workshop.id),
                        const SizedBox(height: AutolabCustomer.spacingMd),
                        _ScheduleFooterButton(workshopId: workshop.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleFooterButton extends StatelessWidget {
  const _ScheduleFooterButton({required this.workshopId});

  final String workshopId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      height: AutolabCustomer.responsiveDouble(
        context,
        compact: 48,
        regular: 54,
        tablet: 60,
      ),
      child: ElevatedButton(
        onPressed: () =>
            context.push(_ProfileActions.appointmentRoute(workshopId)),
        style: AutolabCustomer.primaryButton.copyWith(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            ),
          ),
        ),
        child: Text(
          l10n.appointmentNextAction,
          style: AutolabCustomer.h3.copyWith(
            color: AutolabCustomer.white,
            fontSize: AutolabCustomer.responsiveDouble(
              context,
              compact: 16,
              regular: 18,
              tablet: 20,
            ),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
