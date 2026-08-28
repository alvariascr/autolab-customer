part of 'workshop_profile_page.dart';

class _WorkshopProfileContent extends StatelessWidget {
  const _WorkshopProfileContent({
    required this.workshop,
    required this.favoriteRepository,
    this.initialCatalogSection,
  });

  final Workshop workshop;
  final FavoriteWorkshopsRepository favoriteRepository;
  final String? initialCatalogSection;

  @override
  Widget build(BuildContext context) {
    final screenMargin = AutolabCustomer.responsiveScreenMargin(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _ProfileHero(
            workshop: workshop,
            favoriteRepository: favoriteRepository,
          ),
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
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          final outerRadius = AutolabCustomer.responsiveDouble(
                            context,
                            compact: 52,
                            regular: 62,
                            tablet: 72,
                          );

                          return WorkshopAvatar(
                            imageUrl: workshop.avatarUrl,
                            outerRadius: outerRadius,
                            innerRadius: outerRadius - 5,
                            outerColor: AutolabCustomer.background,
                            innerColor: AutolabCustomer.background,
                            fallbackIconSize: AutolabCustomer.iconLg,
                            fallbackIconColor: AutolabCustomer.secondary,
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      screenMargin,
                      64,
                      screenMargin,
                      AutolabCustomer.spacingXl + kBottomNavigationBarHeight,
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
                        _ProductsSection(
                          workshopId: workshop.id,
                          initialSection: initialCatalogSection,
                        ),
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
