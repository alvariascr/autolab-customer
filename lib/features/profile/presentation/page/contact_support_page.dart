import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../l10n/app_localizations.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  static const routePath = '/contact-support';
  static const _supportPhone = '89147371';
  static const _supportEmail = 'info@autolab.lat';

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
            _SupportHeader(
              title: l10n.supportContactTitle,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            const SizedBox(height: AutolabCustomer.spacingXl),
            Text(
              l10n.supportContactHeading,
              style: AutolabCustomer.h3.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingSm),
            Text(
              l10n.supportContactSubtitle,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingLg),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AutolabCustomer.spacingSmd,
              mainAxisSpacing: AutolabCustomer.spacingSmd,
              childAspectRatio: 0.88,
              children: [
                _SupportContactCard(
                  icon: FontAwesomeIcons.whatsapp,
                  title: l10n.supportWhatsappTitle,
                  subtitle: l10n.supportWhatsappSubtitle,
                  onTap: () => _launchSupportUri(
                    context,
                    Uri.parse('https://wa.me/506$_supportPhone'),
                  ),
                ),
                _SupportContactCard(
                  icon: Icons.phone_outlined,
                  title: l10n.supportCallTitle,
                  subtitle: l10n.supportCallSubtitle,
                  onTap: () => _launchSupportUri(
                    context,
                    Uri(scheme: 'tel', path: _supportPhone),
                  ),
                ),
                _SupportContactCard(
                  icon: Icons.mail_outline_rounded,
                  title: l10n.supportEmailTitle,
                  subtitle: l10n.supportEmailSubtitle,
                  onTap: () => _launchSupportUri(
                    context,
                    Uri(
                      scheme: 'mailto',
                      path: _supportEmail,
                      queryParameters: {'subject': l10n.supportEmailSubject},
                    ),
                  ),
                ),
                _SupportContactCard(
                  icon: Icons.schedule_rounded,
                  title: l10n.supportScheduleTitle,
                  subtitle: l10n.supportScheduleSubtitle,
                  onTap: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.supportScheduleSubtitle)),
                      );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchSupportUri(BuildContext context, Uri uri) async {
    final l10n = AppLocalizations.of(context)!;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.settingsOpenLinkError)));
  }
}

class _SupportHeader extends StatelessWidget {
  const _SupportHeader({required this.title, required this.onBack});

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
                child: _SupportBackButton(onPressed: onBack),
              ),
              const AutolabLogoMark(width: 92, height: 34),
            ],
          ),
        ),
        const SizedBox(height: AutolabCustomer.spacingMd),
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

class _SupportBackButton extends StatelessWidget {
  const _SupportBackButton({required this.onPressed});

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

class _SupportContactCard extends StatelessWidget {
  const _SupportContactCard({
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
          padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            border: Border.all(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SupportIconBadge(icon: icon),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingXs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        height: 1.35,
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportIconBadge extends StatelessWidget {
  const _SupportIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        shape: BoxShape.circle,
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AutolabCustomer.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: AutolabCustomer.primary,
        size: AutolabCustomer.iconMd,
      ),
    );
  }
}
