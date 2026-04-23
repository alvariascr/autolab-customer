import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_session_cubit.dart';

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.heroLabel,
    required this.heroValue,
    required this.summaryTitle,
    required this.quickActionsTitle,
    required this.currentStatusTitle,
    required this.highlights,
    required this.quickActions,
    required this.statusCards,
  });

  final String title;
  final String subtitle;
  final String heroLabel;
  final String heroValue;
  final String summaryTitle;
  final String quickActionsTitle;
  final String currentStatusTitle;
  final List<HomeInfoItem> highlights;
  final List<HomeInfoItem> quickActions;
  final List<HomeStatusItem> statusCards;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181411),
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7B6F67),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () {
                context.read<AuthSessionCubit>().logout();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF181411),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(l10n.adminHomeLogout),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCard(label: heroLabel, value: heroValue),
                      const SizedBox(height: 24),
                      isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _InfoSection(
                                    title: summaryTitle,
                                    items: highlights,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _InfoSection(
                                    title: quickActionsTitle,
                                    items: quickActions,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _InfoSection(
                                  title: summaryTitle,
                                  items: highlights,
                                ),
                                const SizedBox(height: 20),
                                _InfoSection(
                                  title: quickActionsTitle,
                                  items: quickActions,
                                ),
                              ],
                            ),
                      const SizedBox(height: 24),
                      Text(
                        currentStatusTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181411),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: statusCards
                            .map((item) => _StatusCard(item: item))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF181411), Color(0xFF41352E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22181411),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.items});

  final String title;
  final List<HomeInfoItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181411),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4ECE6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: const Color(0xFF9B3D24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181411),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6F625A),
                            height: 1.35,
                          ),
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.item});

  final HomeStatusItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7DDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7B6F67),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF181411),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: item.tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.caption,
              style: theme.textTheme.labelLarge?.copyWith(
                color: item.tone,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeInfoItem {
  const HomeInfoItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class HomeStatusItem {
  const HomeStatusItem({
    required this.label,
    required this.value,
    required this.caption,
    required this.tone,
  });

  final String label;
  final String value;
  final String caption;
  final Color tone;
}

List<HomeInfoItem> buildHomeInfoItems(
  List<({String title, String description, IconData icon})> items,
) {
  return items
      .map(
        (item) => HomeInfoItem(
          title: item.title,
          description: item.description,
          icon: item.icon,
        ),
      )
      .toList();
}

List<HomeStatusItem> buildHomeStatusItems(
  List<({String label, String value, String caption, Color tone})> items,
) {
  return items
      .map(
        (item) => HomeStatusItem(
          label: item.label,
          value: item.value,
          caption: item.caption,
          tone: item.tone,
        ),
      )
      .toList();
}
