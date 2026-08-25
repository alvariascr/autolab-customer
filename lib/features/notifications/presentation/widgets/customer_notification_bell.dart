import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

class CustomerNotificationBell extends StatelessWidget {
  const CustomerNotificationBell({
    super.key,
    required this.onTap,
    this.iconColor,
    this.indicatorBorderColor,
    this.iconSize,
  });

  final VoidCallback onTap;
  final Color? iconColor;
  final Color? indicatorBorderColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resolvedIconSize =
        iconSize ??
        AutolabCustomer.responsiveDouble(
          context,
          compact: AutolabCustomer.iconMd,
          regular: AutolabCustomer.iconLg - 4,
          tablet: AutolabCustomer.iconLg,
        );

    return BlocSelector<NotificationsCubit, NotificationsState, bool>(
      selector: (state) => state.hasUnread,
      builder: (context, hasUnread) => IconButton(
        onPressed: onTap,
        tooltip: l10n?.myAppointmentsNotificationsTooltip,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: iconColor ?? AutolabCustomer.customerTextColor(context),
              size: resolvedIconSize,
            ),
            if (hasUnread)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  key: const Key('notification-unread-indicator'),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AutolabCustomer.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          indicatorBorderColor ??
                          AutolabCustomer.customerBackgroundColor(context),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
