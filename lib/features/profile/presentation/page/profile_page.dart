import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_session_cubit.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 4;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4EF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(
            color: Color(0xFF181411),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF181411),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.profileAccountTitle,
                    style: const TextStyle(
                      color: Color(0xFF181411),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileAccountSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B5F57),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ProfileMenuCard(
              leading: const _ProfileActionIcon(
                icon: Icons.calendar_month_rounded,
                backgroundColor: Color(0xFFE9F0FF),
                foregroundColor: Color(0xFF0B5CFF),
              ),
              title: l10n.profileAppointmentsTitle,
              subtitle: l10n.profileAppointmentsSubtitle,
              borderColor: const Color(0xFF0B5CFF),
              trailingColor: const Color(0xFF0B5CFF),
              onTap: () => context.push('/appointments'),
            ),
            const SizedBox(height: 20),
            _ProfileMenuCard(
              leading: const _ProfileActionIcon(
                icon: Icons.directions_car_filled_outlined,
                backgroundColor: Color(0xFFFFE9E7),
                foregroundColor: Color(0xFFE32119),
              ),
              title: l10n.vehiclesTitle,
              subtitle: l10n.vehiclesProfileSubtitle,
              borderColor: const Color(0xFFE9DDD2),
              onTap: () => context.push('/vehicles'),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE9DDD2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileSessionTitle,
                    style: const TextStyle(
                      color: Color(0xFF181411),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileSessionSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B5F57),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF181411),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        context.read<AuthSessionCubit>().logout();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(l10n.profileLogout),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavigation,
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.onTap,
    this.trailingColor = const Color(0xFF6B5F57),
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Color borderColor;
  final Color trailingColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF181411),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B5F57),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: trailingColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActionIcon extends StatelessWidget {
  const _ProfileActionIcon({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: foregroundColor),
    );
  }
}
