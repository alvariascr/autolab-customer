import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/app_theme_mode_cubit.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_session_cubit.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notifications/presentation/widgets/customer_notification_bell.dart';
import '../../application/active_garage_vehicle_loader.dart';
import '../../application/garage_vehicle_controller.dart';
import '../../domain/entities/garage_vehicle.dart';
import '../../domain/usecases/get_default_garage_vehicle.dart';
import '../helpers/garage_vehicle_display.dart';
import 'about_us_page.dart';
import 'contact_support_page.dart';
import 'delivery_addresses_page.dart';
import 'favorite_workshops_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.showBottomNavigation = true,
    this.garageVehicleController,
  });

  final bool showBottomNavigation;
  final GarageVehicleController? garageVehicleController;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _profilePhotoPathKey = 'profile_photo_path';
  int _currentIndex = 4;
  String? _profilePhotoPath;
  GarageVehicle? _activeVehicle;
  int _activeVehicleLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    widget.garageVehicleController?.addListener(_onGarageVehiclesChanged);
    _loadProfilePhoto();
    unawaited(_loadActiveVehicle());
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.garageVehicleController != widget.garageVehicleController) {
      oldWidget.garageVehicleController?.removeListener(
        _onGarageVehiclesChanged,
      );
      widget.garageVehicleController?.addListener(_onGarageVehiclesChanged);
    }
  }

  @override
  void dispose() {
    widget.garageVehicleController?.removeListener(_onGarageVehiclesChanged);
    super.dispose();
  }

  void _onGarageVehiclesChanged() {
    unawaited(_loadActiveVehicle());
  }

  void _handleBottomNavigation(int index) {
    if (index == 2) {
      NavigationHandler.handle(context, index);
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    NavigationHandler.handle(context, index);
  }

  Future<void> _openVehiclesPage() async {
    await context.push('/vehicles');
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _currentUserDisplayName();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AutolabCustomer.responsiveScreenMargin(context),
            AutolabCustomer.spacingLg,
            AutolabCustomer.responsiveScreenMargin(context),
            AutolabCustomer.spacingXxl,
          ),
          children: [
            _GarageHeader(
              onNotificationTap: () =>
                  context.push(NotificationsPage.routePath),
            ),
            const SizedBox(height: AutolabCustomer.spacingSm),
            Text(
              l10n.garageTitle,
              style: AutolabCustomer.bodyLarge.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingLg),
            _GarageUserSummary(
              displayName: displayName,
              profilePhotoPath: _profilePhotoPath,
              onEditPhotoTap: _showChangePhotoDialog,
            ),
            if (_activeVehicle case final activeVehicle?) ...[
              const SizedBox(height: AutolabCustomer.spacingLg),
              _ActiveVehicleCard(vehicle: activeVehicle),
            ],
            const SizedBox(height: AutolabCustomer.spacingLg),
            _SectionTitle(l10n.garageQuickAccessTitle),
            const SizedBox(height: AutolabCustomer.spacingSmd),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AutolabCustomer.spacingSmd,
              mainAxisSpacing: AutolabCustomer.spacingSmd,
              childAspectRatio: 1.55,
              children: [
                _QuickAccessCard(
                  icon: Icons.calendar_month_rounded,
                  label: l10n.profileAppointmentsTitle,
                  onTap: () => context.push('/appointments'),
                ),
                _QuickAccessCard(
                  icon: Icons.directions_car_filled_outlined,
                  label: l10n.vehiclesTitle,
                  onTap: _openVehiclesPage,
                ),
                _QuickAccessCard(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.loyaltyProgramsTitle,
                  onTap: () => context.push('/loyalty-programs'),
                ),
                _QuickAccessCard(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.garageHistory,
                  onTap: () => context.push('/purchases'),
                ),
              ],
            ),
            const SizedBox(height: AutolabCustomer.spacingMd),
            _SectionTitle(l10n.garageManagementTitle),
            const SizedBox(height: AutolabCustomer.spacingSmd),
            _GarageMenuGroup(
              children: [
                _GarageMenuItem(
                  icon: Icons.favorite_border_rounded,
                  label: l10n.garageFavorites,
                  onTap: () => context.push(FavoriteWorkshopsPage.routePath),
                ),
                _GarageMenuItem(
                  icon: Icons.location_on_outlined,
                  label: l10n.garageAddresses,
                  onTap: () => context.push(DeliveryAddressesPage.routePath),
                ),
                _GarageMenuItem(
                  icon: Icons.notifications_none_rounded,
                  label: l10n.myAppointmentsNotificationsTooltip,
                  onTap: () => context.push(NotificationsPage.routePath),
                ),
                const _GarageThemeModeItem(
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: AutolabCustomer.spacingLg),
            _SectionTitle(l10n.garageSupportTitle),
            const SizedBox(height: AutolabCustomer.spacingSmd),
            _GarageMenuGroup(
              children: [
                _GarageMenuItem(
                  icon: Icons.location_on_outlined,
                  label: l10n.garageContactSupport,
                  onTap: () => context.push(ContactSupportPage.routePath),
                ),
                _GarageMenuItem(
                  icon: Icons.credit_card_rounded,
                  label: l10n.garageAboutUs,
                  onTap: () => context.push(AboutUsPage.routePath),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: AutolabCustomer.spacingLg),
            const _LogoutCard(),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNavigation
          ? CustomBottomNavbar(
              currentIndex: _currentIndex,
              onTap: _handleBottomNavigation,
            )
          : null,
    );
  }

  String _currentUserDisplayName() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final metadata = user?.userMetadata ?? const <String, dynamic>{};
      final metadataName =
          metadata['name'] ?? metadata['full_name'] ?? metadata['display_name'];
      final name = metadataName?.toString().trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }

      final emailName = user?.email?.split('@').first.trim();
      if (emailName != null && emailName.isNotEmpty) {
        return _humanizeEmailName(emailName);
      }
    } catch (_) {
      // Supabase may not be initialized in widget tests.
    }

    return AppLocalizations.of(context)!.garageDefaultCustomerName;
  }

  String _humanizeEmailName(String value) {
    return value
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          final normalized = part.trim().toLowerCase();
          return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
        })
        .join(' ');
  }

  Future<void> _showChangePhotoDialog() async {
    final l10n = AppLocalizations.of(context)!;

    final shouldPickPhoto = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AutolabCustomer.customerSurfaceColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
            side: BorderSide(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AutolabCustomer.spacingLg,
            AutolabCustomer.spacingLg,
            AutolabCustomer.spacingLg,
            AutolabCustomer.spacingMd,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                color: AutolabCustomer.primary,
                size: AutolabCustomer.iconLg,
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              Text(
                l10n.garageChangeProfilePhotoTitle,
                textAlign: TextAlign.center,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AutolabCustomer.primaryButton,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(
                    l10n.garageChooseFromGallery,
                    style: AutolabCustomer.body.copyWith(
                      color: AutolabCustomer.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingSm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    l10n.garageCloseAction,
                    style: AutolabCustomer.body.copyWith(
                      color: AutolabCustomer.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldPickPhoto != true) {
      return;
    }

    final image = await ImagePickerPlatform.instance.getImageFromSource(
      source: ImageSource.gallery,
      options: const ImagePickerOptions(imageQuality: 85),
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _profilePhotoPath = image.path;
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profilePhotoPathKey, image.path);
  }

  Future<void> _loadProfilePhoto() async {
    final preferences = await SharedPreferences.getInstance();
    final path = preferences.getString(_profilePhotoPathKey);

    if (path == null || path.isEmpty || !File(path).existsSync() || !mounted) {
      return;
    }

    setState(() {
      _profilePhotoPath = path;
    });
  }

  Future<void> _loadActiveVehicle() async {
    final generation = ++_activeVehicleLoadGeneration;
    try {
      final activeVehicle = await loadActiveGarageVehicle(
        sl<GetDefaultGarageVehicle>(),
      );

      if (!mounted || generation != _activeVehicleLoadGeneration) {
        return;
      }
      if (activeVehicle == null) {
        setState(() {
          _activeVehicle = null;
        });
        return;
      }

      setState(() {
        _activeVehicle = activeVehicle;
      });
    } catch (_) {
      // The active vehicle is optional on the garage screen.
    }
  }
}

class _GarageHeader extends StatelessWidget {
  const _GarageHeader({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _GarageLogo(),
          Align(
            alignment: Alignment.centerRight,
            child: CustomerNotificationBell(onTap: onNotificationTap),
          ),
        ],
      ),
    );
  }
}

class _GarageLogo extends StatelessWidget {
  const _GarageLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 28,
      child: CustomPaint(painter: _GarageLogoPainter()),
    );
  }
}

