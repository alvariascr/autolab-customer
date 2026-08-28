part of 'home_customer_content.dart';

class _PromotionsSection extends StatelessWidget {
  const _PromotionsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _HomeColors.of(context);
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);
    final cardHeight = AutolabCustomer.responsiveDouble(
      context,
      compact: 140,
      regular: 160,
      tablet: 190,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homePromotionsComingSoon,
                  style: AutolabCustomer.h2.copyWith(
                    color: colors.text,
                    fontSize: AutolabCustomer.responsiveDouble(
                      context,
                      compact: 21,
                      regular: 24,
                      tablet: 28,
                    ),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AutolabCustomer.spacingSmd + 2),
          Container(
            height: cardHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: AutolabCustomer.primary,
                  size: AutolabCustomer.iconLg + 2,
                ),
                const SizedBox(height: AutolabCustomer.spacingSmd - 2),
                Text(
                  l10n.homePromotionsTitle,
                  style: AutolabCustomer.bodyLarge.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                Text(
                  l10n.homePromotionsSubtitle,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.caption.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AutolabCustomer.spacingMd + 2),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PromoDot(isActive: true),
              _PromoDot(isActive: false),
              _PromoDot(isActive: false),
              _PromoDot(isActive: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoDot extends StatelessWidget {
  const _PromoDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AutolabCustomer.primary
            : _HomeColors.of(context).inactiveDot,
        shape: BoxShape.circle,
      ),
    );
  }
}
