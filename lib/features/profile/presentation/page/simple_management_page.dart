import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../l10n/app_localizations.dart';

class SimpleManagementPage extends StatelessWidget {
  const SimpleManagementPage({super.key});

  static const routePath = '/simple-management';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      _SimpleManagementStep(
        icon: Icons.search_rounded,
        title: l10n.simpleManagementExploreTitle,
        description: l10n.simpleManagementExploreDescription,
      ),
      _SimpleManagementStep(
        icon: Icons.calendar_month_outlined,
        title: l10n.simpleManagementScheduleTitle,
        description: l10n.simpleManagementScheduleDescription,
      ),
      _SimpleManagementStep(
        icon: Icons.fact_check_outlined,
        title: l10n.simpleManagementTrackTitle,
        description: l10n.simpleManagementTrackDescription,
      ),
      _SimpleManagementStep(
        icon: Icons.person_outline_rounded,
        title: l10n.simpleManagementAccountTitle,
        description: l10n.simpleManagementAccountDescription,
      ),
      _SimpleManagementStep(
        icon: Icons.verified_user_outlined,
        title: l10n.simpleManagementTrustTitle,
        description: l10n.simpleManagementTrustDescription,
      ),
    ];

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AutolabCustomer.responsiveScreenMargin(context),
            AutolabCustomer.spacingSm,
            AutolabCustomer.responsiveScreenMargin(context),
            AutolabCustomer.spacingXxl + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _SimpleManagementHeader(
              title: l10n.aboutSimpleManagementTitle,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            const SizedBox(height: AutolabCustomer.spacingXl),
            _SimpleManagementIntro(text: l10n.simpleManagementIntro),
            const SizedBox(height: AutolabCustomer.spacingMd),
            for (final step in steps) ...[
              _SimpleManagementStepCard(step: step),
              const SizedBox(height: AutolabCustomer.spacingSmd),
            ],
          ],
        ),
      ),
    );
  }
}

class _SimpleManagementHeader extends StatelessWidget {
  const _SimpleManagementHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _SimpleManagementBackButton(onPressed: onBack),
              ),
              const AutolabLogoMark(width: 96, height: 36),
            ],
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingLg),
        Text(
          title,
          style: AutolabCustomer.h2.copyWith(
            color: AutolabCustomer.customerTextColor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SimpleManagementBackButton extends StatelessWidget {
  const _SimpleManagementBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 36,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AutolabCustomer.customerSecondaryTextColor(context),
            size: AutolabCustomer.iconSm,
          ),
        ),
      ),
    );
  }
}

class _SimpleManagementIntro extends StatelessWidget {
  const _SimpleManagementIntro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AutolabCustomer.spacingMd,
        AutolabCustomer.spacingMd,
        AutolabCustomer.spacingMd,
        AutolabCustomer.spacingLg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AutolabCustomer.customerSoftSurfaceColor(context),
            AutolabCustomer.customerBackgroundColor(context),
            AutolabCustomer.primary.withValues(alpha: 0.13),
          ],
        ),
      ),
      child: Text(
        text,
        style: AutolabCustomer.bodyLarge.copyWith(
          color: AutolabCustomer.customerSecondaryTextColor(context),
          height: 1.6,
        ),
      ),
    );
  }
}

class _SimpleManagementStepCard extends StatelessWidget {
  const _SimpleManagementStepCard({required this.step});

  final _SimpleManagementStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AutolabCustomer.spacingSm),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSoftSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SimpleManagementIconBadge(icon: step.icon),
          const SizedBox(width: AutolabCustomer.spacingSmd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AutolabCustomer.bodyLarge.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                Text(
                  step.description,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleManagementIconBadge extends StatelessWidget {
  const _SimpleManagementIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        shape: BoxShape.circle,
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Icon(
        icon,
        color: AutolabCustomer.primary,
        size: AutolabCustomer.iconMd,
      ),
    );
  }
}

class _SimpleManagementStep {
  const _SimpleManagementStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