class _GarageLogoPainter extends CustomPainter {
  _GarageLogoPainter();

  static const _sourceWidth = 622.0;
  static const _sourceHeight = 224.0;
  final Paint _paint = Paint()..color = AutolabCustomer.primary;
  final Path _path = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _sourceWidth;
    final dy = (size.height - (_sourceHeight * scale)) / 2;
    canvas
      ..save()
      ..translate(0, dy)
      ..scale(scale);

    _paint.color = AutolabCustomer.primary;
    for (final polygon in _polygons) {
      _path
        ..reset()
        ..moveTo(polygon.first.dx, polygon.first.dy);

      for (var index = 1; index < polygon.length; index++) {
        final point = polygon[index];
        _path.lineTo(point.dx, point.dy);
      }

      _path.close();
      canvas.drawPath(_path, _paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  static const _polygons = [
    [
      Offset(503.87, 7.07),
      Offset(512.96, 35.05),
      Offset(542.39, 35.05),
      Offset(518.58, 52.35),
      Offset(527.68, 80.34),
      Offset(503.87, 63.04),
      Offset(480.07, 80.34),
      Offset(489.16, 52.35),
      Offset(465.35, 35.05),
      Offset(494.78, 35.05),
    ],
    [
      Offset(279.41, 7.07),
      Offset(404.43, 7.07),
      Offset(462.51, 109.9),
      Offset(542.39, 109.9),
      Offset(603.12, 216.93),
      Offset(397.95, 216.93),
    ],
    [
      Offset(18.88, 216.93),
      Offset(51.05, 160),
      Offset(22.67, 109.9),
      Offset(79.45, 109.74),
      Offset(137.46, 7.07),
      Offset(261.85, 7.07),
      Offset(380.35, 216.93),
      Offset(256, 216.93),
      Offset(199.66, 117.18),
      Offset(174.43, 161.84),
      Offset(205.94, 216.93),
    ],
  ];
}

class _GarageUserSummary extends StatelessWidget {
  const _GarageUserSummary({
    required this.displayName,
    required this.onEditPhotoTap,
    this.profilePhotoPath,
  });

  final String displayName;
  final String? profilePhotoPath;
  final VoidCallback onEditPhotoTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AutolabCustomer.primary,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: _ProfilePhotoContent(profilePhotoPath: profilePhotoPath),
        ),
        const SizedBox(width: AutolabCustomer.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.garageGreeting(displayName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AutolabCustomer.spacingSm),
                  _EditProfilePhotoButton(onTap: onEditPhotoTap),
                ],
              ),
              const SizedBox(height: AutolabCustomer.spacingXs),
              Text(
                l10n.garageWelcomeSubtitle,
                style: AutolabCustomer.caption.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfilePhotoContent extends StatelessWidget {
  const _ProfilePhotoContent({this.profilePhotoPath});

  final String? profilePhotoPath;

  @override
  Widget build(BuildContext context) {
    final path = profilePhotoPath;

    if (path == null || path.isEmpty) {
      return const Icon(
        Icons.person_rounded,
        color: AutolabCustomer.white,
        size: 38,
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.person_rounded,
        color: AutolabCustomer.white,
        size: 38,
      ),
    );
  }
}

class _EditProfilePhotoButton extends StatelessWidget {
  const _EditProfilePhotoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(AutolabCustomer.spacingXs),
          child: Icon(
            Icons.edit_square,
            color: AutolabCustomer.primary,
            size: AutolabCustomer.iconSm,
          ),
        ),
      ),
    );
  }
}

