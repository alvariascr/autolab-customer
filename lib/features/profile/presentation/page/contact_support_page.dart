import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_remote_settings.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../l10n/app_localizations.dart';

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({super.key});

  static const routePath = '/contact-support';

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  late final Future<AppRemoteSettings> _supportInfoFuture;

  @override
  void initState() {
    super.initState();
    _supportInfoFuture = _loadSupportInfo();
  }

  Future<AppRemoteSettings> _loadSupportInfo() => AppRemoteSettings.load();

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
            FutureBuilder<AppRemoteSettings>(
              future: _supportInfoFuture,
              initialData: AppRemoteSettings.fallback,
              builder: (context, snapshot) {
                final supportInfo = snapshot.data ?? AppRemoteSettings.fallback;

                final cards = [
                  _SupportContactCard(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp),
                    title: l10n.supportWhatsappTitle,
                    subtitle: l10n.supportWhatsappSubtitle,
                    onTap: () => _launchSupportUri(
                      context,
                      Uri.parse(
                        'https://wa.me/506${supportInfo.whatsappPhone}',
                      ),
                    ),
                  ),
                  _SupportContactCard(
                    icon: const Icon(Icons.phone_outlined),
                    title: l10n.supportCallTitle,
                    subtitle: l10n.supportCallSubtitle,
                    onTap: () => _launchSupportUri(
                      context,
                      Uri(scheme: 'tel', path: supportInfo.callPhone),
                    ),
                  ),
                  _SupportContactCard(
                    icon: const Icon(Icons.mail_outline_rounded),
                    title: l10n.supportEmailTitle,
                    subtitle: l10n.supportEmailSubtitle,
                    onTap: () => _launchSupportUri(
                      context,
                      Uri(
                        scheme: 'mailto',
                        path: supportInfo.email,
                        queryParameters: {'subject': l10n.supportEmailSubject},
                      ),
                    ),
                  ),
                  _SupportContactCard(
                    icon: const Icon(Icons.schedule_rounded),
                    title: l10n.supportScheduleTitle,
                    subtitle: supportInfo.scheduleText,
                    onTap: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(supportInfo.scheduleText)),
                        );
                    },
                  ),
                ];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AutolabCustomer.spacingSmd,
                    mainAxisSpacing: AutolabCustomer.spacingSmd,
                    mainAxisExtent: AutolabCustomer.responsiveDouble(
                      context,
                      compact: 178,
                      regular: 190,
                      tablet: 210,
                    ),
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) => cards[index],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchSupportUri(BuildContext context, Uri uri) async {
    final l10n = AppLocalizations.of(context)!;
    final errorMessage = l10n.settingsOpenLinkError;
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(errorMessage)));
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
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: Material(
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

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Container(
        decoration: BoxDecoration(
          color: AutolabCustomer.customerSoftSurfaceColor(context),
          borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
          border: Border.all(
            color: AutolabCustomer.customerBorderColor(context),
          ),
        ),
        child: Material(
          color: AutolabCustomer.transparent,
          borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
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
        ),
      ),
    );
  }
}

class _SupportIconBadge extends StatelessWidget {
  const _SupportIconBadge({required this.icon});

  final Widget icon;

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
      child: IconTheme(
        data: const IconThemeData(
          color: AutolabCustomer.primary,
          size: AutolabCustomer.iconMd,
        ),
        child: Center(child: icon),
      ),
    );
  }
}
