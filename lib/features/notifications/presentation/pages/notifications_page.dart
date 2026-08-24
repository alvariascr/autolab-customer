import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/customer_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static const routePath = '/notifications';

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
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
      appBar: AppBar(
        backgroundColor: AutolabCustomer.customerBackgroundColor(context),
        foregroundColor: AutolabCustomer.customerTextColor(context),
        elevation: 0,
        leading: IconButton(
          onPressed: context.pop,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          l10n.notificationsPageTitle,
          style: AutolabCustomer.h3.copyWith(
            color: AutolabCustomer.customerTextColor(context),
          ),
        ),
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
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
          if (state.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: context.read<NotificationsCubit>().load,
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
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AutolabCustomer.responsiveScreenMargin(context),
                AutolabCustomer.spacingMd,
                AutolabCustomer.responsiveScreenMargin(context),
                AutolabCustomer.spacingXxl,
              ),
              itemCount: state.notifications.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AutolabCustomer.spacingSmd),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () => context.read<NotificationsCubit>().markAsRead(
                    notification.id,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty();

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
                l10n.notificationsEmptyTitle,
                textAlign: TextAlign.center,
                style: AutolabCustomer.h3.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                ),
              ),
              const SizedBox(height: AutolabCustomer.spacingSm),
              Text(
                l10n.notificationsEmptyMessage,
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
    final secondary = AutolabCustomer.customerSecondaryTextColor(context);
    final localizations = MaterialLocalizations.of(context);
    final date = notification.updatedAt.toLocal();
    return Material(
      color: notification.isRead
          ? AutolabCustomer.customerSurfaceColor(context)
          : Color.alphaBlend(
              AutolabCustomer.primary.withValues(alpha: 0.06),
              AutolabCustomer.customerSurfaceColor(context),
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        side: BorderSide(
          color: notification.isRead
              ? AutolabCustomer.customerBorderColor(context)
              : AutolabCustomer.primary.withValues(alpha: 0.75),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AutolabCustomer.primary,
                      borderRadius: BorderRadius.circular(
                        AutolabCustomer.radiusSm,
                      ),
                    ),
                    child: Icon(
                      _iconForType(notification.type),
                      color: Colors.white,
                      size: AutolabCustomer.iconSm,
                    ),
                  ),
                  const SizedBox(width: AutolabCustomer.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AutolabCustomer.bodyLarge.copyWith(
                                  color: AutolabCustomer.customerTextColor(
                                    context,
                                  ),
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: AutolabCustomer.spacingSm),
                            _NotificationTypeBadge(
                              label: _labelForType(context, notification.type),
                            ),
                          ],
                        ),
                        const SizedBox(height: AutolabCustomer.spacingXs),
                        Text(
                          notification.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AutolabCustomer.body.copyWith(
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              Divider(
                height: 1,
                color: AutolabCustomer.customerBorderColor(context),
              ),
              const SizedBox(height: AutolabCustomer.spacingSm),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: AutolabCustomer.primary,
                  ),
                  const SizedBox(width: AutolabCustomer.spacingSm),
                  Expanded(
                    child: Text(
                      localizations.formatMediumDate(date),
                      style: AutolabCustomer.caption.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 18,
                    child: VerticalDivider(
                      width: AutolabCustomer.spacingLg,
                      color: AutolabCustomer.customerBorderColor(context),
                    ),
                  ),
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AutolabCustomer.primary,
                  ),
                  const SizedBox(width: AutolabCustomer.spacingSm),
                  Text(
                    localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date)),
                    style: AutolabCustomer.caption.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
      'appointment' || 'cita' => Icons.calendar_month_rounded,
      'payment' || 'pago' => Icons.receipt_long_rounded,
      'vehicle' || 'vehiculo' => Icons.directions_car_rounded,
      'promotion' || 'promocion' => Icons.local_offer_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  String _labelForType(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    return switch (type.toLowerCase()) {
      'appointment' || 'cita' => l10n.notificationsTypeAppointment,
      'payment' || 'pago' => l10n.notificationsTypePayment,
      'vehicle' || 'vehiculo' => l10n.notificationsTypeVehicle,
      'promotion' || 'promocion' => l10n.notificationsTypePromotion,
      _ => l10n.notificationsTypeMessage,
    };
  }
}

class _NotificationTypeBadge extends StatelessWidget {
  const _NotificationTypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AutolabCustomer.spacingSm,
        vertical: AutolabCustomer.spacingXs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AutolabCustomer.primary),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      ),
      child: Text(
        label,
        style: AutolabCustomer.caption.copyWith(
          color: AutolabCustomer.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