class _ActiveVehicleCard extends StatelessWidget {
  const _ActiveVehicleCard({required this.vehicle});

  final GarageVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 48,
            child: _ActiveVehicleImage(imageUrl: vehicle.imageUrl),
          ),
          const SizedBox(width: AutolabCustomer.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garageVehicleTitle(vehicle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  garageActiveVehicleSubtitle(vehicle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.caption.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AutolabCustomer.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AutolabCustomer.spacingXs),
                    Text(
                      l10n.garageActiveVehicle,
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveVehicleImage extends StatelessWidget {
  const _ActiveVehicleImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const _ActiveVehiclePlaceholder(),
      );
    }

    return const _ActiveVehiclePlaceholder();
  }
}

class _ActiveVehiclePlaceholder extends StatelessWidget {
  const _ActiveVehiclePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.directions_car_filled_rounded,
      color: AutolabCustomer.customerTextColor(context),
      size: 44,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AutolabCustomer.bodyLarge.copyWith(
        color: AutolabCustomer.customerTextColor(context),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AutolabCustomer.customerSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AutolabCustomer.primary, size: 34),
              const SizedBox(height: AutolabCustomer.spacingSm),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GarageMenuGroup extends StatelessWidget {
  const _GarageMenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      ),
      child: Column(children: children),
    );
  }
}

