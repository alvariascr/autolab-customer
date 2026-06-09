import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_session_cubit.dart';
import '../../../auth/domain/errors/auth_error_catalog.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
import '../../../workshops/domain/entities/booked_appointment_slot.dart';
import '../../../workshops/domain/repositories/workshop_repository.dart';
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
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF06285E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                return;
              }

              context.go('/profile');
            },
          ),
          title: Text(
            l10n.myAppointmentsTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: l10n.myAppointmentsNotificationsTooltip,
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<MyAppointmentsCubit, MyAppointmentsState>(
            builder: (context, state) {
              return Column(
                children: [
                  const SizedBox(height: 18),
                  Text(
                    l10n.myAppointmentsSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF1D2A44),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _AppointmentTabs(
                      selectedTab: _selectedTab,
                      onChanged: (tab) => setState(() => _selectedTab = tab),
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(height: 16),
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
      backgroundColor: Colors.transparent,
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
      backgroundColor: Colors.transparent,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyFailureMessage(
              cubit.state.message,
              AppLocalizations.of(context)!.myAppointmentRescheduleFailure,
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
      backgroundColor: Colors.transparent,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyFailureMessage(
              cubit.state.message,
              AppLocalizations.of(context)!.myAppointmentCancelFailure,
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
          danger: selectedTab == _AppointmentTab.canceled,
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
    this.danger = false,
  });

  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = danger
        ? const Color(0xFFD83945)
        : const Color(0xFF0B5CFF);

    return Expanded(
      child: SizedBox(
        height: 44,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? selectedColor : Colors.white,
            foregroundColor: selected ? Colors.white : const Color(0xFF101B35),
            side: BorderSide(
              color: selected ? selectedColor : const Color(0xFFE0E5EF),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7ECF5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0A1D3C),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
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
                      color: status.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.garage_rounded,
                      color: status.accent,
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
                          style: const TextStyle(
                            color: Color(0xFF101B35),
                            fontSize: 16,
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
                          style: const TextStyle(
                            color: Color(0xFF1D2A44),
                            fontSize: 14,
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
              const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        visual.label,
        style: TextStyle(
          color: visual.foreground,
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
        Icon(icon, color: const Color(0xFF53617A), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF101B35),
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
      color: const Color(0xFFF1F5FB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF0B5CFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.myAppointmentsNewAppointmentPrompt,
                  style: const TextStyle(
                    color: Color(0xFF101B35),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                l10n.myAppointmentsSearchWorkshopsAction,
                style: const TextStyle(
                  color: Color(0xFF0B5CFF),
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
                  style: const TextStyle(
                    color: Color(0xFF101B35),
                    fontSize: 18,
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
                color: Color(0xFF101B35),
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
                      style: const TextStyle(
                        color: Color(0xFF101B35),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _textOrFallback(
                        appointment.workshopName,
                        l10n.appointmentWorkshopLabel,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF53617A),
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
          const Divider(height: 1, color: Color(0xFFE7ECF5)),
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
            style: const TextStyle(
              color: Color(0xFF101B35),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• ${_textOrFallback(appointment.serviceName, l10n.appointmentServiceLabel)}',
            style: const TextStyle(
              color: Color(0xFF1D2A44),
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
                    foregroundColor: const Color(0xFF101B35),
                    side: const BorderSide(color: Color(0xFF101B35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    l10n.myAppointmentRescheduleAction,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: canceling ? null : onCancel,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD82135),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: canceling
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.myAppointmentCancelAction,
                          style: const TextStyle(fontWeight: FontWeight.w900),
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
  final _getBookedAppointmentSlots = sl<GetBookedAppointmentSlots>();
  final _isAppointmentSlotAvailable = sl<IsAppointmentSlotAvailable>();

  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;
  var _loading = true;
  var _confirming = false;
  var _failed = false;
  List<DateTime> _unavailableDates = const [];
  Map<DateTime, List<String>> _availableTimesByDate = const {};

  @override
  void initState() {
    super.initState();
    _focusedDate = _validFocusedDay(
      widget.appointment.scheduledAt.year,
      widget.appointment.scheduledAt.month,
    );
    _selectedDate = _dateOnly(widget.appointment.scheduledAt);
    _loadAvailability(_focusedDate);
  }

  Future<void> _loadAvailability(DateTime month) async {
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
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _unavailableDates = availability.unavailableDates;
        _availableTimesByDate = availability.availableTimesByDate;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
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
                  style: const TextStyle(
                    color: Color(0xFF101B35),
                    fontSize: 18,
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
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left_rounded),
              rightChevronIcon: Icon(Icons.chevron_right_rounded),
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
            style: const TextStyle(
              color: Color(0xFF101B35),
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
              backgroundColor: const Color(0xFFD82135),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: _confirming
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.myAppointmentRescheduleConfirm,
                    style: const TextStyle(fontWeight: FontWeight.w900),
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
        ? Colors.white
        : disabled || outside
        ? const Color(0xFFBAC3D4)
        : const Color(0xFF101B35);
    final background = selected
        ? const Color(0xFFD82135)
        : today
        ? const Color(0xFFFFE4E8)
        : Colors.transparent;

    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
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
          backgroundColor: selected ? const Color(0xFFFFE4E8) : Colors.white,
          foregroundColor: selected
              ? const Color(0xFFD82135)
              : const Color(0xFF101B35),
          side: BorderSide(
            color: selected ? const Color(0xFFD82135) : const Color(0xFFE0E5EF),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900),
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
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF53617A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF53617A),
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
                  style: const TextStyle(
                    color: Color(0xFF101B35),
                    fontSize: 18,
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
            style: const TextStyle(
              color: Color(0xFF101B35),
              fontWeight: FontWeight.w900,
              fontSize: 16,
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
            decoration: InputDecoration(
              hintText: l10n.myAppointmentCancelCommentsHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E5EF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD82135)),
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
              backgroundColor: const Color(0xFFD82135),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(
              l10n.myAppointmentCancelContinue,
              style: const TextStyle(fontWeight: FontWeight.w900),
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
                  ? const Color(0xFFD82135)
                  : const Color(0xFF8A94A6),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1D2A44),
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Color(0xFFF59E0B),
        size: 72,
      ),
      title: Text(
        l10n.myAppointmentCancelConfirmTitle,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.myAppointmentCancelConfirmMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF53617A)),
          ),
          const SizedBox(height: 16),
          _AppointmentSummaryCard(appointment: appointment),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.myAppointmentCancelConfirmNo),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD82135),
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.myAppointmentCancelConfirmYes),
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        color: Color(0xFF16A34A),
        size: 86,
      ),
      title: Text(
        l10n.myAppointmentCancelSuccessTitle,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.myAppointmentCancelSuccessMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF53617A)),
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
              backgroundColor: const Color(0xFFD82135),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              l10n.myAppointmentCancelSuccessAction,
              style: const TextStyle(fontWeight: FontWeight.w900),
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        color: Color(0xFF16A34A),
        size: 86,
      ),
      title: Text(
        l10n.myAppointmentRescheduleSuccessTitle,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.myAppointmentRescheduleSuccessMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF53617A)),
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
              backgroundColor: const Color(0xFFD82135),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              l10n.myAppointmentRescheduleSuccessAction,
              style: const TextStyle(fontWeight: FontWeight.w900),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7ECF5)),
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
            style: const TextStyle(
              color: Color(0xFF101B35),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _textOrFallback(
              appointment.workshopName,
              l10n.appointmentWorkshopLabel,
            ),
            style: const TextStyle(
              color: Color(0xFF53617A),
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
              style: const TextStyle(
                color: Color(0xFF53617A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF101B35),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE7FF),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(icon, color: const Color(0xFF699BFF), size: 64),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF101B35),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF53617A),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 190,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B5CFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
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
  const _AppointmentStatusVisual({
    required this.label,
    required this.accent,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color accent;
  final Color background;
  final Color foreground;

  factory _AppointmentStatusVisual.from(
    Appointment appointment,
    AppLocalizations l10n,
  ) {
    final normalized = appointment.status.trim().toLowerCase();

    if (_isCanceled(normalized)) {
      return const _AppointmentStatusVisual(
        label: '',
        accent: Color(0xFFE3364A),
        background: Color(0xFFFFE4E8),
        foreground: Color(0xFFD82135),
      ).copyWith(label: l10n.myAppointmentsStatusCanceled);
    }

    if (normalized.contains('no_show')) {
      return const _AppointmentStatusVisual(
        label: '',
        accent: Color(0xFFE3364A),
        background: Color(0xFFFFE4E8),
        foreground: Color(0xFFD82135),
      ).copyWith(label: l10n.myAppointmentsStatusNoShow);
    }

    if (normalized.contains('complete') || normalized.contains('complet')) {
      return const _AppointmentStatusVisual(
        label: '',
        accent: Color(0xFF16A34A),
        background: Color(0xFFDFF7E8),
        foreground: Color(0xFF148A45),
      ).copyWith(label: l10n.myAppointmentsStatusCompleted);
    }

    if (normalized.contains('checked_in')) {
      return const _AppointmentStatusVisual(
        label: '',
        accent: Color(0xFF0B5CFF),
        background: Color(0xFFE4EEFF),
        foreground: Color(0xFF0B5CFF),
      ).copyWith(label: l10n.myAppointmentsStatusCheckedIn);
    }

    if (normalized.contains('in_progress')) {
      return const _AppointmentStatusVisual(
        label: '',
        accent: Color(0xFF0B5CFF),
        background: Color(0xFFE4EEFF),
        foreground: Color(0xFF0B5CFF),
      ).copyWith(label: l10n.myAppointmentsStatusInProgress);
    }

    if (appointment.scheduledAt.isBefore(DateTime.now())) {
      return const _AppointmentStatusVisual(
        label: '',
        accent: Color(0xFFE3364A),
        background: Color(0xFFFFE4E8),
        foreground: Color(0xFFD82135),
      ).copyWith(label: l10n.myAppointmentsStatusExpired);
    }

    if (normalized.contains('confirm') ||
        normalized.contains('scheduled') ||
        normalized.contains('pending')) {
      return const _AppointmentStatusVisual(
        label: '',
        accent: Color(0xFF0B5CFF),
        background: Color(0xFFDFF7E8),
        foreground: Color(0xFF148A45),
      ).copyWith(label: l10n.myAppointmentsStatusConfirmed);
    }

    return const _AppointmentStatusVisual(
      label: '',
      accent: Color(0xFF0B5CFF),
      background: Color(0xFFDFF7E8),
      foreground: Color(0xFF148A45),
    ).copyWith(label: l10n.myAppointmentsStatusConfirmed);
  }

  _AppointmentStatusVisual copyWith({required String label}) {
    return _AppointmentStatusVisual(
      label: label,
      accent: accent,
      background: background,
      foreground: foreground,
    );
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
  if (text.isEmpty || RegExp(r'^[A-Z]+_\d+$').hasMatch(text)) {
    return fallback;
  }

  return text;
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
