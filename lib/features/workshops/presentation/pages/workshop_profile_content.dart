part of 'workshop_profile_page.dart';

class _WorkshopProfileContent extends StatelessWidget {
  const _WorkshopProfileContent({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ProfileHero(workshop: workshop),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderSummary(workshop: workshop),
                      const SizedBox(height: 18),
                      _ProfileActions(workshop: workshop),
                      const SizedBox(height: 16),
                      _DeliverySummary(workshop: workshop),
                      const SizedBox(height: 18),
                      _ProductsSection(workshopId: workshop.id),
                    ],
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
