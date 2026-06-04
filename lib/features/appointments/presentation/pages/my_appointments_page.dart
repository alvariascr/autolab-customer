import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_session_cubit.dart';
import '../../../auth/domain/errors/auth_error_catalog.dart';
import '../../../navigation/navigation_handler.dart';
import '../../../navigation/widgets/custom_bottom_navbar.dart';
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

          return _AppointmentCard(appointment: appointments[index]);
        },
      ),
    );
  }

  List<Appointment> _filterAppointments(List<Appointment> appointments) {
    final now = DateTime.now();

    return appointments.where((appointment) {
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
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = _AppointmentStatusVisual.from(appointment, l10n);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