class _GarageThemeModeItem extends StatelessWidget {
  const _GarageThemeModeItem({this.showDivider = true});

  final bool showDivider;

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

        return _GarageMenuItem(
          icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          label: isDark
              ? l10n.profileDarkModeTitle
              : l10n.profileLightModeTitle,
          trailing: Switch(
            value: isDark,
            activeThumbColor: AutolabCustomer.primary,
            activeTrackColor: AutolabCustomer.primary.withValues(alpha: 0.35),
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
          showDivider: showDivider,
        );
      },
    );
  }
}

class _GarageMenuItem extends StatelessWidget {
  const _GarageMenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onTap != null || trailing != null;
    final color = isInteractive
        ? AutolabCustomer.customerTextColor(context)
        : AutolabCustomer.customerSecondaryTextColor(
            context,
          ).withValues(alpha: 0.45);

    return InkWell(
      onTap: isInteractive ? onTap : null,
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AutolabCustomer.spacingMd,
              vertical: AutolabCustomer.spacingSm,
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: AutolabCustomer.iconSm),
                const SizedBox(width: AutolabCustomer.spacingMd),
                Expanded(
                  child: Text(
                    label,
                    style: AutolabCustomer.body.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing case final trailing?)
                  trailing
                else if (isInteractive)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: color,
                    size: AutolabCustomer.iconSm,
                  ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              indent: 48,
              color: AutolabCustomer.customerBorderColor(context),
            ),
        ],
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.garageSupportTitle,
            style: AutolabCustomer.bodyLarge.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AutolabCustomer.spacingXs),
          Text(
            l10n.profileSessionSubtitle,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerTextColor(context),
            ),
          ),
          const SizedBox(height: AutolabCustomer.spacingMd),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AutolabCustomer.primary,
                foregroundColor: AutolabCustomer.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
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
    );
  }
}
