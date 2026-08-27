import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_remote_settings.dart';
import '../../../../core/theme/app_theme_mode_cubit.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_session_cubit.dart';
import '../widgets/customer_page_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const routePath = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _openTermsAndConditions() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final settings = await AppRemoteSettings.load();
    final opened = await launchUrl(
      settings.termsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsOpenLinkError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            CustomerPageHeader(
              title: l10n.garageSettings,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AutolabCustomer.responsiveScreenMargin(context),
                  AutolabCustomer.spacingSmd,
                  AutolabCustomer.responsiveScreenMargin(context),
                  AutolabCustomer.spacingXl +
                      MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _SettingsSection(
                    title: l10n.settingsAccountTitle,
                    children: [
                      _SettingsActionTile(
                        icon: Icons.person_outline_rounded,
                        title: l10n.settingsEditProfile,
                        trailingText: l10n.settingsComingSoon,
                      ),
                      _SettingsActionTile(
                        icon: Icons.lock_outline_rounded,
                        title: l10n.settingsChangePassword,
                        trailingText: l10n.settingsComingSoon,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AutolabCustomer.spacingMd),
                  _SettingsSection(
                    title: l10n.settingsPreferencesTitle,
                    children: [
                      const _ThemeModeSettingsTile(),
                      _SettingsActionTile(
                        icon: Icons.language_rounded,
                        title: l10n.settingsLanguage,
                        trailingText: l10n.settingsComingSoon,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AutolabCustomer.spacingMd),
                  _SettingsSection(
                    title: l10n.settingsPrivacyTitle,
                    children: [
                      _SettingsActionTile(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.settingsPrivacyPolicy,
                        trailingText: l10n.settingsComingSoon,
                      ),
                      _SettingsActionTile(
                        icon: Icons.description_outlined,
                        title: l10n.settingsTerms,
                        onTap: _openTermsAndConditions,
                      ),
                      _SettingsActionTile(
                        icon: Icons.delete_outline_rounded,
                        title: l10n.settingsDeleteAccount,
                        titleColor: AutolabCustomer.primary,
                        trailingText: l10n.settingsComingSoon,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AutolabCustomer.spacingMd),
                  _SettingsSection(
                    title: l10n.settingsAppTitle,
                    children: [
                      _SettingsActionTile(
                        icon: Icons.report_gmailerrorred_outlined,
                        title: l10n.settingsReportProblem,
                        trailingText: l10n.settingsComingSoon,
                      ),
                      _SettingsActionTile(
                        icon: Icons.cleaning_services_outlined,
                        title: l10n.settingsClearCache,
                        trailingText: l10n.settingsComingSoon,
                      ),
                      _SettingsActionTile(
                        icon: Icons.info_outline_rounded,
                        title: l10n.settingsVersion,
                        trailingText: l10n.settingsComingSoon,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AutolabCustomer.spacingMd),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AutolabCustomer.primary,
                        foregroundColor: AutolabCustomer.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AutolabCustomer.radiusSm,
                          ),
                        ),
                        textStyle: AutolabCustomer.body.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () {
                        context.read<AuthSessionCubit>().logout();
                      },
                      child: Text(l10n.profileLogout),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AutolabCustomer.spacingXs,
            bottom: AutolabCustomer.spacingSm,
          ),
          child: Text(
            title,
            style: AutolabCustomer.bodyLarge.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AutolabCustomer.customerElevatedSurfaceColor(context),
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
            border: Border.all(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ThemeModeSettingsTile extends StatelessWidget {
  const _ThemeModeSettingsTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AppThemeModeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = switch (mode) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system =>
            MediaQuery.platformBrightnessOf(context) == Brightness.dark,
        };

        return _SettingsActionTile(
          icon: Icons.dark_mode_outlined,
          title: l10n.settingsThemeMode,
          subtitle: isDark
              ? l10n.settingsThemeModeEnabled
              : l10n.settingsThemeModeDisabled,
          trailing: Switch(
            value: isDark,
            activeThumbColor: AutolabCustomer.primary,
            inactiveThumbColor: AutolabCustomer.customerDisabledTextColor(
              context,
            ),
            inactiveTrackColor: AutolabCustomer.customerSoftSurfaceColor(
              context,
            ),
            onChanged: (enabled) {
              context.read<AppThemeModeCubit>().setThemeMode(
                enabled ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailing,
    this.titleColor,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final textColor = titleColor ?? AutolabCustomer.customerTextColor(context);
    final secondaryTextColor = AutolabCustomer.customerSecondaryTextColor(
      context,
    );

    return Material(
      color: AutolabCustomer.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AutolabCustomer.spacingMd,
                vertical: AutolabCustomer.spacingSmd,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: titleColor ?? secondaryTextColor,
                    size: AutolabCustomer.iconSm,
                  ),
                  const SizedBox(width: AutolabCustomer.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AutolabCustomer.body.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AutolabCustomer.spacingXs),
                          Text(
                            subtitle!,
                            style: AutolabCustomer.caption.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else if (trailingText != null)
                    Text(
                      trailingText!,
                      textAlign: TextAlign.right,
                      style: AutolabCustomer.caption.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: secondaryTextColor,
                      size: AutolabCustomer.iconSm,
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AutolabCustomer.transparent,
                      size: AutolabCustomer.iconSm,
                    ),
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                indent: 52,
                color: AutolabCustomer.customerBorderColor(context),
              ),
          ],
        ),
      ),
    );
  }
}
