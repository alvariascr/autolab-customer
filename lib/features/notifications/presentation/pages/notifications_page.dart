import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../core/theme/autolab_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/customer_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

enum _NotificationFilter { all, unread, promotions }

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static const routePath = '/notifications';

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AutolabCustomer.customerBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _NotificationsHeader(
              title: l10n.notificationsPageTitle,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                context.go('/home-customer?tab=profile');
              },
            ),
            Expanded(
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  if (state.status == NotificationsStatus.loading &&
                      state.notifications.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == NotificationsStatus.failure &&
                      state.notifications.isEmpty) {
                    return _NotificationsError(
                      message: state.message ?? l10n.notificationsLoadError,
                      onRetry: context.read<NotificationsCubit>().load,
                    );
                  }

                  final visibleNotifications = _filteredNotifications(
                    state.notifications,
                  );

                  if (state.notifications.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: context.read<NotificationsCubit>().load,
                      color: AutolabCustomer.primary,
                      child: const CustomScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _NotificationsEmpty(),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: context.read<NotificationsCubit>().load,
                    color: AutolabCustomer.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AutolabCustomer.responsiveScreenMargin(context),
                        AutolabCustomer.spacingSmd,
                        AutolabCustomer.responsiveScreenMargin(context),
                        AutolabCustomer.spacingXl +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      children: [
                        _NotificationFilterBar(
                          selectedFilter: _selectedFilter,
                          notifications: state.notifications,
                          onChanged: (filter) {
                            setState(() => _selectedFilter = filter);
                          },
                        ),
                        const SizedBox(height: AutolabCustomer.spacingLg),
                        if (visibleNotifications.isEmpty)
                          _NotificationsEmpty(
                            title: l10n.notificationsFilteredEmptyTitle,
                            message: l10n.notificationsFilteredEmptyMessage,
                          )
                        else
                          ..._groupedNotificationItems(
                            context,
                            visibleNotifications,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CustomerNotification> _filteredNotifications(
    List<CustomerNotification> notifications,
  ) {
    return switch (_selectedFilter) {
      _NotificationFilter.all => notifications,
      _NotificationFilter.unread =>
        notifications
            .where((notification) => !notification.isRead)
            .toList(growable: false),
      _NotificationFilter.promotions =>
        notifications
            .where((notification) => _isPromotion(notification.type))
            .toList(growable: false),
    };
  }

  List<Widget> _groupedNotificationItems(
    BuildContext context,
    List<CustomerNotification> notifications,
  ) {
    final groups = <String, List<CustomerNotification>>{};

    for (final notification in notifications) {
      final label = _groupLabel(context, notification.updatedAt.toLocal());
      groups.putIfAbsent(label, () => []).add(notification);
    }

    final items = <Widget>[];
    for (final entry in groups.entries) {
      items
        ..add(_NotificationGroupTitle(label: entry.key))
        ..add(const SizedBox(height: AutolabCustomer.spacingSmd));

      for (final notification in entry.value) {
        items
          ..add(
            _NotificationCard(
              notification: notification,
              onTap: () => context.read<NotificationsCubit>().markAsRead(
                notification.id,
              ),
            ),
          )
          ..add(const SizedBox(height: AutolabCustomer.spacingSmd));
      }

      items.add(const SizedBox(height: AutolabCustomer.spacingSm));
    }

    return items;
  }

  String _groupLabel(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final notificationDay = DateUtils.dateOnly(date);

    if (notificationDay == today) {
      return l10n.notificationsGroupToday;
    }

    if (notificationDay == today.subtract(const Duration(days: 1))) {
      return l10n.notificationsGroupYesterday;
    }

    if (notificationDay.isAfter(today.subtract(const Duration(days: 7)))) {
      return l10n.notificationsGroupThisWeek;
    }

    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  bool _isPromotion(String type) {
    final normalized = type.trim().toLowerCase();
    return normalized == 'promotion' || normalized == 'promocion';
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AutolabCustomer.responsiveScreenMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AutolabCustomer.spacingSm,
        horizontalPadding,
        AutolabCustomer.spacingSm,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _NotificationsBackButton(onPressed: onBack),
              ),
              const AutolabLogoMark(width: 96, height: 36),
            ],
          ),
          const SizedBox(height: AutolabCustomer.spacingLg),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AutolabCustomer.h2.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationsBackButton extends StatelessWidget {
  const _NotificationsBackButton({required this.onPressed});

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

class _NotificationFilterBar extends StatelessWidget {
  const _NotificationFilterBar({
    required this.selectedFilter,
    required this.notifications,
    required this.onChanged,
  });

  final _NotificationFilter selectedFilter;
  final List<CustomerNotification> notifications;
  final ValueChanged<_NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = [
      _NotificationFilterData(
        filter: _NotificationFilter.all,
        icon: Icons.grid_view_rounded,
        label: l10n.notificationsAllFilter,
        count: notifications.length,
      ),
      _NotificationFilterData(
        filter: _NotificationFilter.unread,
        icon: Icons.circle_rounded,
        label: l10n.notificationsUnreadFilter,
        count: notifications.where((item) => !item.isRead).length,
      ),
      _NotificationFilterData(
        filter: _NotificationFilter.promotions,
        icon: Icons.sell_rounded,
        label: l10n.notificationsPromotionsFilter,
        count: notifications.where((item) {
          final type = item.type.trim().toLowerCase();
          return type == 'promotion' || type == 'promocion';
        }).length,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in filters) ...[
            _NotificationFilterChip(
              icon: item.icon,
              label: item.label,
              count: item.count,
              selected: selectedFilter == item.filter,
              onSelected: () => onChanged(item.filter),
            ),
            const SizedBox(width: AutolabCustomer.spacingSm),
          ],
        ],
      ),
    );
  }
}

class _NotificationFilterData {
  const _NotificationFilterData({
    required this.filter,
    required this.icon,
    required this.label,
    required this.count,
  });

  final _NotificationFilter filter;
  final IconData icon;
  final String label;
  final int count;
}

class _NotificationFilterChip extends StatelessWidget {
  const _NotificationFilterChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? AutolabCustomer.primary
        : AutolabCustomer.customerSecondaryTextColor(context);

    return Material(
      color: selected
          ? AutolabCustomer.primary.withValues(alpha: 0.10)
          : AutolabCustomer.customerSoftSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusButton),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusButton),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AutolabCustomer.spacingMd,
            vertical: AutolabCustomer.spacingSmd,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusButton),
            border: Border.all(
              color: selected
                  ? AutolabCustomer.primary
                  : AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foregroundColor, size: AutolabCustomer.iconSm),
              const SizedBox(width: AutolabCustomer.spacingSm),
              Text(
                '$label ($count)',
                style: AutolabCustomer.caption.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationGroupTitle extends StatelessWidget {
  const _NotificationGroupTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AutolabCustomer.body.copyWith(
        color: AutolabCustomer.customerSecondaryTextColor(context),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty({this.title, this.message});

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.all(
            AutolabCustomer.responsiveScreenMargin(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _NotificationIcon(icon: Icons.notifications_none_rounded),
              const SizedBox(height: AutolabCustomer.spacingLg),
              Text(
                title ?? l10n.notificationsEmptyTitle,
                textAlign: TextAlign.center,
                style: AutolabCustomer.h3.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingSm),
              Text(
                message ?? l10n.notificationsEmptyMessage,
                textAlign: TextAlign.center,
                style: AutolabCustomer.body.copyWith(
                  color: AutolabCustomer.customerSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          AutolabCustomer.responsiveScreenMargin(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _NotificationIcon(icon: Icons.cloud_off_rounded),
            const SizedBox(height: AutolabCustomer.spacingLg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerTextColor(context),
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingMd),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AutolabCustomer.primary,
                foregroundColor: AutolabCustomer.white,
              ),
              child: Text(l10n.notificationsRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AutolabCustomer.spacingLg),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48, color: AutolabCustomer.primary),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final CustomerNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final date = notification.updatedAt.toLocal();
    final textColor = notification.isRead
        ? AutolabCustomer.customerSecondaryTextColor(context)
        : AutolabCustomer.customerTextColor(context);

    return Material(
      color: notification.isRead
          ? AutolabCustomer.customerSoftSurfaceColor(context)
          : Color.alphaBlend(
              AutolabCustomer.primary.withValues(alpha: 0.05),
              AutolabCustomer.customerSoftSurfaceColor(context),
            ),
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
              color: notification.isRead
                  ? AutolabCustomer.customerBorderColor(context)
                  : AutolabCustomer.primary.withValues(alpha: 0.75),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NotificationTypeIcon(icon: _iconForType(notification.type)),
              const SizedBox(width: AutolabCustomer.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AutolabCustomer.spacingXs),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AutolabCustomer.body.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutolabCustomer.spacingSmd),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date)),
                    style: AutolabCustomer.caption.copyWith(
                      color: AutolabCustomer.customerSecondaryTextColor(
                        context,
                      ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(height: AutolabCustomer.spacingSmd),
                    const _UnreadDot(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type.toLowerCase()) {
      'appointment' || 'cita' => Icons.calendar_month_outlined,
      'payment' || 'pago' => Icons.credit_card_outlined,
      'vehicle' || 'vehiculo' => Icons.build_outlined,
      'promotion' || 'promocion' => Icons.local_offer_outlined,
      _ => Icons.notifications_none_rounded,
    };
  }
}

class _NotificationTypeIcon extends StatelessWidget {
  const _NotificationTypeIcon({required this.icon});

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
      ),
      child: Icon(
        icon,
        color: AutolabCustomer.primary,
        size: AutolabCustomer.iconMd,
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AutolabCustomer.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
