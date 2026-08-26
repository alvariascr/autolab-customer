import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../l10n/app_localizations.dart';
import 'simple_management_page.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const routePath = '/about-us';
  static final _termsUri = Uri.parse(
    'https://www.autolab.lat/terminos-y-condiciones/',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            _AboutHeader(
              title: l10n.garageAboutUs,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            const SizedBox(height: AutolabCustomer.spacingXl),
            const _AboutHeroCard(),
            const SizedBox(height: AutolabCustomer.spacingSmd),
            _AboutActionCard(
              icon: Icons.assignment_outlined,
              title: l10n.aboutSimpleManagementTitle,
              subtitle: l10n.aboutSimpleManagementSubtitle,
              onTap: () => context.push(SimpleManagementPage.routePath),
            ),
            const SizedBox(height: AutolabCustomer.spacingSmd),
            _AboutActionCard(
              icon: Icons.description_outlined,
              title: l10n.settingsTerms,
              subtitle: l10n.aboutTermsSubtitle,
              onTap: () => _openTerms(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTerms(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final opened = await launchUrl(
      _termsUri,
      mode: LaunchMode.externalApplication,
    );

    if (opened || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.settingsOpenLinkError)));
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader({required this.title, required this.onBack});

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
                child: _AboutBackButton(onPressed: onBack),
              ),
              const AutolabLogoMark(width: 92, height: 34),
            ],
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingMd),
        Text(
          title,
          style: AutolabCustomer.h3.copyWith(
            color: AutolabCustomer.customerTextColor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AboutBackButton extends StatelessWidget {
  const _AboutBackButton({required this.onPressed});

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
          dimension: 34,
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

class _AboutHeroCard extends StatelessWidget {
  const _AboutHeroCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AutolabCustomer.customerSoftSurfaceColor(context),
            AutolabCustomer.customerSoftSurfaceColor(context),
            AutolabCustomer.primary.withValues(alpha: 0.16),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AutolabCustomer.customerSurfaceColor(context),
              borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
              border: Border.all(
                color: AutolabCustomer.customerBorderColor(context),
              ),
            ),
            child: const Center(
              child: AutolabLogoMark(width: 70, height: 28),
            ),
          ),
          const SizedBox(width: AutolabCustomer.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aboutAutolabTitle,
                  style: AutolabCustomer.h3.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AutolabCustomer.spacingXs),
                Text(
                  l10n.aboutAutolabDescription,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerSecondaryTextColor(context),
                    height: 1.45,
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

class _AboutActionCard extends StatelessWidget {
  const _AboutActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        child: Ink(
          padding: const EdgeInsets.all(AutolabCustomer.spacingSmd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            border: Border.all(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Row(
            children: [
              _AboutIconBadge(icon: icon),
              const SizedBox(width: AutolabCustomer.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AutolabCustomer.body.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    Text(
                      subtitle,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AutolabCustomer.primary,
                size: AutolabCustomer.iconMd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutIconBadge extends StatelessWidget {
  const _AboutIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        shape: BoxShape.circle,
        border: Border.all(
          color: AutolabCustomer.customerBorderColor(context),
        ),
      ),
      child: Icon(
        icon,
        color: AutolabCustomer.primary,
        size: AutolabCustomer.iconMd,
      ),
    );
  }
}
