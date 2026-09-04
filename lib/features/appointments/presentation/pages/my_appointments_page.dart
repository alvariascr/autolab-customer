import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../core/theme/autolab_customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_session_cubit.dart';
import '../../../auth/domain/errors/auth_error_catalog.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notifications/presentation/widgets/customer_notification_bell.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../workshops/domain/entities/booked_appointment_slot.dart';
import '../../../workshops/domain/repositories/workshop_repository.dart';
import '../../../workshops/domain/services/appointment_service_classifier.dart';
import '../../../workshops/domain/services/workshop_availability_calculator.dart';
import '../../../workshops/domain/usecases/get_booked_appointment_slots.dart';
import '../../../workshops/domain/usecases/is_appointment_slot_available.dart';
import '../../domain/entities/appointment.dart';
import '../cubit/my_appointments_cubit.dart';
import '../cubit/my_appointments_state.dart';

enum _AppointmentTab { upcoming, past, canceled }

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  _AppointmentTab _selectedTab = _AppointmentTab.upcoming;
  final int _currentIndex = 4;

  void _handleBottomNavigation(int index) {
    NavigationHandler.handle(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => sl<MyAppointmentsCubit>()..load(),
      child: Scaffold(
        backgroundColor: AutolabCustomer.customerBackgroundColor(context),
        body: SafeArea(
          child: BlocBuilder<MyAppointmentsCubit, MyAppointmentsState>(
            builder: (context, state) {
              return Column(
                children: [
                  _AppointmentsHeader(
                    title: l10n.myAppointmentsTitle,
                    onNotificationTap: () =>
                        context.push(NotificationsPage.routePath),
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                        return;
                      }

                      context.go('/home-customer?tab=profile');
                    },
                  ),
                  const SizedBox(height: AutolabCustomer.spacingLg),
                  Text(
                    l10n.myAppointmentsSubtitle,
                    style: AutolabCustomer.body.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingLg),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AutolabCustomer.responsiveScreenMargin(
                        context,
                      ),
                    ),
                    child: _AppointmentTabs(
                      selectedTab: _selectedTab,
                      onChanged: (tab) => setState(() => _selectedTab = tab),
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(height: AutolabCustomer.spacingMd),
                  Expanded(child: _buildContent(context, state)),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: CustomBottomNavbar(
          currentIndex: _currentIndex,
          onTap: _handleBottomNavigation,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MyAppointmentsState state) {
    final l10n = AppLocalizations.of(context)!;

    if (state.status == MyAppointmentsStatus.loading ||
        state.status == MyAppointmentsStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == MyAppointmentsStatus.error) {
      final sessionExpired = state.code == AuthErrorCatalog.sessionExpired.code;

      return _MessageState(
        icon: Icons.cloud_off_rounded,
        title: sessionExpired
            ? l10n.authErrorSessionExpired
            : l10n.myAppointmentsLoadErrorTitle,
        message: state.message ?? l10n.myAppointmentsRetryMessage,
        actionLabel: sessionExpired
            ? l10n.authLoginSubmit
            : l10n.myAppointmentsRetryAction,
        onAction: sessionExpired
            ? () => context.read<AuthSessionCubit>().logout()
            : () => context.read<MyAppointmentsCubit>().load(),
      );
    }

    final appointments = _filterAppointments(state.appointments);

    if (appointments.isEmpty) {
      return _MessageState(
        icon: Icons.calendar_month_rounded,
        title: _emptyTitle(l10n),
        message: _emptyMessage(l10n),
        actionLabel: l10n.myAppointmentsSearchWorkshopsAction,
        onAction: () => NavigationHandler.handle(context, 2),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<MyAppointmentsCubit>().load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        itemCount:
            appointments.length +
            (_selectedTab == _AppointmentTab.upcoming ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == appointments.length) {
            return _ScheduleCard(
              onTap: () => NavigationHandler.handle(context, 2),
            );
          }

          final appointment = appointments[index];

          return _AppointmentCard(
            appointment: appointment,
            onTap: _selectedTab == _AppointmentTab.upcoming
                ? () => _showAppointmentDetail(context, appointment)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _showAppointmentDetail(
    BuildContext context,
    Appointment appointment,
  ) async {
    final cubit = context.read<MyAppointmentsCubit>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AutolabCustomer.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: _AppointmentDetailSheet(
            appointment: appointment,
            onReschedule: () {
              Navigator.pop(sheetContext);
              _startRescheduleFlow(context, cubit, appointment);
            },
            onCancel: () {
              Navigator.pop(sheetContext);
              _startCancelFlow(context, cubit, appointment);
            },
          ),
        );
      },
    );
  }

  Future<void> _startRescheduleFlow(
    BuildContext context,
    MyAppointmentsCubit cubit,
    Appointment appointment,
  ) async {
    final scheduledAt = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AutolabCustomer.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      builder: (_) => _RescheduleAppointmentSheet(appointment: appointment),
    );
    if (scheduledAt == null || !context.mounted) {
      return;
    }

    final updated = await cubit.rescheduleAppointment(
      appointment: appointment,
      scheduledAt: scheduledAt,
    );
    if (!context.mounted) {
      return;
    }

    if (updated == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _appointmentActionFailureMessage(
              l10n: l10n,
              code: cubit.state.code,
              message: cubit.state.message,
              fallback: l10n.myAppointmentRescheduleFailure,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _selectedTab = _AppointmentTab.upcoming);
    await showDialog<void>(
      context: context,
      builder: (_) => _RescheduleSuccessDialog(appointment: updated),
    );
  }

  Future<void> _startCancelFlow(
    BuildContext context,
    MyAppointmentsCubit cubit,
    Appointment appointment,
  ) async {
    final request = await showModalBottomSheet<_CancelAppointmentRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AutolabCustomer.transparent,
      builder: (_) => _CancelReasonSheet(appointment: appointment),
    );
    if (request == null || !context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CancelConfirmationDialog(appointment: appointment),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final canceled = await cubit.cancelAppointment(
      appointment: appointment,
      reason: request.reason,
      comments: request.comments,
    );
    if (!context.mounted) {
      return;
    }

    if (!canceled) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _appointmentActionFailureMessage(
              l10n: l10n,
              code: cubit.state.code,
              message: cubit.state.message,
              fallback: l10n.myAppointmentCancelFailure,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _selectedTab = _AppointmentTab.canceled);
    await showDialog<void>(
      context: context,
      builder: (_) => _CancelSuccessDialog(appointment: appointment),
    );
  }

  List<Appointment> _filterAppointments(List<Appointment> appointments) {
    final now = DateTime.now();

    final filtered = appointments.where((appointment) {
      final canceled = _isCanceled(appointment.status);
      final completed = _isCompleted(appointment.status);
      final noShow = _isNoShow(appointment.status);
      final past = appointment.scheduledAt.isBefore(now);

      return switch (_selectedTab) {
        _AppointmentTab.upcoming => !canceled && !completed && !noShow && !past,
        _AppointmentTab.past => !canceled && (completed || noShow || past),
        _AppointmentTab.canceled => canceled,
      };
    }).toList();

    return filtered..sort((left, right) {
      final comparison = left.scheduledAt.compareTo(right.scheduledAt);
      return _selectedTab == _AppointmentTab.upcoming
          ? comparison
          : -comparison;
    });
  }

  String _emptyTitle(AppLocalizations l10n) {
    return switch (_selectedTab) {
      _AppointmentTab.upcoming => l10n.myAppointmentsUpcomingEmptyTitle,
      _AppointmentTab.past => l10n.myAppointmentsPastEmptyTitle,
      _AppointmentTab.canceled => l10n.myAppointmentsCanceledEmptyTitle,
    };
  }

  String _emptyMessage(AppLocalizations l10n) {
    return switch (_selectedTab) {
      _AppointmentTab.upcoming => l10n.myAppointmentsUpcomingEmptyMessage,
      _AppointmentTab.past => l10n.myAppointmentsPastEmptyMessage,
      _AppointmentTab.canceled => l10n.myAppointmentsCanceledEmptyMessage,
    };
  }
}

class _AppointmentsHeader extends StatelessWidget {
  const _AppointmentsHeader({
    required this.title,
    required this.onBack,
    required this.onNotificationTap,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final horizontalMargin = AutolabCustomer.responsiveScreenMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalMargin,
        AutolabCustomer.spacingSm,
        horizontalMargin,
        0,
      ),
      child: SizedBox(
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(left: 0, top: 0, child: _AppointmentsLogo()),
            Positioned(
              left: 0,
              bottom: 0,
              child: _HeaderCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
              ),
            ),
            Positioned(
              bottom: 0,
              child: Text(
                title,
                style: AutolabCustomer.h3.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CustomerNotificationBell(onTap: onNotificationTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: AutolabCustomer.customerSurfaceColor(context),
          foregroundColor: AutolabCustomer.customerSecondaryTextColor(context),
        ),
        icon: Icon(icon, size: AutolabCustomer.iconSm),
      ),
    );
  }
}

class _AppointmentsLogo extends StatelessWidget {
  const _AppointmentsLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 58,
      height: 22,
      child: CustomPaint(painter: _AppointmentsLogoPainter()),
    );
  }
}

class _AppointmentsLogoPainter extends CustomPainter {
  const _AppointmentsLogoPainter();

  static const _sourceWidth = 622.0;
  static const _sourceHeight = 224.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _sourceWidth;
    final dy = (size.height - (_sourceHeight * scale)) / 2;
    canvas
      ..save()
      ..translate(0, dy)
      ..scale(scale);

    final paint = Paint()..color = AutolabCustomer.primary;
    for (final polygon in _polygons) {
      final path = Path()..moveTo(polygon.first.dx, polygon.first.dy);
      for (final point in polygon.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
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

class _AppointmentTabs extends StatelessWidget {
  const _AppointmentTabs({
    required this.selectedTab,
    required this.onChanged,
    required this.l10n,
  });

  final _AppointmentTab selectedTab;
  final ValueChanged<_AppointmentTab> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabButton(
          label: l10n.myAppointmentsUpcomingTab,
          selected: selectedTab == _AppointmentTab.upcoming,
          onTap: () => onChanged(_AppointmentTab.upcoming),
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: l10n.myAppointmentsPastTab,
          selected: selectedTab == _AppointmentTab.past,
          onTap: () => onChanged(_AppointmentTab.past),
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: l10n.myAppointmentsCanceledTab,
          selected: selectedTab == _AppointmentTab.canceled,
          onTap: () => onChanged(_AppointmentTab.canceled),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 40,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: selected
                ? AutolabCustomer.primary
                : AutolabCustomer.transparent,
            foregroundColor: selected
                ? AutolabCustomer.white
                : AutolabCustomer.customerTextColor(context),
            side: BorderSide(
              color: selected
                  ? AutolabCustomer.primary
                  : AutolabCustomer.customerBorderColor(context),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AutolabCustomer.label.copyWith(
                color: selected
                    ? AutolabCustomer.white
                    : AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, this.onTap});

  final Appointment appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = _AppointmentStatusVisual.from(appointment, l10n);

    return Material(
      color: AutolabCustomer.customerSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AutolabCustomer.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
            border: Border.all(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AutolabCustomer.primary,
                      borderRadius: BorderRadius.circular(
                        AutolabCustomer.radiusSm,
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: AutolabCustomer.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _textOrFallback(
                            appointment.workshopName,
                            l10n.appointmentWorkshopLabel,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AutolabCustomer.bodyLarge.copyWith(
                            color: AutolabCustomer.customerTextColor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _textOrFallback(
                            appointment.serviceName,
                            l10n.appointmentServiceLabel,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AutolabCustomer.body.copyWith(
                            color: AutolabCustomer.customerSecondaryTextColor(
                              context,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(visual: status),
                ],
              ),
              const SizedBox(height: AutolabCustomer.spacingMd),
              Divider(color: AutolabCustomer.customerBorderColor(context)),
              const SizedBox(height: AutolabCustomer.spacingSm),
              Row(
                children: [
                  Expanded(
                    child: _MetaItem(
                      icon: Icons.calendar_today_rounded,
                      label: DateFormat(
                        'dd MMMM yyyy',
                        'es',
                      ).format(appointment.scheduledAt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 18,
                    color: AutolabCustomer.customerBorderColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetaItem(
                      icon: Icons.access_time_rounded,
                      label: DateFormat('h:mm a', 'es')
                          .format(appointment.scheduledAt)
                          .replaceAll('.', '')
                          .toLowerCase(),
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
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.visual});

  final _AppointmentStatusVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AutolabCustomer.transparent,
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.primary),
      ),
      child: Text(
        visual.label,
        style: AutolabCustomer.caption.copyWith(
          color: AutolabCustomer.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AutolabCustomer.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AutolabCustomer.customerSurfaceColor(context),
      borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AutolabCustomer.primary,
                  borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AutolabCustomer.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.myAppointmentsNewAppointmentPrompt,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                l10n.myAppointmentsSearchWorkshopsAction,
                style: AutolabCustomer.body.copyWith(
                  color: AutolabCustomer.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentDetailSheet extends StatelessWidget {
  const _AppointmentDetailSheet({
    required this.appointment,
    required this.onReschedule,
    required this.onCancel,
  });

  final Appointment appointment;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = _AppointmentStatusVisual.from(appointment, l10n);
    final canceling = context.select((MyAppointmentsCubit cubit) {
      return cubit.state.cancelingAppointmentId == appointment.id;
    });

    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  l10n.myAppointmentDetailTitle,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.h3.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.directions_car_rounded,
                color: AutolabCustomer.primary,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _textOrFallback(
                        appointment.serviceName,
                        l10n.appointmentServiceLabel,
                      ),
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.customerTextColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _textOrFallback(
                        appointment.workshopName,
                        l10n.appointmentWorkshopLabel,
                      ),
                      style: AutolabCustomer.body.copyWith(
                        color: AutolabCustomer.customerSecondaryTextColor(
                          context,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(visual: status),
            ],
          ),
          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: AutolabCustomer.customerBorderColor(context),
          ),
          const SizedBox(height: 18),
          _DetailRow(
            label: l10n.myAppointmentDetailPlate,
            value: _textOrFallback(
              appointment.vehiclePlate,
              l10n.myAppointmentDetailNotAvailable,
            ),
          ),
          _DetailRow(
            label: l10n.myAppointmentDetailVehicle,
            value: _textOrFallback(
              appointment.vehicleType,
              l10n.myAppointmentDetailNotAvailable,
            ),
          ),
          _DetailRow(
            label: l10n.myAppointmentDetailDate,
            value: DateFormat(
              'dd MMM yyyy',
              'es',
            ).format(appointment.scheduledAt),
          ),
          _DetailRow(
            label: l10n.myAppointmentDetailTime,
            value: _formatAppointmentTime(appointment.scheduledAt),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.myAppointmentDetailItems,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• ${_textOrFallback(appointment.serviceName, l10n.appointmentServiceLabel)}',
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: canceling ? null : onReschedule,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AutolabCustomer.customerTextColor(context),
                    side: BorderSide(
                      color: AutolabCustomer.customerBorderColor(context),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AutolabCustomer.radiusSm,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    l10n.myAppointmentRescheduleAction,
                    style: const TextStyle(
                      fontFamily: AutolabCustomer.primaryFont,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: canceling ? null : onCancel,
                  style: FilledButton.styleFrom(
                    backgroundColor: AutolabCustomer.primary,
                    foregroundColor: AutolabCustomer.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AutolabCustomer.radiusSm,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: canceling
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AutolabCustomer.white,
                          ),
                        )
                      : Text(
                          l10n.myAppointmentCancelAction,
                          style: const TextStyle(
                            fontFamily: AutolabCustomer.primaryFont,
                            fontWeight: FontWeight.w900,
                          ),
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

class _RescheduleAppointmentSheet extends StatefulWidget {
  const _RescheduleAppointmentSheet({required this.appointment});

  final Appointment appointment;

  @override
  State<_RescheduleAppointmentSheet> createState() =>
      _RescheduleAppointmentSheetState();
}

class _RescheduleAppointmentSheetState
    extends State<_RescheduleAppointmentSheet> {
  final _availabilityCalculator = WorkshopAvailabilityCalculator();
  final _workshopRepository = sl<WorkshopRepository>();
  final _productRepository = sl<ProductRepository>();
  final _getBookedAppointmentSlots = sl<GetBookedAppointmentSlots>();
  final _isAppointmentSlotAvailable = sl<IsAppointmentSlotAvailable>();
  int _availabilityRequestId = 0;

  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;
  var _loading = true;
  var _confirming = false;
  var _failed = false;
  List<DateTime> _unavailableDates = const [];
  Map<DateTime, List<String>> _availableTimesByDate = const {};

  // Appointment only carries serviceId/serviceName, not how long the
  // service actually takes -- without this, the availability grid and the
  // final confirm check both fall back to a guessed default duration, which
  // can show (or accept) a time that doesn't actually have room for this
  // specific service. Best-effort: if the lookup fails, everything below
  // still falls back to that same guessed default, same as before this fix.
  double? _serviceDurationHours;
  bool _isInspectionService = false;

  @override
  void initState() {
    super.initState();
    _focusedDate = _validFocusedDay(
      widget.appointment.scheduledAt.year,
      widget.appointment.scheduledAt.month,
    );
    _selectedDate = _dateOnly(widget.appointment.scheduledAt);
    unawaited(_initializeAvailability());
  }

  Future<void> _initializeAvailability() async {
    await _loadServiceDuration();
    if (!mounted) {
      return;
    }
    await _loadAvailability(_focusedDate);
  }

  Future<void> _loadServiceDuration() async {
    // Bulk-fetches the workshop's full active catalog and filters by id
    // client-side because ProductRepository has no single-item lookup
    // (getActiveProducts/getActiveProductsByWorkshop only). Acceptable for
    // now given catalog sizes in this app; revisit if a getById is added.
    final result = await _productRepository.getActiveProductsByWorkshop(
      widget.appointment.workshopId,
    );
    if (!mounted) {
      return;
    }

    result.fold((_) => null, (products) {
      for (final product in products) {
        if (product.id == widget.appointment.serviceId) {
          setState(() {
            _serviceDurationHours = product.estimatedDurationHours;
            _isInspectionService =
                AppointmentServiceClassifier.isInspectionService(product);
          });
          return;
        }
      }
    });
  }

  Future<void> _loadAvailability(DateTime month) async {
    final requestId = ++_availabilityRequestId;
    setState(() {
      _loading = true;
      _failed = false;
      _focusedDate = _validFocusedDay(month.year, month.month);
    });

    try {
      final workshopResult = await _workshopRepository.getWorkshopById(
        widget.appointment.workshopId,
      );
      final workshop = workshopResult.getOrElse(() => null);
      if (workshop == null) {
        throw StateError('missing workshop');
      }

      final monthStart = DateTime(month.year, month.month);
      final monthEnd = DateTime(month.year, month.month + 1);
      final bookedSlots = await _getBookedAppointmentSlots(
        workshopId: widget.appointment.workshopId,
        startDate: monthStart,
        endDate: monthEnd,
      );
      final availability = _availabilityCalculator.calculateMonth(
        workshop: workshop,
        month: monthStart,
        bookedSlots: _withoutCurrentAppointmentSlot(bookedSlots),
        serviceDurationHours: _serviceDurationHours,
        isInspectionService: _isInspectionService,
      );

      if (!mounted || requestId != _availabilityRequestId) {
        return;
      }

      setState(() {
        _unavailableDates = availability.unavailableDates;
        _availableTimesByDate = availability.availableTimesByDate;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _availabilityRequestId) {
        return;
      }

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  List<BookedAppointmentSlot> _withoutCurrentAppointmentSlot(
    List<BookedAppointmentSlot> slots,
  ) {
    return slots.where((slot) {
      return !_sameMinute(slot.start.toLocal(), widget.appointment.scheduledAt);
    }).toList();
  }

  List<String> _availableTimesForSelectedDate() {
    final date = _selectedDate;
    if (date == null) {
      return const [];
    }

    return _availableTimesByDate[_dateOnly(date)] ?? const [];
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = _selectedDate;
    final selectedTime = _selectedTime;
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.myAppointmentRescheduleSelectHour)),
      );
      return;
    }

    final scheduledAt = _combineDateAndTime(selectedDate, selectedTime);
    if (scheduledAt == null) {
      return;
    }

    setState(() => _confirming = true);
    final available = await _isAppointmentSlotAvailable(
      workshopId: widget.appointment.workshopId,
      scheduledDateTime: scheduledAt,
      serviceDurationHours: _serviceDurationHours,
      isInspectionService: _isInspectionService,
    );
    if (!mounted) {
      return;
    }

    setState(() => _confirming = false);
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.myAppointmentRescheduleNoHours)),
      );
      await _loadAvailability(_focusedDate);
      return;
    }

    Navigator.pop(context, scheduledAt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final availableTimes = _availableTimesForSelectedDate();

    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  l10n.myAppointmentRescheduleTitle,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.h3.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          TableCalendar<void>(
            locale: 'es',
            firstDay: _calendarFirstDay(),
            lastDay: DateTime.now().add(const Duration(days: 120)),
            focusedDay: _focusedDate,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: {
              CalendarFormat.month: l10n.myAppointmentRescheduleCalendarMonth,
            },
            selectedDayPredicate: (day) {
              final selectedDate = _selectedDate;
              return selectedDate != null && isSameDay(day, selectedDate);
            },
            enabledDayPredicate: (day) {
              if (_loading || _failed) {
                return false;
              }

              final date = _dateOnly(day);
              final unavailable = _unavailableDates.any((blocked) {
                return isSameDay(blocked, date);
              });
              return !unavailable && _availableTimesByDate.containsKey(date);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = _dateOnly(selectedDay);
                _focusedDate = focusedDay;
                _selectedTime = null;
              });
            },
            onPageChanged: _loadAvailability,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w900,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: AutolabCustomer.customerTextColor(context),
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: AutolabCustomer.customerTextColor(context),
              ),
            ),
            calendarStyle: const CalendarStyle(outsideDaysVisible: true),
            calendarBuilders: CalendarBuilders<void>(
              defaultBuilder: (context, day, focusedDay) =>
                  _RescheduleCalendarDay(day: day),
              disabledBuilder: (context, day, focusedDay) =>
                  _RescheduleCalendarDay(day: day, disabled: true),
              outsideBuilder: (context, day, focusedDay) =>
                  _RescheduleCalendarDay(day: day, outside: true),
              selectedBuilder: (context, day, focusedDay) =>
                  _RescheduleCalendarDay(day: day, selected: true),
              todayBuilder: (context, day, focusedDay) =>
                  _RescheduleCalendarDay(day: day, today: true),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.myAppointmentRescheduleAvailableHours,
            style: AutolabCustomer.bodyLarge.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            _InlineStateMessage(
              icon: Icons.hourglass_top_rounded,
              message: l10n.myAppointmentRescheduleLoading,
            )
          else if (_failed)
            _InlineStateMessage(
              icon: Icons.error_outline_rounded,
              message: l10n.myAppointmentRescheduleLoadError,
            )
          else if (availableTimes.isEmpty)
            _InlineStateMessage(
              icon: Icons.event_busy_rounded,
              message: l10n.myAppointmentRescheduleNoHours,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTimes.map((time) {
                return _RescheduleTimeButton(
                  label: _displaySlotTime(time),
                  selected: _selectedTime == time,
                  onTap: () => setState(() => _selectedTime = time),
                );
              }).toList(),
            ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed:
                _confirming ||
                    _loading ||
                    _failed ||
                    _selectedDate == null ||
                    _selectedTime == null
                ? null
                : _confirm,
            style: FilledButton.styleFrom(
              backgroundColor: AutolabCustomer.primary,
              foregroundColor: AutolabCustomer.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: _confirming
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AutolabCustomer.white,
                    ),
                  )
                : Text(
                    l10n.myAppointmentRescheduleConfirm,
                    style: const TextStyle(
                      fontFamily: AutolabCustomer.primaryFont,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

DateTime _calendarFirstDay() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _validFocusedDay(int year, int month) {
  final firstDay = _calendarFirstDay();
  final monthStart = DateTime(year, month);
  return monthStart.isBefore(firstDay) ? firstDay : monthStart;
}

class _RescheduleCalendarDay extends StatelessWidget {
  const _RescheduleCalendarDay({
    required this.day,
    this.disabled = false,
    this.outside = false,
    this.selected = false,
    this.today = false,
  });

  final DateTime day;
  final bool disabled;
  final bool outside;
  final bool selected;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AutolabCustomer.white
        : disabled || outside
        ? AutolabCustomer.customerSecondaryTextColor(
            context,
          ).withValues(alpha: 0.55)
        : AutolabCustomer.customerTextColor(context);
    final background = selected
        ? AutolabCustomer.primary
        : today
        ? AutolabCustomer.primary.withValues(alpha: 0.14)
        : AutolabCustomer.transparent;

    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RescheduleTimeButton extends StatelessWidget {
  const _RescheduleTimeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? AutolabCustomer.primary
              : AutolabCustomer.customerSurfaceColor(context),
          foregroundColor: selected
              ? AutolabCustomer.white
              : AutolabCustomer.customerTextColor(context),
          side: BorderSide(
            color: selected
                ? AutolabCustomer.primary
                : AutolabCustomer.customerBorderColor(context),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineStateMessage extends StatelessWidget {
  const _InlineStateMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AutolabCustomer.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelReasonSheet extends StatefulWidget {
  const _CancelReasonSheet({required this.appointment});

  final Appointment appointment;

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  late String _selectedReason;
  final _commentsController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedReason = AppLocalizations.of(
      context,
    )!.myAppointmentCancelReasonNoNeed;
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reasons = [
      l10n.myAppointmentCancelReasonNoNeed,
      l10n.myAppointmentCancelReasonChangedWorkshop,
      l10n.myAppointmentCancelReasonBookingError,
      l10n.myAppointmentCancelReasonCannotAttend,
      l10n.myAppointmentCancelReasonOther,
    ];

    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  l10n.myAppointmentCancelTitle,
                  textAlign: TextAlign.center,
                  style: AutolabCustomer.h3.copyWith(
                    color: AutolabCustomer.customerTextColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.myAppointmentCancelReasonQuestion,
            style: AutolabCustomer.bodyLarge.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...reasons.map(
            (reason) => _CancelReasonOption(
              label: reason,
              selected: reason == _selectedReason,
              onTap: () => setState(() => _selectedReason = reason),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentsController,
            minLines: 4,
            maxLines: 4,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerTextColor(context),
            ),
            decoration: InputDecoration(
              hintText: l10n.myAppointmentCancelCommentsHint,
              hintStyle: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
              ),
              filled: true,
              fillColor: AutolabCustomer.customerSurfaceColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                borderSide: BorderSide(
                  color: AutolabCustomer.customerBorderColor(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                borderSide: BorderSide(
                  color: AutolabCustomer.customerBorderColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
                borderSide: const BorderSide(color: AutolabCustomer.primary),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                _CancelAppointmentRequest(
                  reason: _selectedReason,
                  comments: _commentsController.text,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AutolabCustomer.primary,
              foregroundColor: AutolabCustomer.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(
              l10n.myAppointmentCancelContinue,
              style: const TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelReasonOption extends StatelessWidget {
  const _CancelReasonOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? AutolabCustomer.primary
                  : AutolabCustomer.customerSecondaryTextColor(context),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AutolabCustomer.body.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelConfirmationDialog extends StatelessWidget {
  const _CancelConfirmationDialog({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AutolabCustomer.customerSurfaceColor(context),
      surfaceTintColor: AutolabCustomer.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: AutolabCustomer.warning,
        size: 72,
      ),
      title: Text(
        l10n.myAppointmentCancelConfirmTitle,
        textAlign: TextAlign.center,
        style: AutolabCustomer.h3.copyWith(
          color: AutolabCustomer.customerTextColor(context),
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.myAppointmentCancelConfirmMessage,
            textAlign: TextAlign.center,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          _AppointmentSummaryCard(appointment: appointment),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AutolabCustomer.primary,
                  side: const BorderSide(color: AutolabCustomer.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AutolabCustomer.radiusSm,
                    ),
                  ),
                ),
                child: Text(
                  l10n.myAppointmentCancelConfirmNo,
                  style: AutolabCustomer.label.copyWith(
                    color: AutolabCustomer.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingSm),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AutolabCustomer.primary,
                  foregroundColor: AutolabCustomer.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AutolabCustomer.radiusSm,
                    ),
                  ),
                ),
                child: Text(
                  l10n.myAppointmentCancelConfirmYes,
                  style: AutolabCustomer.label.copyWith(
                    color: AutolabCustomer.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CancelSuccessDialog extends StatelessWidget {
  const _CancelSuccessDialog({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AutolabCustomer.customerSurfaceColor(context),
      surfaceTintColor: AutolabCustomer.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        color: AutolabCustomer.success,
        size: 86,
      ),
      title: Text(
        l10n.myAppointmentCancelSuccessTitle,
        textAlign: TextAlign.center,
        style: AutolabCustomer.h3.copyWith(
          color: AutolabCustomer.customerTextColor(context),
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.myAppointmentCancelSuccessMessage,
            textAlign: TextAlign.center,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          _AppointmentSummaryCard(appointment: appointment),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AutolabCustomer.primary,
              foregroundColor: AutolabCustomer.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              l10n.myAppointmentCancelSuccessAction,
              style: const TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RescheduleSuccessDialog extends StatelessWidget {
  const _RescheduleSuccessDialog({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AutolabCustomer.customerSurfaceColor(context),
      surfaceTintColor: AutolabCustomer.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        color: AutolabCustomer.success,
        size: 86,
      ),
      title: Text(
        l10n.myAppointmentRescheduleSuccessTitle,
        textAlign: TextAlign.center,
        style: AutolabCustomer.h3.copyWith(
          color: AutolabCustomer.customerTextColor(context),
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.myAppointmentRescheduleSuccessMessage,
            textAlign: TextAlign.center,
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          _AppointmentSummaryCard(appointment: appointment),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AutolabCustomer.primary,
              foregroundColor: AutolabCustomer.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              l10n.myAppointmentRescheduleSuccessAction,
              style: const TextStyle(
                fontFamily: AutolabCustomer.primaryFont,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppointmentSummaryCard extends StatelessWidget {
  const _AppointmentSummaryCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AutolabCustomer.customerSurfaceColor(context),
        borderRadius: BorderRadius.circular(AutolabCustomer.radiusSm),
        border: Border.all(color: AutolabCustomer.customerBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _textOrFallback(
              appointment.serviceName,
              l10n.appointmentServiceLabel,
            ),
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerTextColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _textOrFallback(
              appointment.workshopName,
              l10n.appointmentWorkshopLabel,
            ),
            style: AutolabCustomer.caption.copyWith(
              color: AutolabCustomer.customerSecondaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _MetaItem(
            icon: Icons.calendar_today_rounded,
            label: DateFormat(
              'dd MMM yyyy',
              'es',
            ).format(appointment.scheduledAt),
          ),
          const SizedBox(height: 8),
          _MetaItem(
            icon: Icons.access_time_rounded,
            label: _formatAppointmentTime(appointment.scheduledAt),
          ),
          const SizedBox(height: 8),
          _MetaItem(
            icon: Icons.directions_car_rounded,
            label: _textOrFallback(
              appointment.vehicleType,
              l10n.myAppointmentDetailNotAvailable,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 14,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AutolabCustomer.customerSurfaceColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AutolabCustomer.customerBorderColor(context),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CancelAppointmentRequest {
  const _CancelAppointmentRequest({required this.reason, this.comments});

  final String reason;
  final String? comments;
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AutolabCustomer.customerSurfaceColor(context),
                borderRadius: BorderRadius.circular(AutolabCustomer.radiusMd),
                border: Border.all(
                  color: AutolabCustomer.customerBorderColor(context),
                ),
              ),
              child: Icon(icon, color: AutolabCustomer.primary, size: 42),
            ),
            const SizedBox(height: AutolabCustomer.spacingLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AutolabCustomer.h3.copyWith(
                color: AutolabCustomer.customerTextColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AutolabCustomer.body.copyWith(
                color: AutolabCustomer.customerSecondaryTextColor(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: AutolabCustomer.spacingLg),
            SizedBox(
              width: 190,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AutolabCustomer.primary,
                  foregroundColor: AutolabCustomer.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AutolabCustomer.radiusSm,
                    ),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: AutolabCustomer.label.copyWith(
                    color: AutolabCustomer.white,
                    fontWeight: FontWeight.w900,
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

class _AppointmentStatusVisual {
  const _AppointmentStatusVisual({required this.label});

  final String label;

  factory _AppointmentStatusVisual.from(
    Appointment appointment,
    AppLocalizations l10n,
  ) {
    final normalized = appointment.status.trim().toLowerCase();

    if (_isCanceled(normalized)) {
      return _AppointmentStatusVisual(label: l10n.myAppointmentsStatusCanceled);
    }

    if (normalized.contains('no_show')) {
      return _AppointmentStatusVisual(label: l10n.myAppointmentsStatusNoShow);
    }

    if (normalized.contains('complete') || normalized.contains('complet')) {
      return _AppointmentStatusVisual(
        label: l10n.myAppointmentsStatusCompleted,
      );
    }

    if (normalized.contains('checked_in')) {
      return _AppointmentStatusVisual(
        label: l10n.myAppointmentsStatusCheckedIn,
      );
    }

    if (normalized.contains('in_progress')) {
      return _AppointmentStatusVisual(
        label: l10n.myAppointmentsStatusInProgress,
      );
    }

    if (appointment.scheduledAt.isBefore(DateTime.now())) {
      return _AppointmentStatusVisual(label: l10n.myAppointmentsStatusExpired);
    }

    if (normalized.contains('confirm') ||
        normalized.contains('scheduled') ||
        normalized.contains('pending')) {
      return _AppointmentStatusVisual(
        label: l10n.myAppointmentsStatusConfirmed,
      );
    }

    return _AppointmentStatusVisual(label: l10n.myAppointmentsStatusConfirmed);
  }
}

bool _isCanceled(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized.contains('cancel');
}

bool _isCompleted(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized.contains('complete') || normalized.contains('complet');
}

bool _isNoShow(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized.contains('no_show');
}

String _textOrFallback(String? value, String fallback) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _friendlyFailureMessage(String? message, String fallback) {
  final text = message?.trim() ?? '';
  final looksTechnical =
      text.isEmpty || RegExp(r'^[A-Z0-9_.:-]+$').hasMatch(text);
  if (looksTechnical) {
    return fallback;
  }

  return text;
}

String _appointmentActionFailureMessage({
  required AppLocalizations l10n,
  required String? code,
  required String? message,
  required String fallback,
}) {
  return switch (code) {
    MyAppointmentsCubit.cancelBusyCode => l10n.myAppointmentCancelBusyMessage,
    MyAppointmentsCubit.rescheduleBusyCode =>
      l10n.myAppointmentRescheduleBusyMessage,
    _ => _friendlyFailureMessage(message, fallback),
  };
}

String _formatAppointmentTime(DateTime value) {
  return DateFormat(
    'h:mm a',
    'es',
  ).format(value).replaceAll('.', '').toLowerCase();
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _sameMinute(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day &&
      left.hour == right.hour &&
      left.minute == right.minute;
}

DateTime? _combineDateAndTime(DateTime date, String time) {
  final parts = time.split(':');
  if (parts.length != 2) {
    return null;
  }

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }

  return DateTime(date.year, date.month, date.day, hour, minute);
}

String _displaySlotTime(String time) {
  final scheduledAt = _combineDateAndTime(DateTime(2026), time);
  if (scheduledAt == null) {
    return time;
  }

  return DateFormat(
    'hh:mm a',
    'es',
  ).format(scheduledAt).replaceAll('.', '').toUpperCase();
}
